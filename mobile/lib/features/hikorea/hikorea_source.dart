import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'hikorea_models.dart';

/// HiKorea appointments, through the server that watches them
/// (hikorea_api.py; the web page is pages/hikorea/hikorea.js). Watches
/// belong to the app's account: [auth] is its `Authorization` header.
abstract interface class HikoreaSource {
  Future<List<HkOffice>> offices();

  /// Provinces, by their Korean names.
  Future<List<String>> provinces();

  /// The offices serving a home address.
  Future<List<HkMatch>> resolve(String province, String address);

  Future<HkCalendar> calendar(int desk);

  /// A day's appointment times, checked on HiKorea now (a few seconds).
  Future<HkDay> day(int desk, String ymd);

  Future<List<HkWatch>> watches(Map<String, String> auth, {bool past = false});

  Future<HkWatch> watch(
    Map<String, String> auth, {
    required int desk,
    required String start,
    required String end,
    required String lang,
  });

  Future<void> stop(Map<String, String> auth, int id);

  /// An alert as a real one looks, sent to this account's phones.
  Future<void> test(Map<String, String> auth, String lang);
}

/// [code]: the server's (`duplicate_watch`, `max_watches_reached`,
/// `validation_failed`, `session_expired`, `push_rejected` …), or 'offline'.
class HkException implements Exception {
  const HkException(this.code, [this.status = 0]);

  final String code;
  final int status;

  @override
  String toString() => 'HkException($code, $status)';
}

class HttpHikoreaSource implements HikoreaSource {
  const HttpHikoreaSource([this._client]);

  final http.Client? _client;

  static final _shared = http.Client();

  // A day's check waits on HiKorea itself.
  static const _timeout = Duration(seconds: 30);

  http.Client get _http => _client ?? _shared;

  @override
  Future<List<HkOffice>> offices() async {
    final json = await _call('GET', 'offices');
    return [for (final o in (json['offices'] as List?) ?? const []) ?HkOffice.fromJson(o)]
      ..sort((a, b) => a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase()));
  }

  @override
  Future<List<String>> provinces() async {
    final json = await _call('GET', 'provinces');
    return [
      for (final p in (json['provinces'] as List?) ?? const [])
        if (p is Map && p['ko'] is String) p['ko'] as String,
    ];
  }

  @override
  Future<List<HkMatch>> resolve(String province, String address) async {
    final json = await _call('GET', 'resolve-office', query: {'province': province, 'address': address});
    return [for (final m in (json['matches'] as List?) ?? const []) ?HkMatch.fromJson(m)];
  }

  @override
  Future<HkCalendar> calendar(int desk) async => HkCalendar.fromJson(await _call('GET', 'desks/$desk/slots'));

  @override
  Future<HkDay> day(int desk, String ymd) async => HkDay.fromJson(await _call('GET', 'desks/$desk/dates/$ymd'));

  @override
  Future<List<HkWatch>> watches(Map<String, String> auth, {bool past = false}) async {
    final json = await _call('GET', 'watches', auth: auth, query: {'status': past ? 'all' : 'active'});
    return [for (final w in (json['watches'] as List?) ?? const []) ?HkWatch.fromJson(w)];
  }

  @override
  Future<HkWatch> watch(
    Map<String, String> auth, {
    required int desk,
    required String start,
    required String end,
    required String lang,
  }) async {
    final json = await _call('POST', 'watches',
        auth: auth, body: {'desk_seq': desk, 'start_ymd': start, 'end_ymd': end, 'lang': lang});
    return HkWatch.fromJson(json['watch']) ?? (throw const HkException('bad_response'));
  }

  @override
  Future<void> stop(Map<String, String> auth, int id) => _call('DELETE', 'watches/$id', auth: auth);

  @override
  Future<void> test(Map<String, String> auth, String lang) =>
      _call('POST', 'test-notification', auth: auth, body: {'lang': lang});

  Future<Map<String, dynamic>> _call(
    String method,
    String path, {
    Map<String, String>? auth,
    Map<String, String>? query,
    Object? body,
  }) async {
    var url = AppConfig.apiBase.resolve('api/hikorea/$path');
    if (query != null) url = url.replace(queryParameters: query);
    final request = http.Request(method, url)
      ..headers['Content-Type'] = 'application/json'
      ..headers.addAll(auth ?? const {});
    if (body != null) request.body = jsonEncode(body);
    http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on Exception catch (e) {
      if (e is SocketException || e is http.ClientException || e is TimeoutException) {
        throw const HkException('offline');
      }
      rethrow;
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      json = null;
    }
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    if (response.statusCode >= 400) throw HkException(map['error'] as String? ?? 'server_error', response.statusCode);
    return map;
  }
}
