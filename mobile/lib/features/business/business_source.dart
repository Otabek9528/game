import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'business_models.dart';

/// The business directory, from the endpoints the web page uses
/// (pages/business/business.js).
abstract interface class BusinessSource {
  Future<BizDirectory> directory();

  /// A category's businesses, most liked first.
  Future<List<Business>> category(String id);

  /// Matches anywhere, grouped by category.
  Future<List<BizGroup>> search(String query);

  Future<Business> business(String id);

  /// Counts an opening, as the web page does; never waited for.
  void countView(String id);

  /// A logo's bytes; null when it can't be fetched.
  Future<Uint8List?> logo(Uri url);
}

class BizException implements Exception {
  const BizException(this.message);

  final String message;

  @override
  String toString() => 'BizException: $message';
}

class HttpBusinessSource implements BusinessSource {
  const HttpBusinessSource([this._client]);

  final http.Client? _client;

  static final _shared = http.Client();

  static const _timeout = Duration(seconds: 30);

  http.Client get _http => _client ?? _shared;

  @override
  Future<BizDirectory> directory() async {
    final json = await _get('api/business/categories');
    return BizDirectory(
      categories: [for (final c in (json['categories'] as List?) ?? const []) ?BizCategory.fromJson(c)]
        ..sort(byCategoryOrder),
      listingFee: (json['listingFee'] as num?)?.toInt(),
    );
  }

  @override
  Future<List<Business>> category(String id) async {
    final json = await _get('api/business/list', {'category_id': id});
    return [for (final b in (json['businesses'] as List?) ?? const []) ?Business.fromJson(b)];
  }

  @override
  Future<List<BizGroup>> search(String query) async {
    final json = await _get('api/business/feed', {'q': query});
    final groups = [
      for (final g in (json['groups'] as List?) ?? const [])
        if (g is Map<String, dynamic>)
          if (BizCategory.fromJson(g['category']) case final category?)
            BizGroup(
              category: category,
              total: (g['total'] as num?)?.toInt() ?? 0,
              businesses: [
                for (final b in (g['businesses'] as List?) ?? const []) ?Business.fromJson(b, categoryName: category.name),
              ],
            ),
    ];
    groups.sort((a, b) => byCategoryOrder(
          BizCategory(id: a.category.id, slug: a.category.slug, name: a.category.name, count: a.total),
          BizCategory(id: b.category.id, slug: b.category.slug, name: b.category.name, count: b.total),
        ));
    return groups;
  }

  @override
  Future<Business> business(String id) async {
    final json = await _get('api/business/${Uri.encodeComponent(id)}');
    return Business.fromJson(json['business']) ?? (throw const BizException('no business'));
  }

  @override
  void countView(String id) {
    _http
        .post(
          AppConfig.apiBase.resolve('api/business/${Uri.encodeComponent(id)}/tap'),
          headers: const {'Content-Type': 'application/json', 'X-Init-Data': ''},
        )
        .timeout(_timeout)
        .then<void>((_) {}, onError: (Object _) {});
  }

  @override
  Future<Uint8List?> logo(Uri url) async {
    try {
      final response = await _http.get(url).timeout(_timeout);
      return response.statusCode == 200 && response.bodyBytes.isNotEmpty ? response.bodyBytes : null;
    } on Exception {
      return null;
    }
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    var url = AppConfig.apiBase.resolve(path);
    if (query != null) url = url.replace(queryParameters: query);
    http.Response response;
    try {
      try {
        response = await _http.get(url).timeout(_timeout);
      } on Exception catch (e) {
        // A dropped connection on a weak signal: once more, after a breath.
        if (e is! SocketException && e is! http.ClientException) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 800));
        response = await _http.get(url).timeout(_timeout);
      }
    } on Exception catch (e) {
      throw BizException('$path: $e');
    }
    if (response.statusCode != 200) throw BizException('$path: ${response.statusCode}');
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic> && body['success'] == true) return body;
    } on FormatException {
      // Below.
    }
    throw BizException('$path: bad response');
  }
}
