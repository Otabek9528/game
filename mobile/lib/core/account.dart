import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_language.dart';
import 'config.dart';
import 'google_auth.dart';
import 'key_value_store.dart';
import 'push.dart';

/// Who the app is on the server (app_accounts.py). Every install has one from
/// the first launch; [signedIn] once a Google, WhatsApp or Telegram identity
/// is attached.
@immutable
class AppUser {
  const AppUser({required this.id, this.signedIn = false, this.provider, this.name, this.detail});

  /// The id the server knows this person by: their Telegram id when signed in
  /// with Telegram, a negative number otherwise.
  final int id;
  final bool signedIn;

  /// 'google', 'whatsapp' or 'telegram'.
  final String? provider;
  final String? name;

  /// Their email, number or @username.
  final String? detail;

  static AppUser? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    if (id is! num) return null;
    return AppUser(
      id: id.toInt(),
      signedIn: json['signedIn'] == true,
      provider: json['provider'] as String?,
      name: json['name'] as String?,
      detail: json['detail'] as String?,
    );
  }

  Map<String, Object?> toJson() =>
      {'id': id, 'signedIn': signedIn, 'provider': provider, 'name': name, 'detail': detail};
}

/// A sign-in through a bot: the address to open, and the code to wait on.
@immutable
class LoginLink {
  const LoginLink({required this.code, required this.url, required this.expiresIn});

  final String code;
  final Uri url;
  final Duration expiresIn;
}

class AccountException implements Exception {
  const AccountException(this.code, [this.status = 0]);

  /// The server's code (bad_session, rate_limited, …), or `offline`.
  final String code;
  final int status;

  @override
  String toString() => 'AccountException: $code ($status)';
}

/// The app-accounts endpoints.
abstract interface class AccountSource {
  Future<(String token, AppUser user)> hello({required String lang, String? pushToken});

  Future<AppUser> me(String token);

  Future<void> updateDevice(String token, {String? pushToken, String? lang});

  Future<AppUser> signInWithGoogle(String token, String idToken);

  Future<LoginLink> link(String token, String provider);

  /// 'pending', 'done', 'cancelled' or 'expired'; the user once 'done'.
  Future<(String status, AppUser? user)> linkStatus(String token, String code);

  Future<AppUser> signOut(String token);

  Future<void> delete(String token);
}

class HttpAccountSource implements AccountSource {
  const HttpAccountSource([this._client]);

  final http.Client? _client;

  static final _shared = http.Client();

  static const _timeout = Duration(seconds: 20);

  http.Client get _http => _client ?? _shared;

  Future<Map<String, dynamic>> _call(String method, String path, {String? token, Object? body}) async {
    final request = http.Request(method, AppConfig.apiBase.resolve(path))
      ..headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on SocketException {
      throw const AccountException('offline');
    } on http.ClientException {
      throw const AccountException('offline');
    } on TimeoutException {
      throw const AccountException('offline');
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      json = null;
    }
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    if (response.statusCode >= 400 || map['success'] != true) {
      throw AccountException(map['code'] as String? ?? 'server_error', response.statusCode);
    }
    return map;
  }

  AppUser _user(Map<String, dynamic> json) =>
      AppUser.fromJson(json['user']) ?? (throw const AccountException('bad_response'));

  @override
  Future<(String, AppUser)> hello({required String lang, String? pushToken}) async {
    final json = await _call('POST', 'api/app/hello',
        body: {'platform': Platform.isIOS ? 'ios' : 'android', 'lang': lang, 'pushToken': ?pushToken});
    final token = json['token'];
    if (token is! String || token.isEmpty) throw const AccountException('bad_response');
    return (token, _user(json));
  }

  @override
  Future<AppUser> me(String token) async => _user(await _call('GET', 'api/app/me', token: token));

  @override
  Future<void> updateDevice(String token, {String? pushToken, String? lang}) =>
      _call('PUT', 'api/app/me/device', token: token, body: {'pushToken': ?pushToken, 'lang': ?lang});

  @override
  Future<AppUser> signInWithGoogle(String token, String idToken) async =>
      _user(await _call('POST', 'api/app/auth/google', token: token, body: {'idToken': idToken}));

  @override
  Future<LoginLink> link(String token, String provider) async {
    final json = await _call('POST', 'api/app/auth/link', token: token, body: {'provider': provider});
    final url = Uri.tryParse(json['url'] as String? ?? '');
    if (url == null) throw const AccountException('bad_response');
    return LoginLink(
      code: json['code'] as String,
      url: url,
      expiresIn: Duration(seconds: (json['expiresIn'] as num?)?.toInt() ?? 600),
    );
  }

  @override
  Future<(String, AppUser?)> linkStatus(String token, String code) async {
    final json = await _call('GET', 'api/app/auth/link/${Uri.encodeComponent(code)}', token: token);
    return (json['status'] as String? ?? 'pending', AppUser.fromJson(json['user']));
  }

  @override
  Future<AppUser> signOut(String token) async => _user(await _call('POST', 'api/app/signout', token: token));

  @override
  Future<void> delete(String token) => _call('DELETE', 'api/app/me', token: token);
}

/// The app's account: made on the first launch without asking anything,
/// signed in to when something needs a name. Its token goes with every call
/// that needs to know who is asking ([authHeaders]); its phone's push token
/// goes to the server, so alerts arrive as notifications.
class AccountController extends ChangeNotifier {
  AccountController({
    required this._store,
    required this._source,
    required this._push,
    required this._google,
    required this._language,
  }) {
    final token = _store.read(_tokenKey);
    _token = token == null || token.isEmpty ? null : token;
    try {
      _user = AppUser.fromJson(jsonDecode(_store.read(_userKey) ?? 'null'));
    } on FormatException {
      _user = null;
    }
  }

  final KeyValueStore _store;
  final AccountSource _source;
  final PushService _push;
  final GoogleAuth _google;
  final AppLanguage Function() _language;

  static const _tokenKey = 'app_session';
  static const _userKey = 'app_user';

  String? _token;
  AppUser? _user;
  String? _pushToken;
  bool _pushAllowed = false;
  Future<void>? _pushStarted;
  Future<void>? _starting;
  PushOpened _onOpen = _ignore;
  PushArrived _onForeground = _ignore;

  static void _ignore(PushMessage _) {}

  AppUser? get user => _user;
  bool get signedIn => _user?.signedIn ?? false;

  /// Whether this phone lets the app show notifications.
  bool get pushAllowed => _pushAllowed;

  /// For calls that need to know who is asking; empty until the account exists.
  Map<String, String> get authHeaders => _token == null ? const {} : {'Authorization': 'Bearer $_token'};

  String get _lang => _language().code;

  /// What to do with notifications: [onOpen] when one is tapped,
  /// [onForeground] when one arrives while the app is open.
  void handlePush({required PushOpened onOpen, required PushArrived onForeground}) {
    _onOpen = onOpen;
    _onForeground = onForeground;
  }

  /// Push notifications on: asks to show them (unless already answered), and
  /// hands the server this phone's token. Once; after the first-launch
  /// permission questions, so its prompt never comes before them.
  Future<void> startPush() => _pushStarted ??= _push
          .start(
            onToken: _setPushToken,
            onOpen: (m) => _onOpen(m),
            onForeground: (m) => _onForeground(m),
          )
          .then((allowed) {
        _pushAllowed = allowed;
        notifyListeners();
      });

  /// The account, created when missing. Safe to call again and again.
  Future<void> ensure() => _starting ??= _ensure().whenComplete(() => _starting = null);

  Future<void> _ensure() async {
    try {
      if (_token == null) {
        final (token, user) = await _source.hello(lang: _lang, pushToken: _pushToken);
        _token = token;
        _store.write(_tokenKey, token);
        _setUser(user);
        return;
      }
      _setUser(await _source.me(_token!));
    } on AccountException catch (e) {
      if (e.code == 'bad_session') {
        // Deleted, or the server lost it: start again as someone new.
        _forget();
        return _ensure();
      }
      // Offline: the cached user stands until the next try.
    }
  }

  void _setUser(AppUser user) {
    _user = user;
    _store.write(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  void _forget() {
    _token = null;
    _user = null;
    _store.write(_tokenKey, '');
    _store.write(_userKey, 'null');
    notifyListeners();
  }

  Future<void> _setPushToken(String token) async {
    _pushToken = token;
    await ensure();
    final session = _token;
    if (session == null) return;
    try {
      await _source.updateDevice(session, pushToken: token, lang: _lang);
    } on AccountException {
      // Sent again with the next token refresh or launch.
    }
  }

  /// The app's language changed: notifications from now on come in it.
  Future<void> languageChanged() async {
    final session = _token;
    if (session == null) return;
    try {
      await _source.updateDevice(session, lang: _lang);
    } on AccountException {
      // Next launch.
    }
  }

  Future<String> _session() async {
    await ensure();
    return _token ?? (throw const AccountException('offline'));
  }

  /// Google's account picker, then the server. False: the person closed the picker.
  Future<bool> signInWithGoogle() async {
    final session = await _session();
    final idToken = await _google.idToken();
    if (idToken == null) return false;
    _setUser(await _source.signInWithGoogle(session, idToken));
    return true;
  }

  /// A sign-in through the Telegram or WhatsApp bot: open [LoginLink.url],
  /// then wait on [checkLink].
  Future<LoginLink> startLink(String provider) async => _source.link(await _session(), provider);

  /// 'pending', 'done', 'cancelled' or 'expired'. When done, the app is signed in.
  Future<String> checkLink(String code) async {
    final (status, user) = await _source.linkStatus(await _session(), code);
    if (status == 'done' && user != null) _setUser(user);
    return status;
  }

  /// This phone starts again as nobody in particular; the signed-in account
  /// keeps its watches.
  Future<void> signOut() async {
    _setUser(await _source.signOut(await _session()));
    unawaited(_google.signOut());
  }

  /// The account and everything kept under it, everywhere. The app then
  /// starts again with a new, empty account.
  Future<void> deleteAccount() async {
    await _source.delete(await _session());
    unawaited(_google.signOut());
    _forget();
    await ensure();
  }
}
