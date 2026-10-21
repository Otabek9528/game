import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/key_value_store.dart';
import 'parcel_models.dart';

/// A post the user kept, with the way it goes.
class SavedPost {
  const SavedPost({required this.post, required this.direction, required this.savedAt});

  final ParcelPost post;
  final ParcelDirection direction;
  final DateTime savedAt;
}

/// Posts saved on this phone, newest first.
class SavedParcels extends ChangeNotifier {
  SavedParcels(this._store) {
    try {
      final raw = _store.read(key);
      if (raw == null) return;
      for (final item in (jsonDecode(raw) as List).whereType<Map>()) {
        final json = item.cast<String, dynamic>();
        final d = json['direction'];
        _items.add(SavedPost(
          post: ParcelPost.fromJson((json['post'] as Map).cast<String, dynamic>()),
          direction: d == 0 ? ParcelDirection.uzbToKor : ParcelDirection.korToUzb,
          savedAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
        ));
      }
    } catch (_) {
      _items.clear();
    }
  }

  static const key = 'parcel_saved';

  final KeyValueStore _store;
  final _items = <SavedPost>[];

  List<SavedPost> get items => List.unmodifiable(_items);

  bool contains(ParcelPost post) => _items.any((s) => s.post.id == post.id);

  Future<void> save(ParcelPost post, ParcelDirection direction) async {
    if (contains(post)) return;
    _items.insert(0, SavedPost(post: post, direction: direction, savedAt: DateTime.now()));
    notifyListeners();
    await _write();
  }

  /// Back where it was: for "Undo".
  Future<void> restore(SavedPost item, int at) async {
    if (contains(item.post)) return;
    _items.insert(at.clamp(0, _items.length), item);
    notifyListeners();
    await _write();
  }

  /// Returns where it was, for [restore]; −1 when it wasn't saved.
  Future<int> remove(ParcelPost post) async {
    final at = _items.indexWhere((s) => s.post.id == post.id);
    if (at < 0) return -1;
    _items.removeAt(at);
    notifyListeners();
    await _write();
    return at;
  }

  Future<void> _write() => _store.write(
        key,
        jsonEncode([
          for (final s in _items)
            {'post': s.post.toJson(), 'direction': s.direction.api, 'at': s.savedAt.millisecondsSinceEpoch},
        ]),
      );
}
