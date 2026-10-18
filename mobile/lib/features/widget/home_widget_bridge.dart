import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_language.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import '../prayer/prayer_controller.dart';
import '../prayer/prayer_models.dart';

/// Talks to the Android home-screen widgets (android/…/widget/).
///
/// The widgets can't run Dart, so the app hands them everything already
/// worked out and in the user's language: a week of prayer times, labels and
/// date lines. With that they count down and roll over to new days on their
/// own, even when the app hasn't been opened for days.
class HomeWidgetBridge {
  HomeWidgetBridge([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('vegukin/widget');

  final MethodChannel _channel;
  String? _lastSent;

  /// Sends the current data to the widgets if it changed since last time.
  Future<void> publish(PrayerController prayer, AppLanguage language) async {
    final json = jsonEncode(widgetPayload(prayer, language));
    if (json == _lastSent) return;
    _lastSent = json;
    try {
      await _channel.invokeMethod<void>('update', json);
    } on MissingPluginException {
      // Not on Android (tests, iOS for now).
    } on PlatformException catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  /// True when Android won't let the widgets switch to the next prayer on
  /// the dot: "Alarms & reminders" is off (Android 14+ starts with it off).
  Future<bool> exactAlarmsMissing() async {
    try {
      return await _channel.invokeMethod<bool>('exactAlarmsMissing') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// The system page where "Alarms & reminders" is allowed for this app.
  Future<void> openExactAlarmSettings() async {
    try {
      await _channel.invokeMethod<void>('openExactAlarmSettings');
    } on MissingPluginException {
      // Not on Android.
    } on PlatformException catch (e) {
      debugPrint('Opening alarm settings failed: $e');
    }
  }

  /// What the user tapped on a widget to open the app, once:
  /// `refresh_location` (the city) or null.
  Future<String?> takeLaunchAction() async {
    try {
      return await _channel.invokeMethod<String>('takeLaunchAction');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

/// The widgets' data. Times are milliseconds since the epoch; `until` holds
/// the countdown label for each possible next prayer, in [Prayer] order.
@visibleForTesting
Map<String, dynamic> widgetPayload(PrayerController prayer, AppLanguage language) {
  final s = lookupAppLocalizations(language.locale);
  final place = prayer.place;
  final days = prayer.days;
  final base = <String, dynamic>{
    'v': 1,
    'brand': 'Muslim Vegukin Bot',
    'message': s.widgetOpenApp,
  };
  if (place == null || days.isEmpty) return base;

  String upper(String text) => text.toUpperCase();
  final shortPattern = language == AppLanguage.uz ? 'd-MMM' : 'd MMM';
  return {
    ...base,
    'city': place.city ?? s.locationPlaceholder,
    'names': [for (final p in Prayer.values) prayerName(s, p)],
    'until': [for (final p in Prayer.values) upper(countdownLabel(s, p))],
    'days': [
      for (final day in days)
        {
          'date': DateFormat('yyyy-MM-dd').format(day.date),
          'line1': gregorianLine(day.date, language),
          'line2': hijriLine(day, language),
          'short': DateFormat(shortPattern, language.code).format(day.date),
          'times': [for (final p in Prayer.values) day.times[p]!.millisecondsSinceEpoch],
        },
    ],
  };
}
