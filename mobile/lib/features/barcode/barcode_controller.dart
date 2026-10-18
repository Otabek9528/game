import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/activity_log.dart';
import '../../core/key_value_store.dart';
import 'barcode_models.dart';
import 'barcode_source.dart';

/// A code checked on this phone, and what the database said.
class ScanRecord {
  const ScanRecord({required this.code, required this.at, this.product});

  final String code;
  final DateTime at;

  /// Null: not in the database.
  final Product? product;
}

/// The last codes checked, newest first, kept on the phone: they open again
/// with a tap, and answer when there is no connection.
class ScanHistory extends ChangeNotifier {
  ScanHistory(this._store) {
    try {
      for (final json in jsonDecode(_store.read(_key) ?? '[]') as List) {
        final map = json as Map<String, dynamic>;
        final product = map['product'];
        _items.add(ScanRecord(
          code: map['code'] as String,
          at: DateTime.parse(map['at'] as String),
          product: product is Map<String, dynamic> ? Product.fromJson(product) : null,
        ));
      }
    } catch (_) {
      _items.clear();
    }
  }

  final KeyValueStore _store;
  final _items = <ScanRecord>[];

  static const _key = 'barcode_history';
  static const limit = 30;

  List<ScanRecord> get items => List.unmodifiable(_items);

  /// What the database last said about [code], if it knew it.
  Product? saved(String code) {
    for (final item in _items) {
      if (item.code == code) return item.product;
    }
    return null;
  }

  void add(String code, Product? product, DateTime at) {
    _items
      ..removeWhere((item) => item.code == code)
      ..insert(0, ScanRecord(code: code, at: at, product: product));
    if (_items.length > limit) _items.removeRange(limit, _items.length);
    _save();
  }

  void clear() {
    _items.clear();
    _save();
  }

  void _save() {
    notifyListeners();
    _store.write(
      _key,
      jsonEncode([
        for (final item in _items)
          {'code': item.code, 'at': item.at.toIso8601String(), 'product': item.product?.toJson()},
      ]),
    );
  }
}

/// Where a check stands.
sealed class Lookup {
  const Lookup(this.code);

  final String code;
}

class Checking extends Lookup {
  const Checking(super.code);
}

class Found extends Lookup {
  Found(this.product, {this.saved = false}) : super(product.barcode);

  final Product product;

  /// From the phone's history: the server couldn't be reached.
  final bool saved;
}

class NotFound extends Lookup {
  const NotFound(super.code);
}

class Offline extends Lookup {
  const Offline(super.code);
}

/// Checks codes against the database, one at a time: a new check replaces
/// the one before.
class BarcodeController extends ChangeNotifier {
  BarcodeController({
    required this.source,
    required this.history,
    required this.activity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final BarcodeSource source;
  final ScanHistory history;
  final ActivityLog activity;
  final DateTime Function() _clock;

  Lookup? _lookup;
  int _round = 0;

  Lookup? get lookup => _lookup;

  /// [scanned]: read by the camera or typed, counted on the server as the
  /// web page counts its scans. Opening one again from the history is not.
  Future<void> check(String code, {bool scanned = true}) async {
    final round = ++_round;
    _lookup = Checking(code);
    notifyListeners();
    Lookup result;
    try {
      final product = await source.product(code);
      if (round != _round) return;
      if (scanned) activity.log(product == null ? 'scanner_not_found' : 'scanner_found', code);
      history.add(code, product, _clock());
      result = product == null ? NotFound(code) : Found(product);
    } on BarcodeException {
      if (round != _round) return;
      final saved = history.saved(code);
      result = saved == null ? Offline(code) : Found(saved, saved: true);
    }
    _lookup = result;
    notifyListeners();
  }

  void clear() {
    _round++;
    _lookup = null;
    notifyListeners();
  }
}
