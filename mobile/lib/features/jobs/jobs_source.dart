import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';

/// What went wrong: the server's own words when it gave them, or `offline`.
class JobsException implements Exception {
  const JobsException(this.code, {this.message});

  final String code;

  /// The server's message, in Uzbek.
  final String? message;

  @override
  String toString() => 'JobsException($code)';
}

enum JobStatus { available, reserved, finished }

/// A job post one put in the group: open, taken (someone found) or done.
@immutable
class JobPost {
  const JobPost({
    required this.id,
    required this.text,
    required this.contact,
    required this.status,
    required this.commission,
    this.createdAt,
    this.reservedAt,
  });

  final String id;
  final String text;
  final String contact;
  final JobStatus status;
  final bool commission;
  final DateTime? createdAt;
  final DateTime? reservedAt;

  /// Done can be marked three hours after it was taken.
  static const finishAfter = Duration(hours: 3);

  /// How long until it can be marked done; zero when it can.
  Duration finishIn(DateTime now) {
    if (status != JobStatus.reserved || reservedAt == null) return finishAfter;
    final left = finishAfter - now.difference(reservedAt!);
    return left.isNegative ? Duration.zero : left;
  }

  /// "YYYY-MM-DD HH:MM:SS", Korean time.
  static DateTime? kst(Object? v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse('${v.replaceFirst(' ', 'T')}+09:00') : null;

  static JobPost? fromJson(Object? json) {
    if (json is! Map || json['id'] == null) return null;
    return JobPost(
      id: '${json['id']}',
      text: json['message'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      status: JobStatus.values.where((s) => s.name == json['status']).firstOrNull ?? JobStatus.available,
      commission: json['commission'] != false,
      createdAt: kst(json['created_at']),
      reservedAt: kst(json['reserved_at']),
    );
  }
}

/// The job group of the Mini App (job_group_bp.py, places_api_protected.py):
/// a one-time invite to the group, and one's own posts in it. [auth] is the
/// app's account; [user] the id it goes by.
abstract interface class JobsSource {
  /// A link that lets one person in, for a few seconds.
  Future<String> invite(Map<String, String> auth, int user);

  Future<List<JobPost>> posts(Map<String, String> auth, int user);

  Future<void> create(Map<String, String> auth, int user, {required String name, required String text, required String contact, required bool commission});

  Future<void> edit(Map<String, String> auth, int user, String id, {required String text, required String contact, required bool commission});

  Future<void> setStatus(Map<String, String> auth, int user, String id, JobStatus status);

  Future<void> delete(Map<String, String> auth, int user, String id);
}

class HttpJobsSource implements JobsSource {
  const HttpJobsSource([this._client]);

  final http.Client? _client;
  static final _shared = http.Client();
  http.Client get _http => _client ?? _shared;

  @override
  Future<String> invite(Map<String, String> auth, int user) async {
    final link = (await _call('POST', 'invite', auth, {'user_id': user}))['invite_link'];
    return link is String && link.isNotEmpty ? link : throw const JobsException('bad_response');
  }

  @override
  Future<List<JobPost>> posts(Map<String, String> auth, int user) async => [
    for (final p in ((await _call('GET', 'posts', auth, null, {'user_id': '$user'}))['posts'] as List?) ?? const []) ?JobPost.fromJson(p),
  ];

  @override
  Future<void> create(Map<String, String> auth, int user, {required String name, required String text, required String contact, required bool commission}) =>
      _call('POST', 'post', auth, {'user_id': user, 'user_name': name, 'message': text, 'contact': contact, 'commission': commission});

  @override
  Future<void> edit(Map<String, String> auth, int user, String id, {required String text, required String contact, required bool commission}) =>
      _call('POST', 'post/edit', auth, {'post_id': id, 'user_id': user, 'message': text, 'contact': contact, 'commission': commission});

  @override
  Future<void> setStatus(Map<String, String> auth, int user, String id, JobStatus status) =>
      _call('POST', 'post/status', auth, {'post_id': id, 'user_id': user, 'status': status.name});

  @override
  Future<void> delete(Map<String, String> auth, int user, String id) => _call('POST', 'post/delete', auth, {'post_id': id, 'user_id': user});

  Future<Map<String, dynamic>> _call(String method, String path, Map<String, String> auth, [Object? body, Map<String, String>? query]) async {
    var url = AppConfig.apiBase.resolve('api/group/$path');
    if (query != null) url = url.replace(queryParameters: query);
    final request = http.Request(method, url)
      ..headers.addAll(auth)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(const Duration(seconds: 15)));
    } on SocketException {
      throw const JobsException('offline');
    } on http.ClientException {
      throw const JobsException('offline');
    } on TimeoutException {
      throw const JobsException('offline');
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      json = null;
    }
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    if (response.statusCode >= 400 || map['success'] != true) {
      final message = map['message'];
      throw JobsException(
        map['error'] is String && response.statusCode < 500 ? map['error'] as String : 'http_${response.statusCode}',
        message: message is String && message.trim().isNotEmpty ? message.trim() : null,
      );
    }
    return map;
  }
}
