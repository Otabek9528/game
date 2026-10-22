import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/config.dart';
import '../prayer/prayer_models.dart';
import 'places_models.dart';
import 'places_source.dart';

/// A photo of a place: the size for the page, and a small one for lists.
typedef PlacePhoto = ({Uri full, Uri thumb});

/// What the place pages share while open: each kind's places (kept on the
/// phone and asked again with the server's tag, so an unchanged list costs
/// nothing), the place pages seen, the photo list, the places this person
/// watches, and the ones they looked at last.
///
/// The location is the prayer times' own ([AppServices.prayer]): someone who
/// set it for the times gets the nearest places first without being asked.
class PlacesKit extends ChangeNotifier {
  PlacesKit(this.services);

  final AppServices services;

  PlacesSource get source => services.places;
  AppLanguage get language => services.locale.language ?? AppLanguage.uz;

  /// Where distances are measured from; null when never located.
  SavedLocation? get here => services.prayer.place;

  final _lists = <PlaceKind, List<Place>>{};
  final _loading = <PlaceKind, Future<void>>{};
  final _failed = <PlaceKind, String>{};
  final _details = <int, PlaceDetail>{};
  Map<String, List<String>>? _manifest;
  Set<int>? _watched;

  /// The server answers nearby and by-address only (before update 6): the
  /// list is then the nearest few, and search looks around an address.
  bool fewOnly = false;

  /// A kind's places as known (on the phone or fresh); null before any.
  List<Place>? placesOf(PlaceKind kind) => _lists[kind];

  /// Why the last load failed: `offline`, `needs_location`, a server code.
  String? failureOf(PlaceKind kind) => _failed[kind];

  bool loading(PlaceKind kind) => _loading.containsKey(kind);

  PlaceDetail? detailOf(int id) => _details[id];

  bool watching(int id) => _details[id]?.watch.watching ?? _watched?.contains(id) ?? false;

  /// Loads [kind]'s list: what the phone keeps at once, then the server's.
  Future<void> load(PlaceKind kind, {bool refresh = false}) {
    if (!refresh && _lists[kind] != null && _failed[kind] == null && !fewOnly) return Future.value();
    return _loading[kind] ??= _load(kind).whenComplete(() {
      _loading.remove(kind);
      _notify();
    });
  }

  String _cacheKey(PlaceKind kind) => 'places_${kind.key}';

  Future<void> _load(PlaceKind kind) async {
    String? etag;
    if (_lists[kind] == null) {
      final kept = _readCache(kind);
      if (kept != null) {
        _lists[kind] = kept.places;
        etag = kept.etag;
        _notify();
      }
    } else {
      etag = _etags[kind];
    }
    _failed.remove(kind);
    if (!fewOnly) {
      try {
        final fresh = await source.all(kind, etag: etag);
        if (fresh != null) {
          _lists[kind] = fresh.places;
          _etags[kind] = fresh.etag;
          await services.store.write(_cacheKey(kind), jsonEncode({
            'etag': fresh.etag,
            'places': [for (final p in fresh.places) p.toJson()],
          }));
        }
        return;
      } on PlacesException catch (e) {
        if (e.code != 'unsupported') {
          // Offline with a kept list: it stays, quietly.
          if (_lists[kind] == null) _failed[kind] = e.code;
          return;
        }
        fewOnly = true;
      }
    }
    final at = here;
    if (at == null) {
      _failed[kind] = 'needs_location';
      return;
    }
    try {
      _lists[kind] = await source.nearby(kind, at.lat, at.lon);
    } on PlacesException catch (e) {
      _failed[kind] = e.code;
    }
  }

  final _etags = <PlaceKind, String?>{};

  ({List<Place> places, String? etag})? _readCache(PlaceKind kind) {
    try {
      final json = jsonDecode(services.store.read(_cacheKey(kind)) ?? '');
      if (json is! Map<String, dynamic>) return null;
      final places = [for (final p in (json['places'] as List?) ?? const []) ?Place.fromJson(p, kind: kind)];
      _etags[kind] = json['etag'] as String?;
      return (places: places, etag: json['etag'] as String?);
    } on FormatException {
      return null;
    }
  }

  /// A new location fix (asking for the permission if needed); the nearest
  /// few again when that is all the server gives.
  Future<void> locate(PlaceKind kind) async {
    await services.prayer.locate(userAsked: true);
    if (fewOnly && here != null) await load(kind, refresh: true);
    _notify();
  }

  /// Distance from [here], in km.
  double? distanceTo(Place place) {
    final at = here;
    return at == null ? place.distanceKm : place.distanceFrom(at.lat, at.lon) ?? place.distanceKm;
  }

  /// The cities of [kind]'s places, the busiest first.
  List<(String, int)> citiesOf(PlaceKind kind) {
    final counts = <String, int>{};
    for (final p in _lists[kind] ?? const <Place>[]) {
      if (p.city case final city?) counts[city] = (counts[city] ?? 0) + 1;
    }
    return counts.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
  }

  /// [kind]'s places in [city] matching [query]: the best matches first,
  /// then the nearest (or by city and name when there is no location).
  /// [from] measures from there instead of [here] (an address searched).
  List<Place> find(PlaceKind kind, {String? city, String query = '', ({double lat, double lon})? from}) {
    final q = foldForSearch(query);
    double? km(Place p) => from != null ? p.distanceFrom(from.lat, from.lon) : distanceTo(p);
    int rank(Place p) {
      if (q.isEmpty) return 0;
      final name = foldForSearch(p.name);
      if (name.startsWith(q) || name.split(' ').any((w) => w.startsWith(q))) return 0;
      if (name.contains(q)) return 1;
      if (foldForSearch(p.city ?? '').contains(q)) return 2;
      if (foldForSearch(p.address ?? '').contains(q)) return 3;
      return -1;
    }

    final found = [
      for (final p in _lists[kind] ?? const <Place>[])
        if ((city == null || p.city == city) && rank(p) >= 0) (p, rank(p), km(p)),
    ]..sort((a, b) {
        if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
        final (da, db) = (a.$3, b.$3);
        if (da != null || db != null) {
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        }
        final byCity = (a.$1.city ?? '~').compareTo(b.$1.city ?? '~');
        return byCity != 0 ? byCity : a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());
      });
    return [for (final f in found) f.$1];
  }

  /// The server finds a Korean address; its point, and the places near it.
  Future<AddressPlaces> nearAddress(PlaceKind kind, String address) => source.nearAddress(kind, address);

  /// The account's header; the account is made when missing. Empty offline.
  Future<Map<String, String>> auth() async {
    try {
      await services.account.ensure();
    } catch (_) {}
    return services.account.authHeaders;
  }

  Future<PlaceDetail> loadDetail(int id) async {
    final detail = _details[id] = await source.detail(id, await auth());
    // The list learns the page's newer numbers.
    for (final list in _lists.values) {
      final i = list.indexWhere((p) => p.id == id);
      if (i != -1) {
        list[i] = Place.fromJson({...detail.place.toJson(), 'reviewCount': detail.reviews.length, 'averageRating': detail.average}) ??
            list[i];
      }
    }
    _remember(detail.place);
    _notify();
    return detail;
  }

  void putDetail(PlaceDetail detail) {
    _details[detail.place.id] = detail;
    if (_watched != null) {
      detail.watch.watching ? _watched!.add(detail.place.id) : _watched!.remove(detail.place.id);
    }
    _notify();
  }

  /// Which places this person watches; quietly nothing when offline.
  Future<void> loadWatched() async {
    try {
      final auth = await this.auth();
      if (auth.isEmpty) return;
      _watched = {for (final w in await source.watched(auth)) w.id};
      _notify();
    } on PlacesException {
      // As it was.
    }
  }

  // ---------------------------------------------------------------- photos

  static const _photosKey = 'places_photos';

  /// The photos of [place], by the web app's list (Photos/manifest.json).
  List<PlacePhoto> photosOf(Place place) {
    final folder = _cleanFolder(place.photoFolder);
    if (folder == null) return const [];
    final entries = (_manifest ??= _readManifest())?[folder];
    if (entries == null) return const [];
    return [
      for (var i = 0; i < entries.length && i < 10; i++)
        (
          full: AppConfig.webBase.resolve('$folder/${i + 1}.webp?v=${entries[i].split(':').last}'),
          thumb: AppConfig.webBase.resolve('$folder/${i + 1}.thumb.webp?v=${entries[i].split(':').last}'),
        ),
    ];
  }

  Future<void>? _manifestLoading;

  /// Fetches the photo list once a session (kept on the phone between).
  Future<void> loadPhotos() => _manifestLoading ??= () async {
        try {
          _manifest = await source.photoManifest();
          await services.store.write(_photosKey, jsonEncode(_manifest));
          _notify();
        } on Exception {
          _manifest ??= _readManifest();
          _manifestLoading = null;
        }
      }();

  Map<String, List<String>>? _readManifest() {
    try {
      final json = jsonDecode(services.store.read(_photosKey) ?? '');
      if (json is! Map) return null;
      return {for (final e in json.entries) if (e.value is List) '${e.key}': [for (final v in e.value as List) '$v']};
    } on FormatException {
      return null;
    }
  }

  static String? _cleanFolder(String? path) {
    final p = (path ?? '').trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (p.isEmpty || !RegExp(r'^[\w\-./ ]+$').hasMatch(p) || p.contains('..')) return null;
    return p;
  }

  // ---------------------------------------------------------------- recent

  static const _recentKey = 'places_recent';

  /// The places looked at last, newest first, of every kind.
  List<Place> get recent {
    try {
      final json = jsonDecode(services.store.read(_recentKey) ?? '[]');
      return [for (final p in json is List ? json : const []) ?Place.fromJson(p)];
    } on FormatException {
      return const [];
    }
  }

  void _remember(Place place) {
    final list = [place, ...recent.where((p) => p.id != place.id)].take(12);
    unawaited(services.store.write(_recentKey, jsonEncode([for (final p in list) p.toJson()])));
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

/// For matching what people type: lower case, Cyrillic as Latin (Uzbek
/// spelling), no apostrophes or dashes, single spaces.
String foldForSearch(String text) {
  const cyrillic = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'j', 'з': 'z', 'и': 'i',
    'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't',
    'у': 'u', 'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sh', 'ъ': '', 'ы': 'i', 'ь': '',
    'э': 'e', 'ю': 'yu', 'я': 'ya', 'ў': 'o', 'қ': 'q', 'ғ': 'g', 'ҳ': 'h',
  };
  final out = StringBuffer();
  for (final ch in text.toLowerCase().split('')) {
    out.write(cyrillic[ch] ?? ch);
  }
  return out
      .toString()
      .replaceAll(RegExp("[ʻʼ'`‘’ʹ-]"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Whether [text] has Korean letters: an address to look around.
bool hasHangul(String text) => RegExp(r'[가-힣ㄱ-ㆎ]').hasMatch(text);
