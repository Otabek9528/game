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
  const AppUser({required this.id, this.signedIn = false, this.provider, this.name, this.detail, this.photo});

  /// The id the server knows this person by: their Telegram id when signed in
  /// with Telegram, a negative number otherwise.
  final int id;
  final bool signedIn;

  /// 'google', 'whatsapp' or 'telegram'.
  final String? provider;
  final String? name;

  /// Their email, number or @username.
  final String? detail;

  /// The profile photo's version, when the sign-in brought one (Telegram's,
  /// Google's): it changes when the photo does.
  final String? photo;

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
      photo: json['photo'] as String?,
    );
  }

  Map<String, Object?> toJson() =>
      {'id': id, 'signedIn': signedIn, 'provider': provider, 'name': name, 'detail': detail, 'photo': photo};
}

/// An alert that was pushed to this person, as the inbox keeps it.
@immutable
class InboxItem {
  const InboxItem({
    required this.id,
    required this.title,
    this.body = '',
    String? text,
    this.images = const [],
    this.data = const {},
    required this.at,
  }) : text = text ?? body;

  final int id;
  final String title;

  /// What the notification showed: the start of [text] when that is long.
  final String body;

  /// The whole message.
  final String text;

  /// Its photos' addresses.
  final List<String> images;

  /// What a tap opens: `url`, `kind` (as in a push).
  final Map<String, String> data;
  final DateTime at;

  static InboxItem? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final at = DateTime.tryParse(json['at'] as String? ?? '');
    if (id is! num || at == null) return null;
    final data = json['data'];
    final images = json['images'];
    return InboxItem(
      id: id.toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      text: json['text'] as String?,
      images: [if (images is List) for (final url in images) if (url is String && url.startsWith('https://')) url],
      data: data is Map ? {for (final e in data.entries) '${e.key}': '${e.value}'} : const {},
      at: at.toLocal(),
    );
  }
}

/// A sign-in through a bot: the address to open, and the code to wait on.
@immutable
class LoginLink {
  const LoginLink({required this.code, required this.url, required this.expiresIn});

  final String code;
  final Uri url;
  final Duration expiresIn;
}

/// What a test notification did on each way it goes. [push]: `sent` (the
/// notification service took it), `no_token` (this phone gave none yet),
/// `rejected` (its token is dead), `failed`, `off` (none on the server).
/// [telegram], for a Telegram account: `sent`, `blocked` (the bot can't write
/// to them) or `failed`; null otherwise. [bot]: its username, to open it.
typedef TestPushResult = ({String push, String? telegram, String? bot});

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

  /// Newest first, a page at a time; [before]: the last id of the page before.
  Future<(List<InboxItem> items, bool more)> inbox(String token, {int? before});

  /// The signed-in account's profile photo; null when it has none.
  Future<Uint8List?> photo(String token);

  /// A test notification to this phone, and from the bot to a Telegram
  /// account.
  Future<TestPushResult> testPush(String token);
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

  @override
  Future<Uint8List?> photo(String token) async {
    final request = http.Request('GET', AppConfig.apiBase.resolve('api/app/me/photo'))
      ..headers['Authorization'] = 'Bearer $token';
    try {
      final response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) throw AccountException('server_error', response.statusCode);
      return response.bodyBytes;
    } on SocketException {
      throw const AccountException('offline');
    } on http.ClientException {
      throw const AccountException('offline');
    } on TimeoutException {
      throw const AccountException('offline');
    }
  }

  @override
  Future<TestPushResult> testPush(String token) async {
    final json = await _call('POST', 'api/app/me/test-push', token: token);
    final telegram = json['telegram'], bot = json['bot'];
    return (
      push: json['push'] is String ? json['push'] as String : (json['sent'] == true ? 'sent' : 'failed'),
      telegram: telegram is String ? telegram : null,
      bot: bot is String && bot.isNotEmpty ? bot : null,
    );
  }

  @override
  Future<(List<InboxItem>, bool)> inbox(String token, {int? before}) async {
    final json = await _call('GET', before == null ? 'api/app/inbox' : 'api/app/inbox?before=$before', token: token);
    return (
      [for (final item in (json['items'] as List?) ?? const []) ?InboxItem.fromJson(item)],
      json['more'] == true,
    );
  }
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
    _inboxSeen = int.tryParse(_store.read(_seenKey) ?? '') ?? 0;
    try {
      _user = AppUser.fromJson(jsonDecode(_store.read(_userKey) ?? 'null'));
    } on FormatException {
      _user = null;
    }
    // The photo kept from before shows at once, offline too.
    if (_user?.photo case final version? when _store.read(_photoVersionKey) == version) {
      try {
        _photo = base64Decode(_store.read(_photoKey) ?? '');
      } on FormatException {
        _photo = null;
      }
    }
  }

  final KeyValueStore _store;
  final AccountSource _source;
  final PushService _push;
  final GoogleAuth _google;
  final AppLanguage Function() _language;

  static const _tokenKey = 'app_session';
  static const _userKey = 'app_user';
  static const _seenKey = 'inbox_seen';
  static const _photoKey = 'app_photo';
  static const _photoVersionKey = 'app_photo_v';

  /// The language the server was last told: its alerts, and the bots' sign-in
  /// questions, are written in it.
  static const _langKey = 'app_session_lang';

  String? _token;
  AppUser? _user;
  String? _pushToken;
  bool _pushAllowed = false;
  Future<void>? _pushStarted;
  Future<void>? _starting;
  PushOpened _onOpen = _ignore;
  PushArrived _onForeground = _ignore;

  static void _ignore(PushMessage _) {}

  Uint8List? _photo;

  /// The photo version being fetched, so it is fetched once.
  String? _photoFetching;

  List<InboxItem> _inbox = const [];
  bool _inboxMore = false;
  int _inboxSeen = 0;

  AppUser? get user => _user;

  /// The signed-in account's profile photo (Telegram's, Google's), once fetched.
  Uint8List? get photo => _user?.photo == null ? null : _photo;

  /// What was pushed to this person, newest first, as far as loaded.
  List<InboxItem> get inbox => _inbox;
  bool get inboxMore => _inboxMore;

  /// The newest item already seen on the inbox page.
  int get inboxSeen => _inboxSeen;

  /// Arrived since the inbox was last opened.
  int get unread => _inbox.where((i) => i.id > _inboxSeen).length;

  bool get signedIn => _user?.signedIn ?? false;

  /// Whether this phone lets the app show notifications.
  bool get pushAllowed => _pushAllowed;

  /// Whether [pushAllowed] is known: false until the first ask is answered.
  bool get pushChecked => _pushChecked;
  bool _pushChecked = false;

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
        onOpen: (m) {
          _noteTest(m);
          _onOpen(m);
        },
        onForeground: (m) {
          _noteTest(m);
          _onForeground(m);
        },
      )
      .then((allowed) {
        _pushAllowed = allowed;
        _pushChecked = true;
        notifyListeners();
      });

  /// Looks again whether notifications are allowed: back from the phone's
  /// settings, say.
  Future<void> recheckPush() async {
    if (_pushStarted == null) return;
    final allowed = await _push.isAllowed();
    if (allowed == _pushAllowed) return;
    _pushAllowed = allowed;
    notifyListeners();
  }

  /// The header to call the API with: the session the phone has, with no
  /// call to the server for it; a new one made first when there is none.
  /// [ensure] also refreshes who is signed in, which the app does at start
  /// and with each notification token; before every request it only made
  /// each page wait for an extra round trip.
  Future<Map<String, String>> headers() async {
    if (_token == null) await ensure();
    return authHeaders;
  }

  /// The account, created when missing. Safe to call again and again.
  Future<void> ensure() => _starting ??= _ensure().whenComplete(() => _starting = null);

  Future<void> _ensure() async {
    try {
      if (_token == null) {
        final lang = _lang;
        final (token, user) = await _source.hello(lang: lang, pushToken: _pushToken);
        _token = token;
        _store.write(_tokenKey, token);
        _store.write(_langKey, lang);
        _setUser(user);
        return;
      }
      _setUser(await _source.me(_token!));
      await _syncLanguage();
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
    final switched = _user != null && _user!.id != user.id;
    _user = user;
    _store.write(_userKey, jsonEncode(user.toJson()));
    if (switched) {
      // Signed in or out: someone else's alerts.
      _clearInbox();
      unawaited(refreshInbox());
    }
    unawaited(_syncPhoto());
    notifyListeners();
  }

  /// Fetches the photo when its version is new; forgets it when there is none.
  Future<void> _syncPhoto() async {
    final version = _user?.photo, session = _token;
    if (version == null) {
      if (_photo == null) return;
      _photo = null;
      _store.write(_photoKey, '');
      _store.write(_photoVersionKey, '');
      notifyListeners();
      return;
    }
    if (session == null || _photoFetching == version || (_photo != null && _store.read(_photoVersionKey) == version)) {
      return;
    }
    _photoFetching = version;
    try {
      final photo = await _source.photo(session);
      if (_user?.photo != version) return;
      _photo = photo;
      _store.write(_photoKey, photo == null ? '' : base64Encode(photo));
      _store.write(_photoVersionKey, photo == null ? '' : version);
      notifyListeners();
    } on AccountException {
      // The initials meanwhile; tried again with the next look at the account.
    } finally {
      if (_photoFetching == version) _photoFetching = null;
    }
  }

  void _forget() {
    _token = null;
    _user = null;
    _photo = null;
    _store.write(_photoKey, '');
    _store.write(_photoVersionKey, '');
    _store.write(_tokenKey, '');
    _store.write(_userKey, 'null');
    _clearInbox();
    notifyListeners();
  }

  void _clearInbox() {
    _inbox = const [];
    _inboxMore = false;
  }

  Future<void> _setPushToken(String token) async {
    _pushToken = token;
    await ensure();
    final session = _token;
    if (session == null) return;
    try {
      final lang = _lang;
      await _source.updateDevice(session, pushToken: token, lang: lang);
      _store.write(_langKey, lang);
    } on AccountException {
      // Sent again with the next token refresh or launch.
    }
  }

  /// The newest alerts (the first page). False when they couldn't be had;
  /// the list loaded before stays.
  Future<bool> refreshInbox() async {
    await ensure();
    final session = _token;
    if (session == null) return false;
    try {
      final (items, more) = await _source.inbox(session);
      _inbox = items;
      _inboxMore = more;
      notifyListeners();
      return true;
    } on AccountException {
      return false;
    }
  }

  /// The next page, older.
  Future<void> loadMoreInbox() async {
    final session = _token;
    if (session == null || _inbox.isEmpty) return;
    final (items, more) = await _source.inbox(session, before: _inbox.last.id);
    _inbox = [..._inbox, ...items];
    _inboxMore = more;
    notifyListeners();
  }

  /// The inbox page was opened: everything in it is seen.
  void markInboxSeen() {
    final newest = _inbox.isEmpty ? 0 : _inbox.first.id;
    if (newest <= _inboxSeen) return;
    _inboxSeen = newest;
    _store.write(_seenKey, '$newest');
    notifyListeners();
  }

  /// When the last test notification reached this phone; null until it does.
  DateTime? get testArrivedAt => _testArrivedAt;
  DateTime? _testArrivedAt;

  void _noteTest(PushMessage message) {
    if (!isTestPush(message)) return;
    _testArrivedAt = DateTime.now();
    notifyListeners();
  }

  /// A test notification to this phone now, in the app's language (and from
  /// the bot to a Telegram account). Whether it reached the phone is
  /// [testArrivedAt]: the server only knows it was handed on.
  Future<TestPushResult> sendTestPush() async {
    final session = await _session();
    _testArrivedAt = null;
    return _source.testPush(session);
  }

  /// The app's language changed: notifications from now on come in it.
  Future<void> languageChanged() async {
    try {
      await _syncLanguage();
    } on AccountException {
      // On the next launch, or before the next sign-in.
    }
  }

  /// Tells the server the app's language, unless it already knows it. Runs
  /// with every [ensure], so it is right before a sign-in link is made.
  Future<void> _syncLanguage() async {
    final session = _token;
    final lang = _lang;
    if (session == null || _store.read(_langKey) == lang) return;
    await _source.updateDevice(session, lang: lang);
    _store.write(_langKey, lang);
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
