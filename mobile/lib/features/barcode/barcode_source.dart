import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'barcode_models.dart';

/// The halal database, from the same endpoints the web page uses
/// (pages/barcode/app.js, stores.js, store.js).
abstract interface class BarcodeSource {
  /// Null: not in the database. Throws [BarcodeException] when the server
  /// can't be reached, so "no connection" never reads as "not found".
  Future<Product?> product(String code);

  Future<List<StoreSummary>> stores();

  Future<StoreMeta> store(String store);

  Future<ProductPage> storeProducts(
    String store, {
    required Verdict verdict,
    String? category,
    int offset = 0,
    int limit = 20,
  });
}

class BarcodeException implements Exception {
  const BarcodeException(this.message);

  final String message;

  @override
  String toString() => 'BarcodeException: $message';
}

class HttpBarcodeSource implements BarcodeSource {
  const HttpBarcodeSource([this._client]);

  final http.Client? _client;

  /// One client for every request, so its connection is reused.
  static final _shared = http.Client();

  static const _timeout = Duration(seconds: 20);

  @override
  Future<Product?> product(String code) async {
    final json = await _get('api/v2/product/${Uri.encodeComponent(code)}', notFoundOk: true);
    if (json['found'] != true) return null;
    return Product.fromJson(json, barcode: code);
  }

  @override
  Future<List<StoreSummary>> stores() async {
    final json = await _get('api/v2/stores');
    return [
      for (final store in (json['stores'] as List?) ?? const [])
        if (store is Map<String, dynamic>) ?StoreSummary.fromJson(store),
    ];
  }

  @override
  Future<StoreMeta> store(String store) async =>
      StoreMeta.fromJson(await _get('api/v2/store/${Uri.encodeComponent(store)}'));

  @override
  Future<ProductPage> storeProducts(
    String store, {
    required Verdict verdict,
    String? category,
    int offset = 0,
    int limit = 20,
  }) async {
    final json = await _get('api/v2/store/${Uri.encodeComponent(store)}/products', query: {
      'verdict': verdict.name,
      'offset': '$offset',
      'limit': '$limit',
      'category': ?category,
    });
    final products = [
      for (final p in (json['products'] as List?) ?? const [])
        if (p is Map<String, dynamic>) Product.fromJson(p),
    ];
    return ProductPage(
      products: products,
      total: (json['total'] as num?)?.toInt() ?? products.length,
      hasMore: json['hasMore'] == true && products.isNotEmpty,
    );
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query, bool notFoundOk = false}) async {
    var url = AppConfig.apiBase.resolve(path);
    if (query != null) url = url.replace(queryParameters: query);
    final client = _client ?? _shared;
    Future<http.Response> fetch() => client.get(url).timeout(_timeout);
    http.Response response;
    try {
      try {
        response = await fetch();
      } on Exception catch (e) {
        // A dropped connection on a weak signal: once more, after a breath.
        if (e is! SocketException && e is! http.ClientException) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 800));
        response = await fetch();
      }
    } on Exception catch (e) {
      throw BarcodeException('$path: $e');
    }
    final ok = response.statusCode == 200 || (notFoundOk && response.statusCode == 404);
    if (!ok) throw BarcodeException('$path: ${response.statusCode}');
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) return body;
    } on FormatException {
      // Below.
    }
    throw BarcodeException('$path: not JSON');
  }
}
