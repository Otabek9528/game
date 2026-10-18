import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'key_value_store.dart';

/// Tells the server what people open, as the web app does (js/logger.js,
/// pages/barcode/app.js): `POST api/log-interaction`.
abstract interface class ActivityLog {
  /// [action] is the web app's name for it (`qibla`, `scanner_found`, …);
  /// [detail] follows a colon, as on the web (`scanner_found:8801234567890`).
  void log(String action, [String? detail]);
}

/// Sends each action with the platform after it — `qibla_apk` on Android,
/// `qibla_ios` on an iPhone — so the app's visits read apart from the web
/// app's. Fire and forget: a failed send is dropped, as on the web.
class HttpActivityLog implements ActivityLog {
  HttpActivityLog(this._store, {http.Client? client, TargetPlatform? platform})
      : _client = client ?? http.Client(),
        _platform = platform ?? defaultTargetPlatform;

  final KeyValueStore _store;
  final http.Client _client;
  final TargetPlatform _platform;

  static const _key = 'install_id';

  String get suffix => _platform == TargetPlatform.iOS ? 'ios' : 'apk';

  /// There is no Telegram account in the app, so each install gets its own
  /// number in place of one. Negative, so it can never be taken for a
  /// Telegram user's id; a number, so it fits wherever those are kept.
  int get installId {
    final saved = int.tryParse(_store.read(_key) ?? '');
    if (saved != null) return saved;
    final id = -(1000000000 + Random.secure().nextInt(1 << 31));
    _store.write(_key, '$id');
    return id;
  }

  /// What one action is sent as.
  Map<String, Object> payload(String action, [String? detail]) => {
        'user_id': installId,
        'username': _platform == TargetPlatform.iOS ? 'iOS app' : 'Android app',
        'action': '${action}_$suffix${detail == null ? '' : ':$detail'}',
      };

  @override
  void log(String action, [String? detail]) {
    _client
        .post(
          AppConfig.apiBase.resolve('api/log-interaction'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload(action, detail)),
        )
        .timeout(const Duration(seconds: 15))
        .then<void>((_) {}, onError: (Object _) {});
  }
}
