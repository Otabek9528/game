import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../app_services.dart';
import 'cars_models.dart';
import 'cars_source.dart';

/// What the cars pages share while open: the makes, each model's listings
/// (fetched once), the listings seen in full, and, kept on the phone, the
/// saved ones and the ones already looked at.
class CarsKit extends ChangeNotifier {
  CarsKit(this.services) {
    _favorites = _readFavorites();
    _seen = _readSeen();
  }

  final AppServices services;

  CarsSource get source => services.cars;
  int get thisYear => services.clock().year;

  // ------------------------------------------------------------ makes

  List<CarBrand>? catalog;
  Future<void>? _catalogLoading;

  /// The makes, once (none when offline: the picker says so).
  Future<void> loadCatalog() => _catalogLoading ??= () async {
        try {
          catalog = await source.catalog();
          _notify();
        } on CarsException {
          _catalogLoading = null;
        }
      }();

  /// The make and model a channel's link names ("Hyundai_Sonata"), or a
  /// bare make's first model.
  CarPick? pickFromSlug(String slug) {
    for (final b in catalog ?? const <CarBrand>[]) {
      for (final m in b.models) {
        if (modelSlug(b.brand, m.model) == slug) return (brand: b.brand, model: m.model);
      }
    }
    for (final b in catalog ?? const <CarBrand>[]) {
      if (b.brand.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') == slug && b.models.isNotEmpty) {
        return (brand: b.brand, model: b.models.first.model);
      }
    }
    return null;
  }

  // ------------------------------------------------------------ listings

  final _models = <String, ({List<Car> cars, MarketStats stats})>{};
  final _byId = <int, Car>{};

  static String _key(String? brand, String? model) => '$brand|${model ?? ''}';

  /// A make's (or model's) listings and their market, fetched once.
  Future<({List<Car> cars, MarketStats stats})> modelSet(String brand, String? model) async {
    final key = _key(brand, model);
    if (_models[key] case final kept?) return kept;
    final cars = remember(await source.model(brand, model));
    return _models[key] = (cars: cars, stats: MarketStats.of(cars));
  }

  /// The going price of [car]'s model, when its listings are here already.
  int? medianOf(Car car) => _models[_key(car.brand, car.model)]?.stats.available.med;

  /// [cars], each with what's known of it from before.
  List<Car> remember(List<Car> cars) => [
        for (final c in cars) _byId[c.id] = _byId[c.id]?.mergedWith(c) ?? c,
      ];

  Car? known(int id) => _byId[id];

  /// [id] in full (once), counted as looked at.
  Future<Car> loadFull(int id) async {
    final kept = _byId[id];
    final car = kept != null && kept.full ? kept : remember([await source.car(id)]).single;
    markSeen(id);
    unawaited(_countView(id));
    return car;
  }

  Future<void> _countView(int id) async {
    try {
      final views = await source.view(id);
      if (views == null) return;
      _byId[id] = (_byId[id] ?? Car(id: id)).withViews(views);
      _notify();
    } on CarsException {
      // Not counted this time.
    }
  }

  // ------------------------------------------------------------ saved

  static const _favoritesKey = 'cars_favorites';
  late Map<int, Car> _favorites;

  /// The saved listings, last saved first.
  List<Car> get favorites => [for (final c in _favorites.values.toList().reversed) _byId[c.id] ?? c];

  bool isFavorite(int id) => _favorites.containsKey(id);

  void toggleFavorite(Car car) {
    if (_favorites.remove(car.id) == null) _favorites[car.id] = _byId[car.id] ?? car;
    _saveFavorites();
    _notify();
  }

  /// The saved listings as they are now (sold, price changed); a removed
  /// one stays as last seen.
  Future<void> refreshFavorites() async {
    final ids = _favorites.keys.toList();
    for (var i = 0; i < ids.length; i += 4) {
      await Future.wait([
        for (final id in ids.skip(i).take(4))
          source.car(id).then((c) {
            if (_favorites.containsKey(id)) _favorites[id] = remember([c]).single;
          }, onError: (Object _) {}),
      ]);
    }
    _saveFavorites();
    _notify();
  }

  Map<int, Car> _readFavorites() {
    try {
      final json = jsonDecode(services.store.read(_favoritesKey) ?? '[]');
      final cars = [for (final c in json is List ? json : const []) ?Car.fromJson(c)];
      return {for (final car in cars) car.id: car};
    } on FormatException {
      return {};
    }
  }

  void _saveFavorites() => unawaited(services.store.write(
        _favoritesKey,
        // The short form is enough for the list.
        jsonEncode([for (final c in _favorites.values) (c.toJson()..remove('media')..remove('raw_text'))]),
      ));

  // ------------------------------------------------------------ seen

  static const _seenKey = 'cars_seen';
  late Set<int> _seen;

  bool seen(int id) => _seen.contains(id);

  void markSeen(int id) {
    if (!_seen.add(id)) return;
    final kept = _seen.toList();
    unawaited(services.store.write(_seenKey, jsonEncode(kept.sublist(kept.length > 1500 ? kept.length - 1500 : 0))));
    _notify();
  }

  Set<int> _readSeen() {
    try {
      final json = jsonDecode(services.store.read(_seenKey) ?? '[]');
      return {for (final v in json is List ? json : const []) if (v is int) v};
    } on FormatException {
      return {};
    }
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
