import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/app_language.dart';
import '../../core/key_value_store.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/prayer_controller.dart';
import 'reminders.dart';

/// The user's reminder choices, and the hand-off to Android, which shows
/// them (android/…/reminders/PrayerReminders.kt) even when the app is closed.
class ReminderController extends ChangeNotifier {
  ReminderController(this._store, [MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('vegukin/reminders') {
    final saved = _store.read('reminders');
    if (saved != null) {
      try {
        settings = ReminderSettings.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  final KeyValueStore _store;
  final MethodChannel _channel;
  String? _lastSent;

  ReminderSettings settings = ReminderSettings.defaults;

  /// False when the phone blocks this app's notifications.
  bool notificationsAllowed = true;

  Future<void> set(ReminderSlot slot, Reminder reminder) async {
    if (settings[slot] == reminder) return;
    settings = settings.withReminder(slot, reminder);
    notifyListeners();
    await _store.write('reminders', jsonEncode(settings.toJson()));
  }

  /// Hands Android the week's reminders, in [language], if they changed.
  Future<void> publish(PrayerController prayer, AppLanguage language) async {
    final place = prayer.place;
    final s = lookupAppLocalizations(language.locale);
    final list = place == null
        ? const <ScheduledReminder>[]
        : reminderSchedule(
            days: prayer.days,
            settings: settings,
            s: s,
            city: place.city ?? s.locationPlaceholder,
            now: prayer.now,
          );
    final json = jsonEncode([for (final r in list) r.toJson()]);
    if (json == _lastSent) return;
    _lastSent = json;
    await _call('update', json);
  }

  /// Plays the chime or the vibration, so the choice can be tried.
  Future<void> preview(ReminderMode mode) => _call('preview', mode.name);

  /// Re-reads whether notifications are allowed (after the settings page).
  Future<void> checkNotifications() async {
    final allowed = await _call<bool>('notificationsAllowed') ?? true;
    if (allowed == notificationsAllowed) return;
    notificationsAllowed = allowed;
    notifyListeners();
  }

  Future<void> openNotificationSettings() => _call('openNotificationSettings');

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null; // Not on Android (tests, iOS for now).
    } on PlatformException catch (e) {
      debugPrint('Reminders: $method failed: $e');
      return null;
    }
  }
}
