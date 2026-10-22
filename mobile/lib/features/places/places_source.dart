import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'places_models.dart';

/// Places near an address the server found.
typedef AddressPlaces = ({List<Place> places, double? lat, double? lon, String? label});

/// Mosques, restaurants and shops, from the server the Mini App uses
/// (places_api_protected.py, places_public_api.py, place_submissions_api.py,
/// place_notifications_api.py). [auth] is the app account's header: an app
/// user who hasn't signed in may watch places; reviews, suggestions,
/// announcements and claims need someone signed in (`sign_in_required`).
abstract interface class PlacesSource {
  /// The nearest [limit], with their distance. Five, as the web page shows:
  /// the places aren't handed out more than a few at a time.
  Future<List<Place>> nearby(PlaceKind kind, double lat, double lon, {int limit = 5});

  /// The nearest ones to an address in Korean, found by the server.
  Future<AddressPlaces> nearAddress(PlaceKind kind, String address, {int limit = 5});

  /// Counts a view.
  Future<PlaceDetail> detail(int id, Map<String, String> auth);

  /// Writes one's review (or rewrites it: true).
  Future<bool> review(Map<String, String> auth, int id, int rating, String text);

  Future<void> deleteReview(Map<String, String> auth, int id);

  /// A link or the note, for the admin to check: telegram, tiktok,
  /// instagram, note.
  Future<void> suggest(Map<String, String> auth, int id, String field, String value);

  Future<PlaceWatch> watch(Map<String, String> auth, int id, {required bool on, required String lang});

  /// How many people an announcement would reach.
  Future<int> reach(Map<String, String> auth, int id);

  /// Returns how many of this person's announcements wait for the admin.
  Future<int> announce(Map<String, String> auth, int id, String text, String lang);

  Future<void> claim(Map<String, String> auth, int id, String lang);

  Future<List<WatchedPlace>> watched(Map<String, String> auth);

  /// The web app's photo list: folder → ["webp hash", ...] by number.
  Future<Map<String, List<String>>> photoManifest();
}

class HttpPlacesSource implements PlacesSource {
  const HttpPlacesSource([this._client]);

  final http.Client? _client;

  static final _shared = http.Client();
  static const _timeout = Duration(seconds: 30);

  http.Client get _http => _client ?? _shared;

  List<Place> _places(Map<String, dynamic> json, PlaceKind kind) =>
      [for (final p in (json['places'] as List?) ?? const []) ?Place.fromJson(p, kind: kind)];

  @override
  Future<List<Place>> nearby(PlaceKind kind, double lat, double lon, {int limit = 5}) async {
    final json = _check(await _send('GET', 'api/places/nearby', query: {
      'lat': '$lat',
      'lon': '$lon',
      'building_type': kind.buildingType,
      'limit': '$limit',
    }));
    return _places(json, kind);
  }

  @override
  Future<AddressPlaces> nearAddress(PlaceKind kind, String address, {int limit = 5}) async {
    final json = _check(await _send('GET', 'api/places/by-address',
        query: {'address': address, 'building_type': kind.buildingType, 'limit': '$limit'}));
    final at = json['geocoded_location'];
    return (
      places: _places(json, kind),
      lat: at is Map ? (at['lat'] as num?)?.toDouble() : null,
      lon: at is Map ? (at['lon'] as num?)?.toDouble() : null,
      label: at is Map ? at['display_name'] as String? : null,
    );
  }

  @override
  Future<PlaceDetail> detail(int id, Map<String, String> auth) async {
    final json = _check(await _send('GET', 'api/place/$id', query: {'view': '1'}, headers: auth));
    return PlaceDetail.fromJson(json['place']) ?? (throw const PlacesException('bad_response'));
  }

  @override
  Future<bool> review(Map<String, String> auth, int id, int rating, String text) async {
    final json = _check(await _send('POST', 'api/review/submit',
        headers: auth, body: {'place_id': id, 'rating': rating, 'review_text': text}));
    return json['updated'] == true;
  }

  @override
  Future<void> deleteReview(Map<String, String> auth, int id) async =>
      _check(await _send('DELETE', 'api/review/$id', headers: auth));

  @override
  Future<void> suggest(Map<String, String> auth, int id, String field, String value) async =>
      _check(await _send('POST', 'api/place/$id/submit', headers: auth, body: {'field': field, 'value': value}));

  @override
  Future<PlaceWatch> watch(Map<String, String> auth, int id, {required bool on, required String lang}) async {
    final json = _check(await _send(on ? 'POST' : 'DELETE', 'api/notify/watch/$id',
        headers: auth, body: on ? {'lang': lang} : null));
    return PlaceWatch(count: (json['watchCount'] as num?)?.toInt() ?? 0, watching: json['watching'] == true);
  }

  @override
  Future<int> reach(Map<String, String> auth, int id) async =>
      (_check(await _send('GET', 'api/notify/announce/$id/reach', headers: auth))['count'] as num?)?.toInt() ?? 0;

  @override
  Future<int> announce(Map<String, String> auth, int id, String text, String lang) async {
    final json = _check(await _send('POST', 'api/notify/announce/$id', headers: auth, body: {'text': text, 'lang': lang}));
    return (json['pendingAnnouncements'] as num?)?.toInt() ?? 1;
  }

  @override
  Future<void> claim(Map<String, String> auth, int id, String lang) async =>
      _check(await _send('POST', 'api/notify/claim/$id', headers: auth, body: {'lang': lang}));

  @override
  Future<List<WatchedPlace>> watched(Map<String, String> auth) async {
    final json = _check(await _send('GET', 'api/notify/me', headers: auth));
    return [for (final w in (json['watches'] as List?) ?? const []) ?WatchedPlace.fromJson(w)];
  }

  @override
  Future<Map<String, List<String>>> photoManifest() async {
    final http.Response response;
    try {
      response = await _http.get(AppConfig.photosBase.resolve('Photos/manifest.json')).timeout(_timeout);
    } on Exception catch (e) {
      throw _offline(e);
    }
    final folders = _json(response)['folders'];
    if (response.statusCode != 200 || folders is! Map) throw PlacesException('http_${response.statusCode}', response.statusCode);
    return {
      for (final MapEntry(:key, :value) in folders.entries)
        if (value is List) '$key': [for (final v in value) '$v'],
    };
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Object? body,
  }) async {
    var url = AppConfig.apiBase.resolve(path);
    if (query != null) url = url.replace(queryParameters: query);
    final request = http.Request(method, url)..headers.addAll(headers ?? const {});
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    try {
      return await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on Exception catch (e) {
      throw _offline(e);
    }
  }

  static Exception _offline(Exception e) =>
      e is SocketException || e is http.ClientException || e is TimeoutException ? const PlacesException('offline') : e;

  static Map<String, dynamic> _json(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json is Map<String, dynamic> ? json : const {};
    } on FormatException {
      return const {};
    }
  }

  static Map<String, dynamic> _check(http.Response response) {
    final json = _json(response);
    if (response.statusCode >= 400 || json['success'] == false) {
      throw PlacesException(
        json['code'] as String? ?? 'http_${response.statusCode}',
        response.statusCode,
        json['error'] as String?,
      );
    }
    return json;
  }
}
