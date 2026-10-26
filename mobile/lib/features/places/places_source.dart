import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../notifications/notify_models.dart';
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

  /// One's areas, watched places and how one is told.
  Future<NotifyMe> notifyMe(Map<String, String> auth);

  /// A new area, or area [id] changed. `address_not_found`, `area_budget`,
  /// `too_many_areas`, `too_many_changes`, `rate_limited` when not.
  Future<NotifyArea> saveArea(Map<String, String> auth, AreaDraft draft, {int? id, required String lang});

  Future<void> deleteArea(Map<String, String> auth, int id);

  /// The places within 10 km of a point or of an address.
  Future<RadiusPreview> inRadius(Map<String, String> auth, {double? lat, double? lon, String? address});

  /// The bot's test message, and the person switched back on.
  Future<void> hello(Map<String, String> auth, String lang);

  /// A Telegram account's choice: the bot, the app, or both.
  Future<NotifyDelivery> setDelivery(Map<String, String> auth, {required bool telegram, required bool push, required String lang});

  /// The web app's photo list: folder → ["ext:hash", ...] by number; empty
  /// when the site has none (the main site doesn't: it answers a missing
  /// file with its home page).
  Future<Map<String, List<String>>> photoManifest();

  /// Whether a photo is at [url]: its version (ETag or date) if so, null if
  /// not. Asked with HEAD, so a missing file costs no download.
  Future<String?> photoTag(Uri url);
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
  Future<NotifyMe> notifyMe(Map<String, String> auth) async =>
      notifyMeFromJson(_check(await _send('GET', 'api/notify/me', headers: auth)));

  @override
  Future<NotifyArea> saveArea(Map<String, String> auth, AreaDraft draft, {int? id, required String lang}) async {
    final body = {
      'source': draft.address == null ? 'location' : 'address',
      if (draft.address != null) 'address': draft.address,
      if (draft.address == null) ...{'lat': draft.lat, 'lon': draft.lon, 'label': draft.label},
      'radiusKm': draft.radiusKm,
      'types': [for (final k in PlaceKind.values) if (draft.types.contains(k)) k.key],
      'lang': lang,
    };
    final json = _check(await _send(id == null ? 'POST' : 'PUT', id == null ? 'api/notify/areas' : 'api/notify/areas/$id',
        headers: auth, body: body));
    return NotifyArea.fromJson(json['area']) ?? (throw const PlacesException('bad_response'));
  }

  @override
  Future<void> deleteArea(Map<String, String> auth, int id) async =>
      _check(await _send('DELETE', 'api/notify/areas/$id', headers: auth));

  @override
  Future<RadiusPreview> inRadius(Map<String, String> auth, {double? lat, double? lon, String? address}) async {
    final json = _check(await _send('GET', 'api/places/in-radius',
        headers: auth, query: address != null ? {'address': address} : {'lat': '$lat', 'lon': '$lon'}));
    return radiusPreviewFromJson(json) ?? (throw const PlacesException('bad_response'));
  }

  @override
  Future<void> hello(Map<String, String> auth, String lang) async =>
      _check(await _send('POST', 'api/notify/hello', headers: auth, body: {'lang': lang}));

  @override
  Future<NotifyDelivery> setDelivery(Map<String, String> auth, {required bool telegram, required bool push, required String lang}) async =>
      NotifyDelivery.fromJson(_check(await _send('PUT', 'api/notify/delivery',
          headers: auth, body: {'telegram': telegram, 'push': push, 'lang': lang}))['delivery']);

  @override
  Future<Map<String, List<String>>> photoManifest() async {
    final http.Response response;
    try {
      response = await _http.get(AppConfig.photosBase.resolve('Photos/manifest.json')).timeout(_timeout);
    } on Exception catch (e) {
      throw _offline(e);
    }
    if (response.statusCode >= 500) throw PlacesException('http_${response.statusCode}', response.statusCode);
    final folders = _json(response)['folders'];
    if (response.statusCode != 200 || folders is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in folders.entries)
        if (value is List) '$key': [for (final v in value) '$v'],
    };
  }

  @override
  Future<String?> photoTag(Uri url) async {
    final http.Response response;
    try {
      response = await _http.head(url).timeout(_timeout);
    } on Exception catch (e) {
      throw _offline(e);
    }
    if (response.statusCode >= 500) throw PlacesException('http_${response.statusCode}', response.statusCode);
    // The site's home page stands in for a missing file, with a 200.
    if (response.statusCode != 200 || !(response.headers['content-type'] ?? '').startsWith('image/')) return null;
    final tag = (response.headers['etag'] ?? response.headers['last-modified'] ?? '').replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return tag.length > 12 ? tag.substring(tag.length - 12) : tag;
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
