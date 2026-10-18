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
  static const keys = {'location', 'prayer_days', 'prayer_settings', 'permissions_asked', 'exact_alarms_asked', 'city_lookup', 'notifications_asked', 'reminders', 'theme_mode', 'parcel_direction', 'parcel_cache', 'parcel_saved', 'parcel_notice', 'links_remote', 'links_favorites', 'links_view', 'install_id', 'barcode_history', 'qna_saved', 'qna_recent', 'qna_daily', 'qna_text'};

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
