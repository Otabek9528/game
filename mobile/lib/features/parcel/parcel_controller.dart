import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/key_value_store.dart';
import 'parcel_models.dart';
import 'parcel_source.dart';

/// One request's state: still loading, failed, or its result.
class Fetch<T> {
  const Fetch.loading()
      : data = null,
        failed = false;
  const Fetch.failed()
      : data = null,
        failed = true;
  const Fetch.done(T value)
      : data = value,
        failed = false;

  final T? data;
  final bool failed;

  bool get loading => data == null && !failed;
}

/// How the posts are looked up, as on the web page.
enum ParcelMode { byDate, byCity }

/// The parcel page's state: the direction (remembered), the days couriers
/// fly with the chosen day's posts, and the cities.
class ParcelController extends ChangeNotifier {
  ParcelController({required this._source, required KeyValueStore store})
      : _store = store,
        // Most people here live in Korea and send home: that until they swap.
        direction = store.read(_key) == '0' ? ParcelDirection.uzbToKor : ParcelDirection.korToUzb {
    country = direction.from;
  }

  static const _key = 'parcel_direction';

  final ParcelSource _source;
  final KeyValueStore _store;

  ParcelDirection direction;
  ParcelMode mode = ParcelMode.byDate;

  Fetch<List<ParcelDate>> dates = const Fetch.loading();
  ParcelDate? selected;

  /// The chosen day's posts.
  Fetch<List<ParcelPost>> posts = const Fetch.loading();

  /// Cities of the departure country first, as the web page does.
  late ParcelCountry country;

  /// Null until the cities are first wanted.
  Fetch<List<ParcelCity>>? cities;

  /// Bumped when the direction changes: answers to older requests are
  /// dropped.
  int _generation = 0;
  String? _postsKey;
  ParcelCountry? _citiesFor;
  bool _disposed = false;

  Future<void> start() => _loadDates();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> swap() async {
    direction = direction.other;
    country = direction.from;
    unawaited(_store.write(_key, '${direction.api}'));
    _generation++;
    dates = const Fetch.loading();
    selected = null;
    posts = const Fetch.loading();
    _postsKey = null;
    cities = null;
    _citiesFor = null;
    _notify();
    await Future.wait([_loadDates(), if (mode == ParcelMode.byCity) _loadCities()]);
  }

  void setMode(ParcelMode value) {
    if (mode == value) return;
    mode = value;
    _notify();
    if (value == ParcelMode.byCity && (cities == null || cities!.failed)) unawaited(_loadCities());
  }

  Future<void> select(ParcelDate date) async {
    if (selected?.key == date.key && posts.data != null) return;
    selected = date;
    await _loadPosts();
  }

  Future<void> setCountry(ParcelCountry value) async {
    if (country == value && cities?.data != null) return;
    country = value;
    await _loadCities();
  }

  /// Pull to refresh, or "try again". False when it failed; whatever was
  /// shown stays.
  Future<bool> refresh() => mode == ParcelMode.byDate ? _loadDates() : _loadCities();

  /// For a city's own page.
  Future<List<ParcelPost>> postsByCity(String city, ParcelCountry country, ParcelDirection direction) =>
      _source.postsByCity(city, country, direction);

  Future<bool> _loadDates() async {
    final generation = _generation;
    if (dates.data == null) {
      dates = const Fetch.loading();
      _notify();
    }
    try {
      final list = await _source.dates(direction);
      if (generation != _generation) return true;
      dates = Fetch.done(list);
      // The chosen day while it is still listed; else the first.
      selected = list.where((d) => d.key == selected?.key).firstOrNull ?? list.firstOrNull;
      if (selected == null) {
        posts = const Fetch.done([]);
        _postsKey = null;
        _notify();
        return true;
      }
      _notify();
      return await _loadPosts();
    } catch (_) {
      if (generation != _generation) return true;
      if (dates.data == null) dates = const Fetch.failed();
      _notify();
      return false;
    }
  }

  Future<bool> _loadPosts() async {
    final generation = _generation;
    final date = selected!;
    // Another day: its posts load in place of the last day's. The same day
    // again: those stay up until the new ones come.
    if (_postsKey != date.key || posts.data == null) {
      posts = const Fetch.loading();
      _postsKey = date.key;
      _notify();
    }
    bool current() => generation == _generation && selected?.key == date.key;
    try {
      final list = await _source.postsByDate(date.key, direction);
      if (!current()) return true;
      posts = Fetch.done(list);
      _notify();
      return true;
    } catch (_) {
      if (!current()) return true;
      if (posts.data == null) posts = const Fetch.failed();
      _notify();
      return false;
    }
  }

  Future<bool> _loadCities() async {
    final generation = _generation;
    final wanted = country;
    // Another country: its list loads in place of the last one's.
    if (_citiesFor != wanted || cities?.data == null) {
      cities = const Fetch.loading();
      _citiesFor = wanted;
      _notify();
    }
    bool current() => generation == _generation && country == wanted;
    try {
      final list = await _source.cities(wanted, direction);
      if (!current()) return true;
      cities = Fetch.done(list);
      _notify();
      return true;
    } catch (_) {
      if (!current()) return true;
      if (cities?.data == null) cities = const Fetch.failed();
      _notify();
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
