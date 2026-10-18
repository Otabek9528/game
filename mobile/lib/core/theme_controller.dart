import 'package:flutter/material.dart';

import 'key_value_store.dart';

/// Day or night. Follows the phone until the user picks one with the home
/// screen's sun/moon button; the choice is kept, and the web pages get it
/// too (they read the app's theme when they open).
class ThemeController extends ChangeNotifier {
  ThemeController(this._store)
      : _mode = switch (_store.read(_key)) {
          'day' => ThemeMode.light,
          'night' => ThemeMode.dark,
          _ => ThemeMode.system,
        };

  static const _key = 'theme_mode';

  final KeyValueStore _store;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Switches to the other of day and night from what is [showing] now.
  Future<void> toggle(Brightness showing) async {
    _mode = showing == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _store.write(_key, _mode == ThemeMode.dark ? 'night' : 'day');
  }
}
