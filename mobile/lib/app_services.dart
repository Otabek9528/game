import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as ph;

import 'core/config.dart';
import 'core/key_value_store.dart';
import 'core/locale_controller.dart';
import 'features/home/feature_catalog.dart';
import 'features/prayer/prayer_controller.dart';
import 'features/qibla/qibla_sensors.dart';
import 'features/reminders/reminder_controller.dart';
import 'features/widget/home_widget_bridge.dart';

/// Opens a section: for now, its web page inside the app.
typedef FeatureOpener = void Function(
  BuildContext context,
  Feature feature,
  AppServices services,
);

/// Live numbers for the business directory band.
class BusinessStats {
  const BusinessStats({required this.businesses, required this.categories});

  final int businesses;
  final int categories;

  /// From the same endpoint the web home page uses. Null when unavailable;
  /// the band then shows its tagline instead.
  static Future<BusinessStats?> fetch() async {
    try {
      final response = await http
          .get(AppConfig.apiBase.resolve('api/business/categories'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final categories = (body['categories'] as List).cast<Map<String, dynamic>>();
      final total = categories.fold<int>(0, (n, c) => n + ((c['count'] as num?)?.toInt() ?? 0));
      if (total == 0) return null;
      return BusinessStats(businesses: total, categories: categories.length);
    } catch (_) {
      return null;
    }
  }
}

/// The app asks for its permissions once, on first launch, and never again
/// on its own. Afterwards only the user's own taps (e.g. the prayer card's
/// "use my location" button) can bring a permission dialog back.
abstract interface class PermissionsGate {
  /// Location, camera, then notifications — each only the first time.
  /// "Alarms & reminders" follows: see [shouldOfferExactAlarms].
  Future<void> askOnce();

  /// True once, at first launch, when "Alarms & reminders" is off; the caller
  /// explains it and opens its page. The widgets need it to switch on time.
  Future<bool> shouldOfferExactAlarms();

  Future<void> openExactAlarmSettings();

  /// Whether the camera may be used, without asking.
  Future<bool> cameraGranted();

  Future<void> openAppSettings();
}

class DevicePermissions implements PermissionsGate {
  DevicePermissions(this._store, this._prayer, this._widget);

  final KeyValueStore _store;
  final PrayerController _prayer;
  final HomeWidgetBridge _widget;

  @override
  Future<void> askOnce() async {
    if (_store.read('permissions_asked') == null) {
      await _store.write('permissions_asked', '1');
      await _prayer.locate(userAsked: true);
      try {
        await ph.Permission.camera.request();
      } catch (_) {}
    }
    // Prayer reminders came later: installs that answered the first two
    // are asked this one once too.
    if (_store.read('notifications_asked') == null) {
      await _store.write('notifications_asked', '1');
      try {
        await ph.Permission.notification.request();
      } catch (_) {}
    }
  }

  @override
  Future<bool> shouldOfferExactAlarms() async {
    if (_store.read('exact_alarms_asked') != null) return false;
    if (!await _widget.exactAlarmsMissing()) return false;
    await _store.write('exact_alarms_asked', '1');
    return true;
  }

  @override
  Future<void> openExactAlarmSettings() => _widget.openExactAlarmSettings();

  @override
  Future<bool> cameraGranted() async {
    try {
      return await ph.Permission.camera.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();
}

/// Everything the screens need, created once in main().
class AppServices {
  const AppServices({
    required this.locale,
    required this.prayer,
    required this.permissions,
    required this.openFeature,
    required this.homeWidget,
    required this.reminders,
    this.qiblaDevice = const AndroidQiblaDevice(),
    this.businessStats = BusinessStats.fetch,
  });

  final LocaleController locale;
  final PrayerController prayer;
  final PermissionsGate permissions;
  final FeatureOpener openFeature;
  final HomeWidgetBridge homeWidget;
  final ReminderController reminders;
  final QiblaDevice qiblaDevice;
  final Future<BusinessStats?> Function() businessStats;
}
