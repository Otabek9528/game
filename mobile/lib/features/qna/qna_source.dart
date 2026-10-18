import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'qna_models.dart';

/// The archive, from the same endpoints the web page uses
/// (pages/questions/qna.js).
abstract interface class QnaSource {
  /// Questions picked at random.
  Future<List<QnaQuestion>> browse({int limit = 15});

  /// The questions most like [query], by the server's Uzbek language model.
  /// [who] is sent along, as the web page sends the Telegram user.
  Future<List<QnaQuestion>> search(String query, {int limit = 20, Map<String, Object> who = const {}});

  Future<QnaDetail> detail(String id);
}

/// The server can't be reached or answered with an error: never read as
/// "nothing found".
class QnaException implements Exception {
  const QnaException(this.message);

  final String message;

  @override
  String toString() => 'QnaException: $message';
}

class HttpQnaSource implements QnaSource {
  const HttpQnaSource([this._client]);

  final http.Client? _client;

  static final _shared = http.Client();

  /// The search runs a language model: it can take a while.
  static const _timeout = Duration(seconds: 30);

  @override
  Future<List<QnaQuestion>> browse({int limit = 15}) async => _questions(
        await _send(() => (_client ?? _shared).get(
              AppConfig.apiBase.resolve('api/questions/browse').replace(queryParameters: {'limit': '$limit'}),
            )),
      );

  @override
  Future<List<QnaQuestion>> search(String query, {int limit = 20, Map<String, Object> who = const {}}) async =>
      _questions(
        await _send(() => (_client ?? _shared).post(
              AppConfig.apiBase.resolve('api/questions/search'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'query': query, 'limit': limit, ...who}),
            )),
      );

  @override
  Future<QnaDetail> detail(String id) async {
    final json = await _send(
      () => (_client ?? _shared).get(AppConfig.apiBase.resolve('api/questions/${Uri.encodeComponent(id)}')),
    );
    final question = json['question'] is Map<String, dynamic>
        ? QnaQuestion.fromJson(json['question'] as Map<String, dynamic>)
        : null;
    if (question == null) throw const QnaException('no question');
    return QnaDetail(question: question, related: _questions(json, field: 'related'));
  }

  static List<QnaQuestion> _questions(Map<String, dynamic> json, {String field = 'questions'}) => [
        for (final q in (json[field] as List?) ?? const [])
          if (q is Map<String, dynamic>) ?QnaQuestion.fromJson(q),
      ];

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      try {
        response = await request().timeout(_timeout);
      } on Exception catch (e) {
        // A dropped connection on a weak signal: once more, after a breath.
        if (e is! SocketException && e is! http.ClientException) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 800));
        response = await request().timeout(_timeout);
      }
    } on Exception catch (e) {
      throw QnaException('$e');
    }
    if (response.statusCode != 200) throw QnaException('${response.statusCode}');
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic> && body['success'] == true) return body;
      throw QnaException(body is Map ? '${body['error']}' : 'not JSON');
    } on FormatException {
      throw const QnaException('not JSON');
    }
  }
}
