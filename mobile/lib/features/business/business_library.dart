import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/key_value_store.dart';
import 'business_models.dart';

/// What the directory keeps on the phone: the businesses saved for a call
/// one tap away (with their contacts, so they work without a connection),
/// and the last directory, so the page opens at once.
class BusinessLibrary extends ChangeNotifier {
  BusinessLibrary(this._store) {
    try {
      for (final b in jsonDecode(_store.read(_savedKey) ?? '[]') as List) {
        if (Business.fromJson(b) case final business?) _saved.add(business);
      }
    } catch (_) {
      _saved.clear();
    }
  }

  final KeyValueStore _store;
  final _saved = <Business>[];

  static const _savedKey = 'business_saved';
  static const _directoryKey = 'business_directory';
  static const maxSaved = 50;

  /// Newest first.
  List<Business> get saved => List.unmodifiable(_saved);

  bool isSaved(String id) => _saved.any((b) => b.id == id);

  /// Saves [business], or takes it out. Returns whether it is saved now.
  bool toggleSave(Business business) {
    final was = isSaved(business.id);
    _saved.removeWhere((b) => b.id == business.id);
    if (!was) {
      _saved.insert(0, business);
      if (_saved.length > maxSaved) _saved.removeRange(maxSaved, _saved.length);
    }
    _writeSaved();
    return !was;
  }

  /// A saved business opened again: kept up to date.
  void refresh(Business business) {
    final i = _saved.indexWhere((b) => b.id == business.id);
    if (i == -1) return;
    _saved[i] = business;
    _writeSaved();
  }

  void _writeSaved() {
    _store.write(_savedKey, jsonEncode([for (final b in _saved) b.toJson()]));
    notifyListeners();
  }

  BizDirectory? get directory {
    try {
      final json = jsonDecode(_store.read(_directoryKey) ?? 'null');
      if (json is! Map<String, dynamic>) return null;
      return BizDirectory(
        categories: [for (final c in (json['categories'] as List?) ?? const []) ?BizCategory.fromJson(c)]
          ..sort(byCategoryOrder),
        listingFee: (json['listingFee'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  set directory(BizDirectory? value) {
    if (value == null) return;
    _store.write(
      _directoryKey,
      jsonEncode({'categories': [for (final c in value.categories) c.toJson()], 'listingFee': value.listingFee}),
    );
  }
}
