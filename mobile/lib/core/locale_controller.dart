import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

/// Where the chosen language is kept between launches.
abstract interface class LanguageStore {
  String? read();
  Future<void> write(String code);
}

/// Saves the language on the device with shared_preferences.
class PrefsLanguageStore implements LanguageStore {
  PrefsLanguageStore._(this._prefs);

  static const _key = 'app_language';

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsLanguageStore> open() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_key},
      ),
    );
    return PrefsLanguageStore._(prefs);
  }

  @override
  String? read() => _prefs.getString(_key);

  @override
  Future<void> write(String code) => _prefs.setString(_key, code);
}

/// Holds the app's language and tells the app to redraw when it changes.
class LocaleController extends ChangeNotifier {
  LocaleController(this._store) : _language = AppLanguage.fromCode(_store.read());

  final LanguageStore _store;
  AppLanguage? _language;

  /// Null until the user has picked a language on the first launch.
  AppLanguage? get language => _language;

  bool get hasChosen => _language != null;

  Future<void> choose(AppLanguage language) async {
    _language = language;
    notifyListeners();
    await _store.write(language.code);
  }
}
