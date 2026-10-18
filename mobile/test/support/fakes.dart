import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/app.dart';
import 'package:muslim_vegukin/app_services.dart';
import 'package:muslim_vegukin/core/key_value_store.dart';
import 'package:muslim_vegukin/core/locale_controller.dart';
import 'package:muslim_vegukin/core/activity_log.dart';
import 'package:muslim_vegukin/core/system.dart';
import 'package:muslim_vegukin/features/barcode/barcode_camera.dart';
import 'package:muslim_vegukin/features/barcode/barcode_models.dart';
import 'package:muslim_vegukin/features/barcode/barcode_source.dart';
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

  int settingsOpened = 0;

  @override
  Future<void> openAppSettings() async => settingsOpened++;
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

/// The actions the app reported, as `action` or `action:detail`.
class FakeActivityLog implements ActivityLog {
  final actions = <String>[];

  @override
  void log(String action, [String? detail]) => actions.add(detail == null ? action : '$action:$detail');
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
      activity: activity,
      qiblaDevice: qibla,
      businessStats: () async => stats,
      parcels: this.parcels,
      openLink: (uri) async => links.add(uri),
      shareText: (text) async => shared.add(text),
      linksScript: () async => linksScript,
      system: system,
      barcodes: barcodes,
      barcodeCamera: () {
        final camera = FakeScannerCamera(denied: cameraDenied);
        cameras.add(camera);
        return camera;
      },
    );
  }

  final MemoryLanguageStore languageStore;
  final FakeLocation location;
  final FakeTimes times;
  final MemoryStore store;
  final opened = OpenedFeatures();
  final activity = FakeActivityLog();
  final qibla = FakeQiblaDevice();
  final FakeParcels parcels;

  /// What the app opened outside itself: Telegram, the dialer, the browser.
  final links = <Uri>[];

  /// What the app handed to the share sheet.
  final shared = <String>[];

  /// The web page's links script; null: not reachable.
  String? linksScript;
  final system = FakeSystem();
  final barcodes = FakeBarcodes();

  /// Each camera the ingredient check opened, the last one current.
  final cameras = <FakeScannerCamera>[];
  bool cameraDenied = false;
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

/// Two banking apps installed, a Galaxy S22+ on Android 14.
class FakeSystem implements SystemBridge {
  List<String> installed = ['viva.republica.toss', 'com.kebhana.hanapush'];
  final opened = <String>[];

  @override
  Future<List<InstalledApp>> installedApps(List<String> packages) async =>
      [for (final p in packages) if (installed.contains(p)) InstalledApp(p, null)];

  @override
  Future<bool> openApp(String package) async {
    opened.add(package);
    return installed.contains(package);
  }

  @override
  Future<DeviceInfo?> device() async =>
      const DeviceInfo(phone: 'samsung SM-S906N', android: '14', version: '1.0.0 (1)');
}

/// The halal database: three known products, three stores. [fail]: no
/// connection.
class FakeBarcodes implements BarcodeSource {
  bool fail = false;
  final lookedUp = <String>[];

  /// Each store page asked for, as `verdict/category/offset`.
  final pages = <String>[];

  static const cola = Product(
    barcode: '8801043014809',
    verdict: Verdict.joiz,
    name: '롯데 칠성사이다 500ml',
    nameEnglish: 'Chilsung Cider',
    image: '/api/v2/image/8801043014809.jpg',
    ingredients: '정제수, 설탕, 이산화탄소, 구연산, 향료',
    category: 'Drinks',
    source: 'store_products',
    store: 'GS25',
    otherStores: ['CU', '7-Eleven'],
    sameFactory: false,
  );
  static const sausage = Product(
    barcode: '8801234567893',
    verdict: Verdict.nojoiz,
    name: '돼지고기 소시지',
    pork: true,
    meat: true,
    source: 'general',
  );
  static const cookie = Product(
    barcode: '8809999999997',
    verdict: Verdict.shubhali,
    name: '초코 쿠키',
    ambiguous: true,
    sameFactory: true,
    source: 'store_products',
    store: 'CU',
  );

  final products = {for (final p in [cola, sausage, cookie]) p.barcode: p};

  /// The photo every store product gets; none by default.
  String? storeImage;

  List<StoreSummary> storeList = const [
    StoreSummary(store: 'GS25', count: 120),
    StoreSummary(store: 'CU', count: 45),
    StoreSummary(store: 'Daiso', count: 3),
  ];

  @override
  Future<Product?> product(String code) async {
    lookedUp.add(code);
    if (fail) throw const BarcodeException('offline');
    return products[code];
  }

  @override
  Future<List<StoreSummary>> stores() async {
    if (fail) throw const BarcodeException('offline');
    return storeList;
  }

  @override
  Future<StoreMeta> store(String store) async {
    if (fail) throw const BarcodeException('offline');
    return const StoreMeta(
      total: 120,
      byVerdict: {Verdict.joiz: 45, Verdict.shubhali: 3, Verdict.nojoiz: 0},
      categories: [
        ('Drinks', {Verdict.joiz: 30, Verdict.shubhali: 1, Verdict.nojoiz: 0}),
        ('Snacks', {Verdict.joiz: 15, Verdict.shubhali: 2, Verdict.nojoiz: 0}),
      ],
    );
  }

  /// 45 permissible products, 3 doubtful, none prohibited.
  @override
  Future<ProductPage> storeProducts(
    String store, {
    required Verdict verdict,
    String? category,
    int offset = 0,
    int limit = 20,
  }) async {
    pages.add('${verdict.name}/${category ?? '-'}/$offset');
    if (fail) throw const BarcodeException('offline');
    final count = switch (verdict) { Verdict.joiz => category == 'Snacks' ? 15 : 45, Verdict.shubhali => 3, Verdict.nojoiz => 0 };
    final all = [
      for (var i = 0; i < count; i++)
        Product(
          barcode: '88000000${i.toString().padLeft(5, '0')}',
          verdict: verdict,
          name: '${category ?? 'Mahsulot'} ${i + 1}',
          category: category ?? (i.isEven ? 'Drinks' : 'Snacks'),
          image: storeImage,
        ),
    ];
    final page = all.skip(offset).take(limit).toList();
    return ProductPage(products: page, total: all.length, hasMore: offset + page.length < all.length);
  }
}

/// The camera, played by the test: [read] a code.
class FakeScannerCamera extends ScannerCamera {
  FakeScannerCamera({this.denied = false});

  bool denied;
  CameraStatus _status = CameraStatus.starting;
  bool _torch = false;
  int starts = 0;
  int pauses = 0;

  @override
  CameraStatus get status => _status;

  @override
  bool get hasTorch => true;

  @override
  bool get torchOn => _torch;

  @override
  bool get canSwitch => true;

  void read(String code) => onCode?.call(code);

  @override
  Widget preview(Rect window) => CustomPaint(painter: _FakeScene(window));

  @override
  Future<void> start() async {
    starts++;
    _status = denied ? CameraStatus.denied : CameraStatus.running;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    pauses++;
    if (_status == CameraStatus.running) _status = CameraStatus.paused;
    notifyListeners();
  }

  @override
  Future<void> toggleTorch() async {
    _torch = !_torch;
    notifyListeners();
  }

  @override
  Future<void> switchCamera() async {}
}

/// A shelf in a convenience store, roughly: a packet with a barcode in the
/// window.
class _FakeScene extends CustomPainter {
  _FakeScene(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B4636), Color(0xFF2B3A44), Color(0xFF1C2328)],
        ).createShader(Offset.zero & size),
    );
    final packet = window.inflate(48);
    canvas.drawRRect(RRect.fromRectAndRadius(packet, const Radius.circular(14)), Paint()..color = const Color(0xFFE53935));
    final label = Rect.fromCenter(center: window.center, width: window.width * 0.62, height: window.height * 0.62);
    canvas.drawRect(label, Paint()..color = Colors.white);
    final bars = Paint()..color = Colors.black;
    var x = label.left + 10;
    var i = 0;
    while (x < label.right - 10) {
      final w = [1.5, 3.0, 1.5, 2.2, 4.0][i++ % 5];
      canvas.drawRect(Rect.fromLTWH(x, label.top + 8, w, label.height - 26), bars);
      x += w + [1.6, 2.4, 1.6, 3.2][i % 4];
    }
  }

  @override
  bool shouldRepaint(_FakeScene old) => old.window != window;
}
