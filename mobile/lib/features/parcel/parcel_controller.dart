import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/key_value_store.dart';
import 'parcel_cache.dart';
import 'parcel_models.dart';
import 'parcel_saved.dart';
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
/// fly and each day's posts, and the cities.
///
/// Made for slow connections: what was loaded last time shows at once (from
/// [ParcelCache]) while fresh lists load behind it; days' posts load only as
/// they come into view, two at a time; nothing already shown is wiped by a
/// failed refresh.
class ParcelController extends ChangeNotifier {
  ParcelController({required this._source, required KeyValueStore store, DateTime Function()? clock})
      : _store = store,
        _cache = ParcelCache(store),
        saved = SavedParcels(store),
        _clock = clock ?? DateTime.now,
        direction = rememberedDirection(store) {
    country = direction.from;
  }

  static const _directionKey = 'parcel_direction';
  static const _noticeKey = 'parcel_notice';

  /// Two days' posts load at once: enough to stay ahead of scrolling, few
  /// enough not to choke a slow line.
  static const _parallel = 2;

  /// With nothing to show after this long, the server is probably waking.
  static const _slowAfter = Duration(seconds: 6);

  /// Most people here live in Korea and send home: that until they swap.
  static ParcelDirection rememberedDirection(KeyValueStore store) =>
      store.read(_directionKey) == '0' ? ParcelDirection.uzbToKor : ParcelDirection.korToUzb;

  final ParcelSource _source;
  final KeyValueStore _store;
  final ParcelCache _cache;
  final DateTime Function() _clock;

  /// Kept on this phone.
  final SavedParcels saved;

  ParcelDirection direction;
  ParcelMode mode = ParcelMode.byDate;

  Fetch<List<ParcelDate>> dates = const Fetch.loading();

  /// Where the feed of days begins: the first day not yet past, until the
  /// user picks another in the strip.
  int first = 0;

  /// A refresh is under way while older posts show.
  bool updating = false;

  /// Nothing to show yet after a few seconds.
  bool slow = false;

  /// The last refresh failed; what shows was loaded earlier.
  bool offline = false;

  /// Cities of the departure country first, as the web page does.
  late ParcelCountry country;

  /// Null until the cities are first wanted.
  Fetch<List<ParcelCity>>? cities;

  final _days = <String, Fetch<List<ParcelPost>>>{};

  /// Which refresh of the days each day's posts were loaded in: older ones
  /// show until they are loaded again.
  final _dayRound = <String, int>{};
  int _round = 0;
  final _running = <String>{};
  final _queue = <String>[];

  /// The days most recently on screen: a refresh reloads these.
  final _wanted = <String>{};
  String? _picked;
  DateTime? _loadedAt;
  Timer? _slowTimer;
  ParcelCountry? _citiesFor;

  /// Bumped when the direction changes: answers to older requests are
  /// dropped.
  int _generation = 0;
  bool _disposed = false;

  List<ParcelDate> get feed {
    final list = dates.data;
    return list == null ? const [] : list.sublist(first.clamp(0, list.length));
  }

  Fetch<List<ParcelPost>> day(String key) => _days[key] ?? const Fetch.loading();

  /// When the lists on screen were loaded.
  DateTime? get loadedAt => _loadedAt;

  bool isPast(ParcelDate date) {
    final now = _clock();
    return date.date.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get noticeSeen => _store.read(_noticeKey) != null;

  Future<void> acknowledgeNotice() async {
    await _store.write(_noticeKey, '1');
    _notify();
  }

  Future<void> start() async {
    _fromCache();
    _notify();
    await _loadDates();
  }

  @override
  void dispose() {
    _disposed = true;
    _slowTimer?.cancel();
    _cache.flush();
    saved.dispose();
    super.dispose();
  }

  Future<void> swap() async {
    direction = direction.other;
    country = direction.from;
    unawaited(_store.write(_directionKey, '${direction.api}'));
    _generation++;
    _days.clear();
    _dayRound.clear();
    _running.clear();
    _queue.clear();
    _wanted.clear();
    _picked = null;
    dates = const Fetch.loading();
    first = 0;
    updating = false;
    offline = false;
    cities = null;
    _citiesFor = null;
    _fromCache();
    _notify();
    await Future.wait([_loadDates(), if (mode == ParcelMode.byCity) _loadCities()]);
  }

  void setMode(ParcelMode value) {
    if (mode == value) return;
    mode = value;
    _notify();
    if (value == ParcelMode.byCity && (cities == null || cities!.failed)) unawaited(_loadCities());
  }

  /// The feed starts from [date].
  void pick(ParcelDate date) {
    final at = dates.data?.indexWhere((d) => d.key == date.key) ?? -1;
    if (at < 0) return;
    _picked = date.key;
    first = at;
    _notify();
  }

  /// A day's section is near the screen: its posts are wanted.
  void want(String key) {
    _wanted
      ..remove(key)
      ..add(key);
    while (_wanted.length > 6) {
      _wanted.remove(_wanted.first);
    }
    final shown = _days[key];
    // A failed day waits for "Try again" rather than retrying on every
    // scroll.
    if (shown != null && shown.failed) return;
    if (_dayRound[key] == _round || _running.contains(key) || _queue.contains(key)) return;
    _queue.add(key);
    _pump();
  }

  /// Every day in the feed: for searching them all.
  void wantAll() {
    for (final d in feed) {
      final shown = _days[d.key];
      if (shown != null && shown.failed) continue;
      if (_dayRound[d.key] == _round || _running.contains(d.key) || _queue.contains(d.key)) continue;
      _queue.add(d.key);
    }
    _pump();
  }

  void retryDay(String key) {
    _days.remove(key);
    _dayRound.remove(key);
    _notify();
    want(key);
  }

  Future<void> setCountry(ParcelCountry value) async {
    if (country == value && cities?.data != null) return;
    country = value;
    await _loadCities();
  }

  /// Pull to refresh, or "try again". False when it failed; whatever was
  /// shown stays.
  Future<bool> refresh() => mode == ParcelMode.byDate ? _loadDates() : _loadCities();

  /// Back from elsewhere: lists older than ten minutes are refreshed.
  void refreshIfOld() {
    final at = _loadedAt;
    if (at != null && _clock().difference(at) > const Duration(minutes: 10)) unawaited(refresh());
  }

  /// A city's posts saved from last time, for its page to show at once.
  List<ParcelPost>? savedCityPosts(String city, ParcelCountry country, ParcelDirection direction) =>
      _cache.cityPosts(direction, country, city);

  Future<List<ParcelPost>> postsByCity(String city, ParcelCountry country, ParcelDirection direction) async {
    final list = await _source.postsByCity(city, country, direction);
    _cache.putCityPosts(direction, country, city, list);
    return list;
  }

  void _fromCache() {
    final cached = _cache.dates(direction);
    if (cached == null) return;
    dates = Fetch.done(cached);
    first = _firstUpcoming(cached);
    for (final d in cached) {
      final posts = _cache.posts(direction, d.key);
      if (posts != null) _days[d.key] = Fetch.done(posts);
    }
    _loadedAt = _cache.loadedAt(direction);
  }

  int _firstUpcoming(List<ParcelDate> list) {
    final at = list.indexWhere((d) => !isPast(d));
    return at < 0 ? 0 : at;
  }

  Future<bool> _loadDates() async {
    final generation = _generation;
    _round++;
    final shown = dates.data != null;
    if (shown) {
      updating = true;
    } else {
      dates = const Fetch.loading();
      _slowSoon();
    }
    _notify();
    var ok = true;
    try {
      final list = await _source.dates(direction);
      if (generation != _generation) return true;
      _cache.putDates(direction, list);
      dates = Fetch.done(list);
      final picked = _picked == null ? -1 : list.indexWhere((d) => d.key == _picked);
      first = picked >= 0 ? picked : _firstUpcoming(list);
      _days.removeWhere((key, _) => !list.any((d) => d.key == key));
      _loadedAt = _clock();
      offline = false;
    } catch (_) {
      if (generation != _generation) return true;
      ok = false;
      if (shown) {
        offline = true;
      } else {
        dates = const Fetch.failed();
      }
    }
    if (generation != _generation) return true;
    updating = false;
    _calm();
    _notify();
    // The days on screen: their posts again too. Days asked for while the
    // list was loading wait in the queue: on their way now.
    for (final key in _wanted.toList()) {
      want(key);
    }
    _pump();
    return ok;
  }

  void _pump() {
    while (_running.length < _parallel && _queue.isNotEmpty && dates.data != null) {
      final key = _queue.removeAt(0);
      _running.add(key);
      unawaited(_loadDay(key));
    }
  }

  Future<void> _loadDay(String key) async {
    final generation = _generation;
    final round = _round;
    if (_days[key]?.data == null) {
      _days[key] = const Fetch.loading();
      _notify();
    }
    try {
      final list = await _source.postsByDate(key, direction);
      if (generation != _generation) return;
      _days[key] = Fetch.done(list);
      _dayRound[key] = round;
      _cache.putPosts(direction, key, list);
    } catch (_) {
      if (generation != _generation) return;
      if (_days[key]?.data == null) {
        _days[key] = const Fetch.failed();
      } else {
        offline = true;
      }
    }
    _running.remove(key);
    _notify();
    _pump();
  }

  Future<bool> _loadCities() async {
    final generation = _generation;
    final wanted = country;
    // Another country: its saved list, or placeholders, in place of the
    // last one's.
    if (_citiesFor != wanted || cities?.data == null) {
      final cached = _cache.cities(direction, wanted);
      cities = cached == null ? const Fetch.loading() : Fetch.done(cached);
      _citiesFor = wanted;
    }
    final shown = cities!.data != null;
    if (shown) {
      updating = true;
    } else {
      _slowSoon();
    }
    _notify();
    bool current() => generation == _generation && country == wanted;
    var ok = true;
    try {
      final list = await _source.cities(wanted, direction);
      if (!current()) return true;
      cities = Fetch.done(list);
      _cache.putCities(direction, wanted, list);
      offline = false;
    } catch (_) {
      if (!current()) return true;
      ok = false;
      if (shown) {
        offline = true;
      } else {
        cities = const Fetch.failed();
      }
    }
    updating = false;
    _calm();
    _notify();
    return ok;
  }

  void _slowSoon() {
    _slowTimer?.cancel();
    _slowTimer = Timer(_slowAfter, () {
      slow = true;
      _notify();
    });
  }

  void _calm() {
    _slowTimer?.cancel();
    slow = false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

/// On app start, for someone who has opened the parcel page before and not
/// lately: the days and the first coming day's posts are fetched in the
/// background. The page then opens with fresh lists, and a sleeping server
/// is woken before it is needed.
Future<void> warmParcels(ParcelSource source, KeyValueStore store) async {
  final cache = ParcelCache(store);
  final direction = ParcelController.rememberedDirection(store);
  final at = cache.loadedAt(direction);
  if (at == null || DateTime.now().difference(at) < const Duration(minutes: 30)) return;
  try {
    final dates = await source.dates(direction);
    cache.putDates(direction, dates);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = dates.where((d) => !d.date.isBefore(today)).firstOrNull;
    if (next != null) cache.putPosts(direction, next.key, await source.postsByDate(next.key, direction));
  } catch (_) {
    // Next time.
  } finally {
    cache.flush();
  }
}
