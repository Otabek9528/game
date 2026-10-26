import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/home/feature_catalog.dart';
import 'config.dart';
import 'key_value_store.dart';

/// Gets the live web app's home page (index.html); null when it can't.
typedef HomePageSource = Future<String?> Function();

Future<String?> fetchHomePage() async {
  try {
    final response = await http
        .get(AppConfig.liveWebBase.resolve('index.html'))
        .timeout(const Duration(seconds: 15));
    return response.statusCode == 200 ? utf8.decode(response.bodyBytes) : null;
  } catch (_) {
    return null;
  }
}

/// Which sections the web app's home page marks "NEW": the `FEATURE_CARDS`
/// entries with `isNew: true` (one entry per line, `//` lines left out), and
/// `business` while the band's `biz-band-badge` is in the markup. Null when
/// the page doesn't have the table.
Set<String>? parseNewBadges(String page) {
  final start = page.indexOf('FEATURE_CARDS');
  final end = start < 0 ? -1 : page.indexOf('};', start);
  if (end < 0) return null;
  final entry = RegExp(r'^\s*(\w+)\s*:\s*\{');
  final marked = RegExp(r'isNew\s*:\s*true');
  final ids = <String>{};
  var entries = 0;
  for (final line in page.substring(start, end).split('\n')) {
    final match = entry.firstMatch(line);
    if (match == null) continue;
    entries++;
    if (marked.hasMatch(line.split('//').first)) ids.add(match.group(1)!);
  }
  if (entries == 0) return null;
  final markup = page.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  if (RegExp(r'class="[^"]*\bbiz-band-badge\b').hasMatch(markup)) {
    ids.add(businessFeature.id);
  }
  return ids;
}

/// The "NEW" marks on the home screen, as the web app shows them: the line
/// that adds or removes one there does it here too, without an app update.
/// Kept on the phone; the app's own marks until the page is first read.
class NewBadges extends ChangeNotifier {
  NewBadges(this._store, this._page) {
    final saved = _store.read(_key);
    if (saved != null) {
      _ids = {...saved.split(',').where((id) => id.isNotEmpty)};
    }
  }

  final KeyValueStore _store;
  final HomePageSource _page;
  static const _key = 'new_badges';

  Set<String>? _ids;

  bool isNew(Feature feature) => _ids?.contains(feature.id) ?? feature.isNew;

  Future<void> refresh() async {
    final page = await _page();
    final ids = page == null ? null : parseNewBadges(page);
    if (ids == null || setEquals(ids, _ids)) return;
    _ids = ids;
    notifyListeners();
    await _store.write(_key, ids.join(','));
  }
}
