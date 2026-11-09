import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

/// What this version of the app reports about campaign messages, sent to the
/// server with the phone's details (`reports`): the admin panel counts only
/// phones that report, so older versions don't pull its rates down.
const pushReportsVersion = 1;

/// The admin's campaign messages carry their delivery's id and a key the
/// server made for it (`d`, `k`, with `kind: campaign`), in the push and in
/// the inbox. The app sends them back when the message arrives, its
/// notification is tapped, it is read, or a link in it is tapped. Nothing
/// else goes: no account, no device details.
enum PushEvent { received, opened, read, clicked }

class PushReports {
  PushReports({this.client, this.retryAfter = const Duration(seconds: 3)});

  /// Kept open for the app's life; null: one per report, closed after.
  final http.Client? client;
  final Duration retryAfter;

  static final endpoint = AppConfig.apiBase.resolve('api/app/push-event');

  /// Whether [data] is a campaign message's, which can be reported.
  static bool reportable(Map<String, String> data) =>
      data['kind'] == 'campaign' && int.tryParse(data['d'] ?? '') != null && (data['k'] ?? '').isNotEmpty;

  /// Tells the server; tried twice, never throws. Not for other messages.
  Future<void> send(Map<String, String> data, PushEvent event, {String? link}) async {
    if (!reportable(data)) return;
    final body = jsonEncode({'d': int.parse(data['d']!), 'k': data['k'], 'e': event.name, 'link': ?link});
    final own = client == null;
    final sender = client ?? http.Client();
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await sender
              .post(
                endpoint,
                headers: {'Content-Type': 'application/json', 'User-Agent': AppConfig.userAgent},
                body: body,
              )
              .timeout(const Duration(seconds: 10));
          // 4xx: the server won't take it however often it's sent.
          if (response.statusCode < 500) return;
        } catch (e) {
          debugPrint('Push report not sent: $e');
        }
        if (attempt == 0) await Future<void>.delayed(retryAfter);
      }
    } finally {
      if (own) sender.close();
    }
  }
}

/// The app's reporter. Tests put their own here.
PushReports pushReports = PushReports();
