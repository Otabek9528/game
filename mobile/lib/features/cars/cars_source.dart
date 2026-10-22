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

  // With the app's account ([auth]): saved cars need none signed in; alerts
  // and posts do (`sign_in_required`).

  Future<Set<int>> favoriteIds(Map<String, String> auth);

  Future<void> setFavorite(Map<String, String> auth, int id, {required bool on});

  Future<List<CarAlert>> alerts(Map<String, String> auth);

  /// `validation_failed` (no filter), `duplicate_alert`, `limit_reached`.
  Future<CarAlert> addAlert(Map<String, String> auth, CarQuery query);

  Future<void> deleteAlert(Map<String, String> auth, int id);

  Future<List<OwnCar>> ownCars(Map<String, String> auth);

  /// A new post, as a draft; its number.
  Future<int> createPost(Map<String, String> auth, CarPost post);

  Future<void> editPost(Map<String, String> auth, int id, CarPost post);

  /// A photo or video for a draft: [bytes] of the file named [name].
  Future<void> addMedia(Map<String, String> auth, int id, List<int> bytes, String name, {required bool video, required int order});

  /// Listings the post looks the same as.
  Future<List<CarDuplicate>> duplicates(Map<String, String> auth, CarPost post, {int? except});

  /// To the admin; `duplicate` (with its matches) or `no_media` if not.
  Future<void> submitPost(Map<String, String> auth, int id);

  Future<void> markSold(Map<String, String> auth, int id);

  Future<void> withdrawPost(Map<String, String> auth, int id);
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

  @override
  Future<Set<int>> favoriteIds(Map<String, String> auth) async {
    final json = await _call('GET', 'favorites/ids', auth);
    return {for (final v in (json['ids'] as List?) ?? const []) if (v is num) v.toInt()};
  }

  @override
  Future<void> setFavorite(Map<String, String> auth, int id, {required bool on}) async => on
      ? await _call('POST', 'favorites', auth, body: {'listing_id': id})
      : await _call('DELETE', 'favorites', auth, query: {'listing_id': '$id'});

  @override
  Future<List<CarAlert>> alerts(Map<String, String> auth) async =>
      [for (final a in ((await _call('GET', 'alerts', auth))['alerts'] as List?) ?? const []) ?CarAlert.fromJson(a)];

  @override
  Future<CarAlert> addAlert(Map<String, String> auth, CarQuery query) async {
    final json = await _call('POST', 'alerts', auth, body: {
      'brand': query.pick?.brand,
      'model': query.pick?.model,
      'price_max': query.priceMax,
      'mileage_max': query.mileageMax,
      'year_from': query.yearFrom,
      'fuel': query.fuels.toList(),
      'lang': 'uz',
    });
    return CarAlert.fromJson(json['alert']) ?? (throw const CarsException('bad_response'));
  }

  @override
  Future<void> deleteAlert(Map<String, String> auth, int id) => _call('DELETE', 'alerts/$id', auth);

  @override
  Future<List<OwnCar>> ownCars(Map<String, String> auth) async {
    final response = await _send(http.Request('GET', _url('my/listings'))..headers.addAll(auth));
    final json = _decode(response);
    if (response.statusCode >= 400) throw _error(response, json);
    return [for (final c in json is List ? json : const []) ?OwnCar.fromJson(c)];
  }

  @override
  Future<int> createPost(Map<String, String> auth, CarPost post) async =>
      ((await _call('POST', 'listings', auth, body: post.toJson()))['id'] as num).toInt();

  @override
  Future<void> editPost(Map<String, String> auth, int id, CarPost post) => _call('POST', 'listings/$id/edit', auth, body: post.toJson());

  @override
  Future<void> addMedia(Map<String, String> auth, int id, List<int> bytes, String name, {required bool video, required int order}) async {
    final request = http.MultipartRequest('POST', _url('listings/$id/media'))
      ..headers.addAll(auth)
      ..fields['media_type'] = video ? 'video' : 'photo'
      ..fields['ord'] = '$order'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(const Duration(minutes: 3)));
    } on Exception {
      throw const CarsException('offline');
    }
    if (response.statusCode >= 400) throw _error(response, _decode(response));
  }

  @override
  Future<List<CarDuplicate>> duplicates(Map<String, String> auth, CarPost post, {int? except}) async {
    final json = await _call('POST', 'listings/check-duplicate', auth, body: {...post.toJson(), 'phone': post.phone, 'exclude_id': except});
    return [for (final m in (json['matches'] as List?) ?? const []) ?CarDuplicate.fromJson(m)];
  }

  @override
  Future<void> submitPost(Map<String, String> auth, int id) => _call('POST', 'listings/$id/submit', auth, body: const {});

  @override
  Future<void> markSold(Map<String, String> auth, int id) => _call('POST', 'listings/$id/sold', auth, body: const {});

  @override
  Future<void> withdrawPost(Map<String, String> auth, int id) => _call('DELETE', 'listings/$id', auth);

  /// A call with the account; its JSON, or the server's error as a code.
  Future<Map<String, dynamic>> _call(String method, String path, Map<String, String> auth,
      {Map<String, String>? query, Object? body}) async {
    final request = http.Request(method, _url(path, query))
      ..headers.addAll(auth)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    final response = await _send(request);
    final json = _decode(response);
    if (response.statusCode >= 400) throw _error(response, json);
    return json is Map<String, dynamic> ? json : const {};
  }

  static CarsException _error(http.Response response, Object? json) {
    final map = json is Map ? json : const {};
    return CarsException(
      map['error'] as String? ?? 'http_${response.statusCode}',
      response.statusCode,
      [for (final m in (map['matches'] as List?) ?? const []) ?CarDuplicate.fromJson(m)],
    );
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
