import 'package:shared_preferences/shared_preferences.dart';

/// Small values kept on the phone between launches.
abstract interface class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// [KeyValueStore] backed by shared_preferences.
class PrefsKeyValueStore implements KeyValueStore {
  PrefsKeyValueStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// Every key the app stores must be listed here.
  static const keys = {'location', 'prayer_days', 'prayer_settings', 'permissions_asked', 'exact_alarms_asked'};

  static Future<PrefsKeyValueStore> open() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
    );
    return PrefsKeyValueStore._(prefs);
  }

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}
