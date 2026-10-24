import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_language.dart';
import '../../core/config.dart';
import '../../core/key_value_store.dart';
import '../prayer/prayer_models.dart';
import 'links_data.dart';

enum LinkKind { job, life, group }

enum LinksTab { jobs, life, groups }

/// Job groups nearest the user first, or by part of Korea.
enum JobOrder { nearest, regions }

/// A Telegram group, channel or bot from the page.
class UsefulLink {
  UsefulLink({
    required this.name,
    required this.url,
    required this.kind,
    this.cities = const [],
    this.placed = false,
    this.life,
    this.group,
  });

  /// As on the web page.
  final String name;
  final String url;
  final LinkKind kind;

  /// A job group's cities: none when it covers all of Korea, or when the
  /// app doesn't know it yet ([placed] false).
  final List<LinkCity> cities;
  final bool placed;
  final LifeInfo? life;
  final GroupFor? group;

  /// "@Ansanish" from https://t.me/Ansanish; invite links have none.
  String? get handle {
    final path = Uri.tryParse(url)?.pathSegments.firstOrNull ?? '';
    return path.isEmpty || path.startsWith('+') ? null : '@$path';
  }

  bool get isBot => handle?.toLowerCase().endsWith('bot') ?? false;

  LinkRegion get region => kind != LinkKind.job || !placed
      ? LinkRegion.other
      : cities.isEmpty
          ? LinkRegion.nationwide
          : cities.first.region;

  /// The name in the app's language: the web page's own for job groups,
  /// translated for "Korea life".
  String title(AppLanguage language) => switch ((life, language)) {
        (final LifeInfo info, AppLanguage.ru) => info.ru,
        (final LifeInfo info, AppLanguage.en) => info.en,
        _ => name,
      };

  /// Everything a search may match: names in every language, the handle,
  /// and every spelling of the cities.
  late final String _haystack = normalizeQuery([
    name,
    handle ?? '',
    if (life != null) ...[life!.ru, life!.en],
    for (final c in cities) ...[c.name, c.hangul, ...c.spellings],
  ].join(' '));

  /// Every word of [query] is somewhere in the link.
  bool matches(String query) => normalizeQuery(query).split(' ').every(_haystack.contains);
}

/// Lower case, apostrophes and Uzbek letter marks dropped ("e'lon", "e’lon"
/// and "elon" all match), spaces collapsed.
String normalizeQuery(String text) =>
    text.toLowerCase().replaceAll(RegExp('[\'‘’ʻʼ`´]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Gets the web page's current script (pages/links/links.js); null when it
/// can't.
typedef LinksScriptSource = Future<String?> Function();

Future<String?> fetchLinksScript() async {
  try {
    final response =
        await http.get(AppConfig.webBase.resolve('pages/links/links.js')).timeout(const Duration(seconds: 15));
    return response.statusCode == 200 ? utf8.decode(response.bodyBytes) : null;
  } catch (_) {
    return null;
  }
}

/// The two lists in the web page's script, as (name, url): only Telegram
/// links are taken. Null when the script doesn't have them.
({List<(String, String)> jobs, List<(String, String)> life})? parseLinksScript(String script) {
  List<(String, String)>? list(String name) {
    final start = script.indexOf(RegExp('(const|let|var)\\s+$name\\s*=\\s*\\['));
    if (start < 0) return null;
    final end = script.indexOf('];', start);
    if (end < 0) return null;
    final item = RegExp(r'''\{\s*name:\s*(["'])((?:\\.|(?!\1).)*)\1\s*,\s*url:\s*["'](https://t\.me/[^"']+)["']\s*,?\s*\}''');
    return [
      for (final m in item.allMatches(script.substring(start, end)))
        (m.group(2)!.replaceAllMapped(RegExp(r'\\(.)'), (e) => e.group(1)!), m.group(3)!),
    ];
  }

  final jobs = list('arbaytLinks');
  final life = list('koreaLifeLinks');
  if (jobs == null || life == null || jobs.isEmpty || life.isEmpty) return null;
  return (jobs: jobs, life: life);
}

/// The useful links page: the lists (the web page's, kept up to date),
/// favourites, and where the user is for the nearest job groups.
class LinksController extends ChangeNotifier {
  LinksController({required this._store, required this._script, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _favorites.addAll(_readList(_favoritesKey));
    final view = _store.read(_viewKey)?.split('|');
    tab = LinksTab.values.where((t) => t.name == view?.first).firstOrNull ?? LinksTab.jobs;
    order = view != null && view.length > 1 && view[1] == JobOrder.regions.name ? JobOrder.regions : JobOrder.nearest;
    _apply(_cachedLists() ?? (jobs: bundledJobs, life: bundledLife));
  }

  static const _remoteKey = 'links_remote';
  static const _favoritesKey = 'links_favorites';
  static const _viewKey = 'links_view';

  final KeyValueStore _store;
  final LinksScriptSource _script;
  final DateTime Function() _clock;

  List<UsefulLink> jobs = const [];
  List<UsefulLink> life = const [];
  late final List<UsefulLink> groups = [
    for (final (name, url, kind) in communityGroups) UsefulLink(name: name, url: url, kind: LinkKind.group, group: kind),
  ];
  late LinksTab tab;
  late JobOrder order;
  final _favorites = <String>[];

  List<UsefulLink> get all => [...jobs, ...life, ...groups];

  /// Favourites, in the order they were added.
  List<UsefulLink> get favorites => [
        for (final url in _favorites) ?all.where((l) => l.url == url).firstOrNull,
      ];

  bool isFavorite(UsefulLink link) => _favorites.contains(link.url);

  /// The web page's lists are fetched at most once a day; until then, and
  /// whenever that fails, the last ones (or the app's own) stay.
  Future<void> start() async {
    final raw = _store.read(_remoteKey);
    final at = raw == null ? null : (jsonDecode(raw) as Map)['at'] as int?;
    if (at != null && _clock().difference(DateTime.fromMillisecondsSinceEpoch(at)) < const Duration(days: 1)) return;
    final script = await _script();
    final lists = script == null ? null : parseLinksScript(script);
    if (lists == null) return;
    await _store.write(
      _remoteKey,
      jsonEncode({
        'at': _clock().millisecondsSinceEpoch,
        'jobs': [for (final (n, u) in lists.jobs) [n, u]],
        'life': [for (final (n, u) in lists.life) [n, u]],
      }),
    );
    _apply(lists);
    notifyListeners();
  }

  void setTab(LinksTab value) {
    tab = value;
    _saveView();
    notifyListeners();
  }

  void setOrder(JobOrder value) {
    order = value;
    _saveView();
    notifyListeners();
  }

  Future<void> toggleFavorite(UsefulLink link) async {
    if (!_favorites.remove(link.url)) _favorites.add(link.url);
    notifyListeners();
    await _store.write(_favoritesKey, jsonEncode(_favorites));
  }

  /// Every link matching [query], in page order.
  List<UsefulLink> search(String query) => normalizeQuery(query).isEmpty ? const [] : all.where((l) => l.matches(query)).toList();

  /// Whether [place] is in Korea: elsewhere distances to Korean cities mean
  /// nothing.
  static bool inKorea(SavedLocation? place) =>
      place != null && place.lat > 33 && place.lat < 38.7 && place.lon > 124.5 && place.lon < 131;

  /// Kilometres from [place] to the nearest of the group's cities.
  static double? distanceKm(UsefulLink link, SavedLocation? place) {
    if (!inKorea(place) || link.cities.isEmpty) return null;
    return link.cities.map((c) => _haversine(place!.lat, place.lon, c.lat, c.lon)).reduce(math.min);
  }

  /// The group's city nearest to [place], else its first.
  static LinkCity? nearestCity(UsefulLink link, SavedLocation? place) {
    if (link.cities.isEmpty) return null;
    if (!inKorea(place)) return link.cities.first;
    return link.cities.reduce((a, b) =>
        _haversine(place!.lat, place.lon, a.lat, a.lon) <= _haversine(place.lat, place.lon, b.lat, b.lon) ? a : b);
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  void _apply(({List<(String, String)> jobs, List<(String, String)> life}) lists) {
    jobs = [
      for (final (name, url) in lists.jobs)
        UsefulLink(
          name: name,
          url: url,
          kind: LinkKind.job,
          placed: jobCities.containsKey(url),
          cities: [for (final key in jobCities[url] ?? const <String>[]) ?linkCities[key]],
        ),
    ];
    life = [
      for (final (name, url) in lists.life) UsefulLink(name: name, url: url, kind: LinkKind.life, life: lifeInfo[url]),
    ];
  }

  ({List<(String, String)> jobs, List<(String, String)> life})? _cachedLists() {
    try {
      final raw = _store.read(_remoteKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      List<(String, String)> list(String key) => [
            for (final item in (json[key] as List).cast<List>()) ('${item[0]}', '${item[1]}'),
          ];
      return (jobs: list('jobs'), life: list('life'));
    } catch (_) {
      return null;
    }
  }

  List<String> _readList(String key) {
    try {
      final raw = _store.read(key);
      return raw == null ? const [] : (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  void _saveView() => _store.write(_viewKey, '${tab.name}|${order.name}');
}
