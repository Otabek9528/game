import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/activity_log.dart';
import '../../core/app_language.dart';
import '../../core/key_value_store.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import '../prayer/prayer_controller.dart';
import '../prayer/prayer_models.dart';

/// Talks to the home-screen widgets (android/…/widget/, ios/PrayerWidget).
///
/// The widgets can't run Dart, so the app hands them everything already
/// worked out and in the user's language: a week of prayer times, labels and
/// date lines. With that they count down and roll over to new days on their
/// own, even when the app hasn't been opened for days.
class HomeWidgetBridge {
  HomeWidgetBridge([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('vegukin/widget');

  final MethodChannel _channel;

  /// Told when there is a launch action to take, the app already running:
  /// on iOS, a reminder or the widget tapped after the app last looked (see
  /// [takeLaunchAction]).
  set onLaunchAction(VoidCallback? listener) => _channel.setMethodCallHandler(
        listener == null
            ? null
            : (call) async {
                if (call.method == 'launchAction') listener();
              },
      );
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

  /// Lets the widgets be counted, as the app's pages are ([ActivityLog]).
  ///
  /// Android's count themselves (WidgetLog.kt): once a day while one is on a
  /// home screen, when the first is placed and when the last is removed,
  /// even if the app isn't opened. They're told here where to send and as
  /// whom. iPhone widgets can't send anything: the app reports the ones
  /// placed, once a day, when it is opened.
  Future<void> track(ActivityLog activity, KeyValueStore store, DateTime now) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final today = DateFormat('yyyy-MM-dd').format(now);
        if (store.read(_countedKey) == today) return;
        for (final kind in await placed()) {
          activity.log('widget_$kind');
        }
        await store.write(_countedKey, today);
      } else {
        await _channel.invokeMethod<void>('track', {'url': '${HttpActivityLog.endpoint}', ...activity.who});
      }
    } on MissingPluginException {
      // Tests.
    } on PlatformException catch (e) {
      debugPrint('Widget tracking failed: $e');
    }
  }

  static const _countedKey = 'widget_counted';

  /// The widget sizes on this phone's home (and lock) screens: Android
  /// `large`, `small`; iPhone `small`, `medium`, `large`, `lock`.
  Future<List<String>> placed() async {
    try {
      return await _channel.invokeListMethod<String>('placed') ?? const [];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  /// How the app can help put a widget on the home screen: `pin` (Android
  /// adds it, see [pin]), `guide` (iPhone: show how), or null (it can't:
  /// an old launcher, or no widget in this build).
  Future<String?> offer() async {
    try {
      return await _channel.invokeMethod<String>('offer');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Asks the launcher to add the [size] (`large` or `small`) widget: it
  /// shows its own confirmation with a preview. False when it couldn't.
  Future<bool> pin(String size) async {
    try {
      return await _channel.invokeMethod<bool>('pin', size) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// What the user tapped on a widget to open the app, once:
  /// `refresh_location` (the city), `widget` (the rest of it; on iPhone
  /// `widget_prayers`, which opens the prayers page), `open_prayers` (a
  /// reminder) or null.
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
    'brand': 'Muslim Vegukin',
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
