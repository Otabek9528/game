import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/app.dart';
import 'package:muslim_vegukin/app_services.dart';
import 'package:muslim_vegukin/core/key_value_store.dart';
import 'package:muslim_vegukin/core/locale_controller.dart';
import 'package:muslim_vegukin/features/home/feature_catalog.dart';
import 'package:muslim_vegukin/features/prayer/prayer_controller.dart';
import 'package:muslim_vegukin/features/prayer/prayer_models.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';
import 'package:muslim_vegukin/features/reminders/reminder_controller.dart';
import 'package:muslim_vegukin/features/widget/home_widget_bridge.dart';

class MemoryLanguageStore implements LanguageStore {
  MemoryLanguageStore([this.value]);

  String? value;

  @override
  String? read() => value;

  @override
  Future<void> write(String code) async => value = code;
}

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class FakeLocation implements LocationSource {
  FakeLocation({
    this.access = LocationAccess.granted,
    this.afterRequest = LocationAccess.granted,
    this.lat = 37.32,
    this.lon = 126.83,
    this.city = 'Ansan',
  });

  LocationAccess access;
  LocationAccess afterRequest;
  double lat;
  double lon;
  String? city;
  bool failFix = false;
  int requests = 0;
  int fixes = 0;
  int cityLookups = 0;

  @override
  Future<LocationAccess> check() async => access;

  @override
  Future<LocationAccess> request() async {
    requests++;
    return access = afterRequest;
  }

  @override
  Future<({double lat, double lon})> current() async {
    fixes++;
    if (failFix) throw Exception('no fix');
    return (lat: lat, lon: lon);
  }

  @override
  Future<String?> cityName(double lat, double lon) async {
    cityLookups++;
    return city;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

/// Returns the same clock times every day: 05:00, 06:30, 12:00, 15:30,
/// 18:00, 19:30.
class FakeTimes implements PrayerTimesSource {
  int calls = 0;
  bool fail = false;
  PrayerSettings? lastSettings;

  @override
  Future<List<PrayerDay>> fetchDays(
    DateTime from,
    int count,
    SavedLocation place,
    PrayerSettings settings,
  ) async {
    calls++;
    lastSettings = settings;
    if (fail) throw Exception('offline');
    return [
      for (var i = 0; i < count; i++)
        dayAt(
          DateTime(from.year, from.month, from.day + i),
          key: PrayerDay.keyFor(DateTime(from.year, from.month, from.day + i), settings, place),
        ),
    ];
  }
}

class FakePermissions implements PermissionsGate {
  FakePermissions(this.prayer);

  final PrayerController prayer;
  int asks = 0;
  bool camera = true;

  @override
  Future<void> askOnce() async {
    if (asks++ > 0) return;
    await prayer.locate(userAsked: true);
  }

  /// "Alarms & reminders" is off (Android 14+ at first launch).
  bool exactAlarmsMissing = false;
  bool _exactAlarmsOffered = false;
  int exactAlarmSettingsOpened = 0;

  @override
  Future<bool> shouldOfferExactAlarms() async {
    if (!exactAlarmsMissing || _exactAlarmsOffered) return false;
    return _exactAlarmsOffered = true;
  }

  @override
  Future<void> openExactAlarmSettings() async => exactAlarmSettingsOpened++;

  @override
  Future<bool> cameraGranted() async => camera;

  @override
  Future<void> openAppSettings() async {}
}

PrayerDay dayAt(DateTime day, {String key = 'k'}) {
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  return PrayerDay(
    date: DateTime(day.year, day.month, day.day),
    times: {
      Prayer.fajr: at(5, 0),
      Prayer.sunrise: at(6, 30),
      Prayer.dhuhr: at(12, 0),
      Prayer.asr: at(15, 30),
      Prayer.maghrib: at(18, 0),
      Prayer.isha: at(19, 30),
    },
    hijriDay: 6,
    hijriMonth: 5,
    hijriYear: 1448,
    key: key,
    imsak: at(4, 50),
    lastThird: at(2, 10),
  );
}

/// Saturday 17 October 2026, 11:00 — between sunrise and Dhuhr.
final testNow = DateTime(2026, 10, 17, 11, 0, 0);

class OpenedFeatures {
  final ids = <String>[];
  void call(BuildContext context, Feature feature, AppServices services) => ids.add(feature.id);
}

class TestApp {
  TestApp({
    String? language,
    FakeLocation? location,
    FakeTimes? times,
    MemoryStore? store,
    DateTime? now,
    BusinessStats? stats = const BusinessStats(businesses: 5, categories: 10),
  })  : languageStore = MemoryLanguageStore(language),
        location = location ?? FakeLocation(),
        times = times ?? FakeTimes(),
        store = store ?? MemoryStore() {
    final clockNow = now ?? testNow;
    prayer = PrayerController(
      location: this.location,
      times: this.times,
      store: this.store,
      clock: () => clockNow,
    );
    permissions = FakePermissions(prayer);
    reminders = ReminderController(this.store);
    services = AppServices(
      locale: LocaleController(languageStore),
      prayer: prayer,
      permissions: permissions,
      openFeature: opened.call,
      homeWidget: HomeWidgetBridge(),
      reminders: reminders,
      businessStats: () async => stats,
    );
  }

  final MemoryLanguageStore languageStore;
  final FakeLocation location;
  final FakeTimes times;
  final MemoryStore store;
  final opened = OpenedFeatures();
  late final PrayerController prayer;
  late final FakePermissions permissions;
  late final ReminderController reminders;
  late final AppServices services;

  /// Starts the app on a phone-sized screen (by default 411×891, a Pixel 7).
  Future<void> launch(
    WidgetTester tester, {
    List<Locale> device = const [Locale('ko')],
    Size screen = const Size(411, 891),
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = screen * 3
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // No Android here: the widget and reminder channels answer "nothing"
    // straight away.
    for (final channel in const [MethodChannel('vegukin/widget'), MethodChannel('vegukin/reminders')]) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => null);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    }

    await prayer.start();
    await tester.pumpWidget(VegukinApp(services: services, deviceLocales: device));
    await tester.pumpAndSettle();
  }
}
