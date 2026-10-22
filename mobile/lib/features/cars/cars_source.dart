import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'cars_models.dart';

/// The used-car market the Mini App shows (car_api.py on the server): cars
/// read from the channels' posts, by make and model.
abstract interface class CarsSource {
  /// The makes, each with its models and how many listings.
  Future<List<CarBrand>> catalog();

  /// Every listing of a make (and model): on sale first, newest first.
  Future<List<Car>> model(String brand, String? model);

  /// Listings matching [query] (all of them when it's empty), with the
  /// server's count.
  Future<({List<Car> cars, int count})> search(CarQuery query);

  /// A listing in full: its photos and videos, its post, the seller.
  Future<Car> car(int id);

  /// Counts a look at a listing; the new count.
  Future<int?> view(int id);
}

class HttpCarsSource implements CarsSource {
  const HttpCarsSource([this._client]);

  final http.Client? _client;

  static final _shared = http.Client();
  static const _timeout = Duration(seconds: 30);

  http.Client get _http => _client ?? _shared;

  List<Car> _cars(Object? json) => [for (final c in json is List ? json : const []) ?Car.fromJson(c)];

  @override
  Future<List<CarBrand>> catalog() async {
    final json = await _get('catalog');
    return [for (final b in json is List ? json : const []) ?CarBrand.fromJson(b)];
  }

  @override
  Future<List<Car>> model(String brand, String? model) async {
    final json = await _get('model', {'brand': brand, if (model != null && model.isNotEmpty) 'model': model});
    return _cars(json is Map ? json['cars'] : null);
  }

  @override
  Future<({List<Car> cars, int count})> search(CarQuery query) async {
    final json = await _get('search', query.params);
    final cars = _cars(json is Map ? json['cars'] : null);
    final count = json is Map ? json['count'] : null;
    return (cars: cars, count: count is num ? count.toInt() : cars.length);
  }

  @override
  Future<Car> car(int id) async => Car.fromJson(await _get('car', {'id': '$id'})) ?? (throw const CarsException('bad_response'));

  @override
  Future<int?> view(int id) async {
    final response = await _send(http.Request('POST', _url('car/$id/view'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'telegram_user_id': null}));
    final json = _decode(response);
    return json is Map && json['views'] is num ? (json['views'] as num).toInt() : null;
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final url = AppConfig.apiBase.resolve('api/cars/$path');
    return query == null || query.isEmpty ? url : url.replace(queryParameters: query);
  }

  Future<Object?> _get(String path, [Map<String, String>? query]) async {
    final response = await _send(http.Request('GET', _url(path, query))..headers['Accept'] = 'application/json');
    if (response.statusCode >= 400) throw CarsException('http_${response.statusCode}', response.statusCode);
    return _decode(response) ?? (throw const CarsException('bad_response'));
  }

  Future<http.Response> _send(http.Request request) async {
    try {
      return await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on SocketException {
      throw const CarsException('offline');
    } on http.ClientException {
      throw const CarsException('offline');
    } on TimeoutException {
      throw const CarsException('offline');
    }
  }

  static Object? _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }
}
