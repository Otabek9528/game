import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/config.dart';
import '../prayer/prayer_controller.dart';
import 'places_models.dart';
import 'places_source.dart';

/// A photo of a place: the size for the page, and a small one for lists.
typedef PlacePhoto = ({Uri full, Uri thumb});

/// Where a search's places were measured from: the phone now, the location
/// saved earlier (no new fix could be taken), or an address.
enum PlaceOrigin { here, saved, address }

/// A search's answer: the nearest five, and the point they are measured from.
@immutable
class PlacesFound {
  const PlacesFound({
    required this.places,
    required this.origin,
    required this.lat,
    required this.lon,
    this.label,
    this.at,
  });

  final List<Place> places;
  final PlaceOrigin origin;
  final double lat;
  final double lon;

  /// The city of the location, or the address as the server found it.
  final String? label;

  /// When the location was taken.
  final DateTime? at;

  /// [place]'s distance from the point searched around, in km.
  double? kmTo(Place place) => place.distanceKm ?? place.distanceFrom(lat, lon);
}

/// What the place pages share while open: the searches (always a fresh
/// location fix for "near me": the prayer card's saved one can be hours and
/// kilometres old), the place pages seen, the photo list, the places this
/// person watches, and the addresses searched lately.
class PlacesKit extends ChangeNotifier {
  PlacesKit(this.services);

  final AppServices services;

  PlacesSource get source => services.places;
  AppLanguage get language => services.locale.language ?? AppLanguage.uz;

  final _details = <int, PlaceDetail>{};
  Map<String, List<String>>? _manifest;
  Set<int>? _watched;

  PlaceDetail? detailOf(int id) => _details[id];

  bool watching(int id) => _details[id]?.watch.watching ?? _watched?.contains(id) ?? false;

  /// Whether a location can be taken without asking: then "near me" runs
  /// as the page opens.
  Future<bool> locationAllowed() => services.prayer.hasLocationAccess();

  /// The nearest five to where the phone is now. Without a new fix, those
  /// to the location saved before ([PlaceOrigin.saved]); without either,
  /// throws why: `location_denied`, `location_blocked`, `location_off`,
  /// `location_failed`.
  Future<PlacesFound> nearMe(PlaceKind kind) async {
    final prayer = services.prayer;
    final fix = await prayer.freshFix(userAsked: true);
    if (fix != null) {
      return PlacesFound(
        places: await source.nearby(kind, fix.lat, fix.lon),
        origin: PlaceOrigin.here,
        lat: fix.lat,
        lon: fix.lon,
        label: prayer.place?.city,
        at: prayer.now,
      );
    }
    final saved = prayer.place;
    if (saved == null) {
      throw PlacesException(switch (prayer.status) {
        PrayerStatus.permissionBlocked => 'location_blocked',
        PrayerStatus.locationOff => 'location_off',
        PrayerStatus.needsPermission => 'location_denied',
        _ => 'location_failed',
      });
    }
    return PlacesFound(
      places: await source.nearby(kind, saved.lat, saved.lon),
      origin: PlaceOrigin.saved,
      lat: saved.lat,
      lon: saved.lon,
      label: saved.city,
      at: saved.timestamp,
    );
  }

  /// The nearest five to an address in Korean; `address_not_found` when the
  /// server can't find it.
  Future<PlacesFound> nearAddress(PlaceKind kind, String address) async {
    final AddressPlaces found;
    try {
      found = await source.nearAddress(kind, address);
    } on PlacesException catch (e) {
      throw e.status == 404 ? const PlacesException('address_not_found', 404) : e;
    }
    if (found.lat == null || found.lon == null) throw const PlacesException('address_not_found', 404);
    _rememberAddress(address);
    return PlacesFound(
      places: found.places,
      origin: PlaceOrigin.address,
      lat: found.lat!,
      lon: found.lon!,
      label: found.label ?? address,
    );
  }

  static const _addressesKey = 'places_addresses';

  /// The addresses searched lately, newest first.
  List<String> get addresses {
    try {
      final json = jsonDecode(services.store.read(_addressesKey) ?? '[]');
      return [for (final a in json is List ? json : const []) if (a is String) a];
    } on FormatException {
      return const [];
    }
  }

  void _rememberAddress(String address) {
    final list = [address, ...addresses.where((a) => a != address)].take(3).toList();
    unawaited(services.store.write(_addressesKey, jsonEncode(list)));
    _notify();
  }

  /// The account's header; the account is made when missing. Empty offline.
  Future<Map<String, String>> auth() async {
    try {
      await services.account.ensure();
    } catch (_) {}
    return services.account.authHeaders;
  }

  Future<PlaceDetail> loadDetail(int id) async {
    final detail = _details[id] = await source.detail(id, await auth());
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
          full: AppConfig.photosBase.resolve('$folder/${i + 1}.webp?v=${entries[i].split(':').last}'),
          thumb: AppConfig.photosBase.resolve('$folder/${i + 1}.thumb.webp?v=${entries[i].split(':').last}'),
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

/// Whether [text] has Korean letters.
bool hasHangul(String text) => RegExp(r'[가-힣ㄱ-ㆎ]').hasMatch(text);
