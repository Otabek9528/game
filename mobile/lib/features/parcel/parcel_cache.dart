import 'dart:async';
import 'dart:convert';

import '../../core/key_value_store.dart';
import 'parcel_models.dart';

/// What the parcel page last loaded, kept on the phone: the page opens with
/// it at once and refreshes behind it, and on a dead connection it still
/// has something to show.
class ParcelCache {
  ParcelCache(this._store) {
    try {
      final raw = _store.read(key);
      if (raw != null) _data = (jsonDecode(raw) as Map<String, dynamic>).cast<String, dynamic>();
    } catch (_) {
      _data = {};
    }
  }

  static const key = 'parcel_cache';

  /// Days' posts kept: the most recently loaded.
  static const _maxPostLists = 40;

  final KeyValueStore _store;
  Map<String, dynamic> _data = {};
  Timer? _save;

  /// When anything was last loaded for [direction]; null when never.
  DateTime? loadedAt(ParcelDirection direction) => _at(_section('dates')['${direction.api}']);

  List<ParcelDate>? dates(ParcelDirection direction) =>
      _items(_section('dates')['${direction.api}'], ParcelDate.fromJson);

  void putDates(ParcelDirection direction, List<ParcelDate> dates) =>
      _put('dates', '${direction.api}', [for (final d in dates) d.toJson()]);

  List<ParcelPost>? posts(ParcelDirection direction, String date) =>
      _items(_section('posts')['${direction.api}|$date'], ParcelPost.fromJson);

  void putPosts(ParcelDirection direction, String date, List<ParcelPost> posts) =>
      _put('posts', '${direction.api}|$date', [for (final p in posts) p.toJson()]);

  List<ParcelCity>? cities(ParcelDirection direction, ParcelCountry country) =>
      _items(_section('cities')['${direction.api}|${country.api}'], ParcelCity.fromJson);

  void putCities(ParcelDirection direction, ParcelCountry country, List<ParcelCity> cities) =>
      _put('cities', '${direction.api}|${country.api}', [for (final c in cities) c.toJson()]);

  List<ParcelPost>? cityPosts(ParcelDirection direction, ParcelCountry country, String city) =>
      _items(_section('city_posts')['${direction.api}|${country.api}|$city'], ParcelPost.fromJson);

  void putCityPosts(ParcelDirection direction, ParcelCountry country, String city, List<ParcelPost> posts) =>
      _put('city_posts', '${direction.api}|${country.api}|$city', [for (final p in posts) p.toJson()]);

  /// Writes what is pending now (leaving the page).
  void flush() {
    if (_save?.isActive ?? false) {
      _save!.cancel();
      _write();
    }
  }

  Map<String, dynamic> _section(String name) => (_data[name] as Map?)?.cast<String, dynamic>() ?? {};

  DateTime? _at(Object? entry) {
    final ms = entry is Map ? entry['at'] : null;
    return ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  List<T>? _items<T>(Object? entry, T? Function(Map<String, dynamic>) parse) {
    final items = entry is Map ? entry['items'] : null;
    if (items is! List) return null;
    return [
      for (final item in items.whereType<Map>()) ?parse(item.cast<String, dynamic>()),
    ];
  }

  void _put(String name, String key, List<Map<String, dynamic>> items) {
    final section = _section(name);
    section[key] = {'at': DateTime.now().millisecondsSinceEpoch, 'items': items};
    if (section.length > _maxPostLists) {
      final oldest = section.keys.toList()
        ..sort((a, b) => ((section[a] as Map)['at'] as int).compareTo((section[b] as Map)['at'] as int));
      for (final k in oldest.take(section.length - _maxPostLists)) {
        section.remove(k);
      }
    }
    _data[name] = section;
    // Several lists arrive together: one write for them all.
    _save?.cancel();
    _save = Timer(const Duration(seconds: 1), _write);
  }

  void _write() => _store.write(key, jsonEncode(_data));
}
