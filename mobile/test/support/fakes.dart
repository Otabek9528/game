import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/app.dart';
import 'package:muslim_vegukin/app_services.dart';
import 'package:muslim_vegukin/core/key_value_store.dart';
import 'package:muslim_vegukin/core/locale_controller.dart';
import 'package:muslim_vegukin/core/theme_controller.dart';
import 'package:muslim_vegukin/features/home/feature_catalog.dart';
import 'package:muslim_vegukin/features/parcel/parcel_models.dart';
import 'package:muslim_vegukin/features/parcel/parcel_source.dart';
import 'package:muslim_vegukin/features/prayer/prayer_controller.dart';
import 'package:muslim_vegukin/features/prayer/prayer_models.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';
import 'package:muslim_vegukin/features/qibla/qibla_sensors.dart';
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
    FakeParcels? parcels,
  })  : languageStore = MemoryLanguageStore(language),
        parcels = parcels ?? FakeParcels(),
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
      store: this.store,
      locale: LocaleController(languageStore),
      theme: ThemeController(this.store),
      prayer: prayer,
      permissions: permissions,
      openFeature: opened.call,
      homeWidget: HomeWidgetBridge(),
      reminders: reminders,
      qiblaDevice: qibla,
      businessStats: () async => stats,
      parcels: this.parcels,
      openLink: (uri) async => links.add(uri),
    );
  }

  final MemoryLanguageStore languageStore;
  final FakeLocation location;
  final FakeTimes times;
  final MemoryStore store;
  final opened = OpenedFeatures();
  final qibla = FakeQiblaDevice();
  final FakeParcels parcels;

  /// What the app opened outside itself: Telegram, the dialer, the browser.
  final links = <Uri>[];
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

/// The compass and camera, played by the test: [send] a reading.
class FakeQiblaDevice implements QiblaDevice {
  FakeQiblaDevice({this.compass = true});

  final bool compass;
  final controller = StreamController<CompassReading>.broadcast();
  bool screenOn = false;
  CameraProblem? cameraProblem;

  void send({
    double top = 0,
    double camera = 0,
    double tilt = 5,
    double accuracy = 5,
    int status = 3,
    double field = 51.3,
  }) =>
      controller.add(CompassReading(
        top: top,
        camera: camera,
        cameraUp: tilt - 90,
        tilt: tilt,
        levelX: 0,
        levelY: 0,
        accuracy: accuracy,
        status: status,
        field: field,
        source: 'rotation',
      ));

  @override
  Stream<CompassReading> readings() => controller.stream;

  @override
  Future<bool> hasCompass() async => compass;

  @override
  Future<void> keepScreenOn(bool on) async => screenOn = on;

  @override
  Future<CameraFeed> startCamera() async {
    if (cameraProblem != null) throw CameraException(cameraProblem!);
    return const CameraFeed(
      textureId: 1,
      width: 1280,
      height: 960,
      sensorOrientation: 90,
      fovLong: 66,
      fovShort: 51,
      rotateInApp: false,
    );
  }

  @override
  Future<void> stopCamera() async {}
}

/// Parcel posts: two days and two cities from Korea to Uzbekistan, one day
/// the other way. [fail] makes every request fail.
class FakeParcels implements ParcelSource {
  bool fail = false;
  final requests = <String>[];

  static final korToUzbDates = [
    ParcelDate(date: DateTime(2026, 10, 18), key: '18.10.2026', count: 2),
    ParcelDate(date: DateTime(2026, 10, 21), key: '21.10.2026', count: 1),
  ];

  static final uzbToKorDates = [ParcelDate(date: DateTime(2026, 10, 25), key: '25.10.2026', count: 1)];

  static final posts = {
    '18.10.2026': [
      const ParcelPost(
        text: 'Toshkentga uchaman. 1 kg — 15 000 won. Tel: 010-1234-5678',
        username: 'akmal_kuryer',
        flightTime: '18.10.2026 14:30',
      ),
      const ParcelPost(text: 'Samarqandga pochta olaman, +998 90 123 45 67', flightTime: '18.10.2026'),
    ],
    '21.10.2026': [const ParcelPost(text: 'Buxoroga. @bobur_cargo ga yozing', flightTime: '21.10.2026')],
    '25.10.2026': [const ParcelPost(text: 'Seulga olib boraman', username: 'dilshod')],
  };

  Future<T> _answer<T>(String request, T value) async {
    requests.add(request);
    if (fail) throw const ParcelException('offline');
    return value;
  }

  @override
  Future<List<ParcelDate>> dates(ParcelDirection direction) => _answer(
        'dates ${direction.api}',
        direction == ParcelDirection.korToUzb ? korToUzbDates : uzbToKorDates,
      );

  @override
  Future<List<ParcelPost>> postsByDate(String date, ParcelDirection direction) =>
      _answer('by-date $date ${direction.api}', posts[date] ?? const []);

  @override
  Future<List<ParcelCity>> cities(ParcelCountry country, ParcelDirection direction) => _answer(
        'cities ${country.api} ${direction.api}',
        country == ParcelCountry.kor
            ? const [ParcelCity(name: 'Ansan', count: 2), ParcelCity(name: 'Seul', count: 1)]
            : const [ParcelCity(name: 'Toshkent', count: 3)],
      );

  @override
  Future<List<ParcelPost>> postsByCity(String city, ParcelCountry country, ParcelDirection direction) =>
      _answer('by-city $city ${country.api} ${direction.api}', [...posts['18.10.2026']!]);
}
