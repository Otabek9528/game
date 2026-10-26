import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/app.dart';
import 'package:muslim_vegukin/app_services.dart';
import 'package:muslim_vegukin/core/key_value_store.dart';
import 'package:muslim_vegukin/core/locale_controller.dart';
import 'package:muslim_vegukin/core/account.dart';
import 'package:muslim_vegukin/core/activity_log.dart';
import 'package:muslim_vegukin/core/app_language.dart';
import 'package:muslim_vegukin/core/google_auth.dart';
import 'package:muslim_vegukin/core/push.dart';
import 'package:muslim_vegukin/core/system.dart';
import 'package:muslim_vegukin/features/barcode/barcode_camera.dart';
import 'package:muslim_vegukin/features/barcode/barcode_models.dart';
import 'package:muslim_vegukin/features/barcode/barcode_source.dart';
import 'package:muslim_vegukin/features/business/business_models.dart';
import 'package:muslim_vegukin/features/business/business_source.dart';
import 'package:muslim_vegukin/features/cars/cars_models.dart';
import 'package:muslim_vegukin/features/cars/cars_source.dart';
import 'package:muslim_vegukin/features/housing/housing_source.dart';
import 'package:muslim_vegukin/features/jobs/jobs_source.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_models.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_source.dart';
import 'package:muslim_vegukin/core/theme_controller.dart';
import 'package:muslim_vegukin/features/home/feature_catalog.dart';
import 'package:muslim_vegukin/features/parcel/parcel_models.dart';
import 'package:muslim_vegukin/features/parcel/parcel_source.dart';
import 'package:muslim_vegukin/features/places/places_models.dart';
import 'package:muslim_vegukin/features/places/places_source.dart';
import 'package:muslim_vegukin/features/prayer/prayer_controller.dart';
import 'package:muslim_vegukin/features/prayer/prayer_models.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';
import 'package:muslim_vegukin/features/qibla/qibla_sensors.dart';
import 'package:muslim_vegukin/features/qna/qna_models.dart';
import 'package:muslim_vegukin/features/qna/qna_source.dart';
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

  @override
  Map<String, Object> get who => const {'user_id': -1234567890, 'username': 'Android app'};
}

class TestApp {
  TestApp({
    String? language,
    FakeLocation? location,
    FakeTimes? times,
    MemoryStore? store,
    DateTime? now,
    BusinessStats? stats = const BusinessStats(businesses: 5, categories: 10),
    this.visits,
    FakeParcels? parcels,
    FakeBusinesses? businesses,
  })  : languageStore = MemoryLanguageStore(language),
        parcels = parcels ?? FakeParcels(),
        businesses = businesses ?? FakeBusinesses(),
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
    final locale = LocaleController(languageStore);
    account = AccountController(
      store: this.store,
      source: accounts,
      push: push,
      google: google,
      language: () => locale.language ?? AppLanguage.uz,
    );
    services = AppServices(
      store: this.store,
      locale: locale,
      theme: ThemeController(this.store),
      prayer: prayer,
      permissions: permissions,
      openFeature: opened.call,
      homeWidget: HomeWidgetBridge(),
      reminders: reminders,
      activity: activity,
      account: account,
      qiblaDevice: qibla,
      businessStats: () async => stats,
      todayVisits: () async => visits,
      homePage: () async => homePage,
      parcels: this.parcels,
      openLink: (uri) async => links.add(uri),
      shareText: (text) async => shared.add(text),
      linksScript: () async => linksScript,
      system: system,
      barcodes: barcodes,
      qna: qna,
      businesses: this.businesses,
      hikorea: hikorea,
      places: places,
      cars: cars,
      housing: housing,
      jobs: jobs,
      clock: () => clockNow,
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
  final accounts = FakeAccounts();
  final push = FakePush();
  final google = FakeGoogle();
  late final AccountController account;
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
  final qna = FakeQna();
  final FakeBusinesses businesses;
  final hikorea = FakeHikorea();
  final places = FakePlaces();
  final cars = FakeCars();
  final housing = FakeHousing();
  final jobs = FakeJobs();

  /// Today's visits shown on the home screen; none by default, so the
  /// home screen has nothing that keeps moving.
  int? visits;

  /// The web app's home page, for the "NEW" marks; none by default.
  String? homePage;

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
    bool settle = true,
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
    if (settle) await tester.pumpAndSettle();
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

/// The questions-and-answers archive: each browse gives 15 new questions,
/// a search 3 (none for "yo‘q"), and every question has two similar ones
/// known only by their titles. [fail]: no connection.
class FakeQna implements QnaSource {
  bool fail = false;
  int browses = 0;
  final searches = <String>[];
  Map<String, Object>? who;
  final details = <String>[];

  static const _titles = [
    ('Safarda namozni qasr qilish qanday bo‘ladi?', '🕌 Namoz'),
    ('Ro‘zador tish yuvsa, ro‘zasi buziladimi?', '🌙 Ro‘za'),
    ('Qisqichbaqa yeyish joizmi?', '🍽 Taomlar'),
    ('Bankdan kredit olishning hukmi qanday?', '💰 Muomalot'),
    ('Juma namoziga ulgurmasam nima qilaman?', '🕌 Namoz'),
  ];

  static QnaQuestion question(int i) {
    final (title, topic) = _titles[i % _titles.length];
    return QnaQuestion(
      id: '$i',
      title: i < _titles.length ? title : '$title ($i)',
      topic: topic,
      views: 1200 + i * 37,
      answerSource: 'Shayx Muhammad Sodiq Muhammad Yusuf',
      questionBody: 'Assalomu alaykum. Koreyada ishlayman, shu haqda bilmoqchi edim.',
      answerBody: 'Va alaykum assalom.\n\nUlamolarimiz bu masalada quyidagicha deganlar. Musofir kishi '
          'to‘rt rakatli farz namozlarini ikki rakat qilib o‘qiydi. Bu Alloh taolo tomonidan berilgan '
          'ruxsatdir, uni qabul qilish afzal.\n\nSafar masofasi va muddati haqida mazhabimizda batafsil '
          'aytilgan. Batafsil: https://savollar.islom.uz/s/$i',
      link: Uri.parse('https://savollar.islom.uz/s/$i'),
    );
  }

  @override
  Future<List<QnaQuestion>> browse({int limit = 15}) async {
    if (fail) throw const QnaException('offline');
    final first = browses++ * 100;
    return [for (var i = first; i < first + limit; i++) question(i)];
  }

  @override
  Future<List<QnaQuestion>> search(String query, {int limit = 20, Map<String, Object> who = const {}}) async {
    searches.add(query);
    this.who = who;
    if (fail) throw const QnaException('offline');
    if (query.contains('yo‘q')) return const [];
    return [question(2), question(0), question(4)];
  }

  @override
  Future<QnaDetail> detail(String id) async {
    details.add(id);
    if (fail) throw const QnaException('offline');
    return QnaDetail(
      question: question(int.parse(id)),
      related: const [
        QnaQuestion(id: '900', title: 'Dengiz mahsulotlarining hukmi'),
        QnaQuestion(id: '901', title: 'Halol va harom taomlar'),
      ],
    );
  }
}

/// The business directory: four kinds (one empty), three halal markets of
/// which two share first place, a bakery, two post offices. [fail]: no
/// connection.
class FakeBusinesses implements BusinessSource {
  bool fail = false;
  int directories = 0;
  final searches = <String>[];
  final opened = <String>[];
  final counted = <String>[];

  /// A logo's bytes, by its address; none, by default: the monogram.
  final logos = <String, Uint8List>{};

  static const halal = BizCategory(id: '1', slug: 'halal-market', name: 'Halol market', icon: '🥩', count: 3);
  static const bakery = BizCategory(id: '2', slug: 'pishiriqlar', name: 'Pishiriqlar', icon: '🥐', count: 1);
  static const translation = BizCategory(id: '3', slug: 'tarjima', name: 'Tarjima va apostil', icon: '📄', count: 0);
  static const post = BizCategory(id: '4', slug: 'pochta', name: 'Pochta', icon: '📦', count: 2);

  static const baraka = Business(
    id: '11',
    name: 'Baraka Halal Mart',
    logo: '/uploads/baraka.png',
    description: 'Eng yangi halol go‘sht har kuni\n\nManzil: Seoul, Itaewon-ro 12\nIsh vaqti: 09:00–21:00\n'
        'Buyurtma: 010-9876-5432\nInstagram: https://instagram.com/baraka.mart',
    likes: 12,
    views: 340,
    categoryId: '1',
    categoryName: 'Halol market',
    links: [
      BizLink('instagram', 'https://instagram.com/baraka.mart'),
      BizLink('phone', '010-1234-5678'),
      BizLink('telegram', 'https://t.me/baraka_halal'),
      BizLink('tgchannel', 'https://t.me/+AbCdEf123'),
    ],
  );
  static const ansan = Business(
    id: '12',
    name: 'Ansan Halol Go‘sht',
    description: 'Mol, qo‘y va tovuq go‘shti.',
    likes: 12,
    views: 120,
    categoryId: '1',
    categoryName: 'Halol market',
    links: [BizLink('kakao', 'https://open.kakao.com/o/ansan')],
  );
  static const samarqand = Business(id: '13', name: 'Samarqand Market', categoryId: '1', categoryName: 'Halol market');
  static const nonvoy = Business(
    id: '21',
    name: 'Nonvoyxona Toshkent',
    logo: '/uploads/nonvoy.jpg',
    description: 'Tandir non va somsa',
    likes: 3,
    categoryId: '2',
    categoryName: 'Pishiriqlar',
    links: [BizLink('phone', '010-2222-3333')],
  );
  static const cargo = Business(id: '41', name: 'Asia Cargo', logo: '/uploads/cargo.png', likes: 5, categoryId: '4',
      categoryName: 'Pochta', links: [BizLink('telegram', 'https://t.me/asiacargo')]);
  static const express = Business(id: '42', name: 'Express Pochta', likes: 0, categoryId: '4', categoryName: 'Pochta',
      links: [BizLink('phone', '010-4444-5555')]);

  static const lists = {
    '1': [baraka, ansan, samarqand],
    '2': [nonvoy],
    '3': <Business>[],
    '4': [cargo, express],
  };

  static Business _row(Business b) => Business(
        id: b.id,
        name: b.name,
        logo: b.logo,
        description: b.description,
        likes: b.likes,
        categoryId: b.categoryId,
      );

  @override
  Future<BizDirectory> directory() async {
    directories++;
    if (fail) throw const BizException('offline');
    return const BizDirectory(categories: [halal, bakery, post, translation], listingFee: 15000);
  }

  @override
  Future<List<Business>> category(String id) async {
    if (fail) throw const BizException('offline');
    return [for (final b in lists[id] ?? const <Business>[]) _row(b)];
  }

  @override
  Future<List<BizGroup>> search(String query) async {
    searches.add(query);
    if (fail) throw const BizException('offline');
    final q = query.toLowerCase();
    return [
      for (final c in const [halal, bakery, post])
        if ([for (final b in lists[c.id]!) if (b.name.toLowerCase().contains(q)) _row(b)] case final found when found.isNotEmpty)
          BizGroup(category: c, total: found.length, businesses: found),
    ];
  }

  @override
  Future<Business> business(String id) async {
    opened.add(id);
    if (fail) throw const BizException('offline');
    return lists.values.expand((l) => l).firstWhere((b) => b.id == id);
  }

  @override
  void countView(String id) => counted.add(id);

  @override
  Future<Uint8List?> logo(Uri url) async => logos[url.path];
}

/// Opens [page] over the home screen directly: for a section the home screen
/// doesn't offer in the app's language. Settling is left to the caller.
Future<void> pushPage(WidgetTester tester, Widget page) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<void>(builder: (_) => page));
  await tester.pump();
}

/// The server's app accounts: one per hello, ids counting down from
/// -9000000000001. A sign-in link is answered with [confirm]. [fail]: offline.
class FakeAccounts implements AccountSource {
  bool fail = false;
  int _next = 0;
  final users = <String, AppUser>{};
  final devices = <(String token, String? pushToken, String? lang)>[];
  final links = <String>[];
  final _answers = <String, (String, AppUser?)>{};
  final deleted = <String>[];

  void _online() {
    if (fail) throw const AccountException('offline');
  }

  AppUser _anonymous() => AppUser(id: -9000000000000 - ++_next);

  AppUser _of(String token) => users[token] ?? (throw const AccountException('bad_session', 401));

  /// The person said Yes in the bot: signed in as [user].
  void confirm(String code, AppUser user) => _answers[code] = ('done', user);

  void cancel(String code) => _answers[code] = ('cancelled', null);

  @override
  Future<(String, AppUser)> hello({required String lang, String? pushToken}) async {
    _online();
    final token = 'token-${_next + 1}';
    final user = _anonymous();
    users[token] = user;
    devices.add((token, pushToken, lang));
    return (token, user);
  }

  @override
  Future<AppUser> me(String token) async {
    _online();
    return _of(token);
  }

  @override
  Future<void> updateDevice(String token, {String? pushToken, String? lang}) async {
    _online();
    _of(token);
    devices.add((token, pushToken, lang));
  }

  @override
  Future<AppUser> signInWithGoogle(String token, String idToken) async {
    _online();
    _of(token);
    if (idToken != 'google-id-token') throw const AccountException('bad_token', 401);
    return users[token] =
        const AppUser(id: -9000000000777, signedIn: true, provider: 'google', name: 'Rahim', detail: 'rahim@example.com');
  }

  @override
  Future<LoginLink> link(String token, String provider) async {
    _online();
    _of(token);
    final code = 'CODE${links.length + 1}';
    links.add(code);
    return LoginLink(
      code: code,
      url: provider == 'telegram'
          ? Uri.parse('https://t.me/MuslimVegukinBot?start=applogin_$code')
          : Uri.parse('https://wa.me/821012345678?text=LOGIN%20$code'),
      expiresIn: const Duration(minutes: 10),
    );
  }

  @override
  Future<(String, AppUser?)> linkStatus(String token, String code) async {
    _online();
    _of(token);
    final answer = _answers[code] ?? ('pending', null);
    if (answer.$2 != null) users[token] = answer.$2!;
    return answer;
  }

  @override
  Future<AppUser> signOut(String token) async {
    _online();
    _of(token);
    return users[token] = _anonymous();
  }

  @override
  Future<void> delete(String token) async {
    _online();
    _of(token);
    deleted.add(token);
    users.remove(token);
  }

  /// Profile photos by user id; how many times one was fetched.
  final photos = <int, Uint8List>{};
  int photoFetches = 0;

  @override
  Future<Uint8List?> photo(String token) async {
    _online();
    photoFetches++;
    return photos[_of(token).id];
  }

  /// Test notifications asked for, by token; [testPushError]: the answer instead.
  final testPushes = <String>[];
  String? testPushError;

  @override
  Future<void> testPush(String token) async {
    _online();
    _of(token);
    if (testPushError case final code?) throw AccountException(code, 409);
    testPushes.add(token);
  }

  /// What was pushed to each user id, oldest first.
  final inboxes = <int, List<InboxItem>>{};
  int _alerts = 0;
  int pageSize = 50;

  /// An alert pushed to [userId], as the server keeps it.
  InboxItem alert(
    int userId,
    String title, {
    String body = '',
    String? text,
    List<String> images = const [],
    Map<String, String> data = const {},
    DateTime? at,
  }) {
    final item = InboxItem(id: ++_alerts, title: title, body: body, text: text, images: images, data: data, at: at ?? testNow);
    (inboxes[userId] ??= []).add(item);
    return item;
  }

  @override
  Future<(List<InboxItem>, bool)> inbox(String token, {int? before}) async {
    _online();
    final all = [
      for (final item in (inboxes[_of(token).id] ?? const <InboxItem>[]).reversed)
        if (before == null || item.id < before) item,
    ];
    return (all.take(pageSize).toList(), all.length > pageSize);
  }
}

/// Notifications, played by the test: [allowed] or not, and [open] / [arrive].
class FakePush implements PushService {
  bool allowed = true;
  String token = 'push-token';
  int starts = 0;
  PushOpened? _onOpen;
  PushArrived? _onForeground;

  void open(Map<String, String> data) => _onOpen?.call(PushMessage(data: data));

  void arrive(String title, String body, [Map<String, String> data = const {}]) =>
      _onForeground?.call(PushMessage(title: title, body: body, data: data));

  @override
  Future<bool> start({
    required void Function(String token) onToken,
    required PushOpened onOpen,
    required PushArrived onForeground,
  }) async {
    starts++;
    _onOpen = onOpen;
    _onForeground = onForeground;
    if (allowed) onToken(token);
    return allowed;
  }

  @override
  Future<bool> isAllowed() async => allowed;
}

/// Google's account picker: a token, or null when the person closes it.
class FakeGoogle implements GoogleAuth {
  String? answer = 'google-id-token';
  int signOuts = 0;

  @override
  Future<String?> idToken() async => answer;

  @override
  Future<void> signOut() async => signOuts++;
}

/// A 1×1 PNG: a profile photo, for tests.
final transparentPng = Uint8List.fromList(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x64, 0x60, 0xF8, 0x5F, 0x0F, 0x00, 0x02, 0x87, 0x01, 0x80, 0xEB, 0x47, 0xBA, 0x92, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82]);

/// The HiKorea server, played by the test: three offices (Ansan with two
/// counters), a calendar around [testNow], live days, and watches.
class FakeHikorea implements HikoreaSource {
  bool fail = false;

  /// What a day's live check answers instead: 'session_expired' …
  String? dayError;
  final watchList = <HkWatch>[];
  final tests = <String>[];
  final asked = <String>[];
  int _next = 0;

  void _online() {
    if (fail) throw const HkException('offline');
  }

  static final _offices = [
    HkOffice(id: '1270667', nameEn: 'Ansan Immigration Office', nameKo: '안산출입국·외국인사무소', shortCode: 'AS', desks: const [
      HkDesk(
        seq: 101,
        booth: {'en': "Ansan Center] Residence Control(location: Ansan Foreign Resident's Support Headquarters 1F)(2023.09.19.~, AFTER 09:36)"},
        details: {'en': 'Registration, extension of stay and change of status for residents of Danwon-gu.'},
      ),
      HkDesk(seq: 102, booth: {'en': 'Siheung Center] Residence Control(location: Siheung migrant welfare Center 2F)(2023.09.19.~)'}),
    ]),
    HkOffice(id: '1270100', nameEn: 'Seoul Immigration Office', nameKo: '서울출입국·외국인청', shortCode: 'SU', desks: const [
      HkDesk(seq: 201, booth: {'en': 'Foreigner Residence Control(1F, All countries)(2023.10.14.~)', 'uz': 'Chet ellik rezidentlar nazorati(1-qavat, Barcha mamlakatlar)(2023.10.14.~)'}),
    ]),
    HkOffice(id: 'GIMHAE BRANCH OFFICE', nameEn: 'GIMHAE BRANCH OFFICE', desks: const [HkDesk(seq: 301, booth: {'en': 'Others(2021.05.01 ~ )'})]),
  ];

  /// Instead of the three: the real list, for screenshots.
  List<HkOffice>? officesOverride;

  @override
  Future<List<HkOffice>> offices() async {
    _online();
    return officesOverride ?? _offices;
  }

  @override
  Future<List<String>> provinces() async {
    _online();
    return const ['경기', '경남', '서울'];
  }

  @override
  Future<List<HkMatch>> resolve(String province, String address) async {
    _online();
    asked.add('$province|$address');
    if (province == '경기' && address.contains('단원구')) {
      return const [HkMatch(officeId: '1270667', nameEn: 'Ansan Immigration Office', nameKo: '안산출입국·외국인사무소', district: '안산시 단원구')];
    }
    return const [];
  }

  /// Counters HiKorea retired: they list nothing since 16 October.
  final dormantDesks = <int>{};

  /// Counters with a calendar of their own instead of the one below.
  final calendarFor = <int, HkCalendar>{};

  /// How long a calendar takes to come; how many were asked for at once.
  Duration? calendarDelay;
  int inFlight = 0, mostInFlight = 0;

  /// Mon 19 Oct: 5 booked, Tue 20: 40 (full), Mon 26: 10 (full), Tue 27: 20;
  /// the other working days to the end of November nobody has booked yet;
  /// Tue 3 Nov is a holiday.
  /// Answers every counter's calendar in one request (update 7 on).
  bool bulk = true;

  @override
  Future<Map<int, HkCalendar>> calendars() async {
    _online();
    asked.add('calendars');
    if (!bulk) throw const HkException('unsupported', 404);
    return {
      for (final office in officesOverride ?? _offices)
        for (final desk in office.desks) desk.seq: _calendarOf(desk.seq),
    };
  }

  @override
  Future<HkCalendar> calendar(int desk) async {
    _online();
    asked.add('calendar $desk');
    if (calendarDelay case final delay?) {
      mostInFlight = max(mostInFlight, ++inFlight);
      await Future<void>.delayed(delay);
      inFlight--;
    }
    return _calendarOf(desk);
  }

  HkCalendar _calendarOf(int desk) {
    if (calendarFor[desk] case final calendar?) return calendar;
    if (dormantDesks.contains(desk)) {
      return HkCalendar(deskSeq: desk, dormant: true, listedUntil: DateTime(2026, 10, 16), deskCapacity: 180, status: 'ok');
    }
    return HkCalendar(
      deskSeq: desk,
      listed: const {'20261019': 5, '20261020': 40, '20261026': 10, '20261027': 20},
      schedule: const HkSchedule(first: '20261019', last: '20261130', holidays: {'20261103'}, weekdays: {0, 1, 2, 3, 4}),
      checkedAt: testNow.subtract(const Duration(minutes: 5)),
      status: 'ok',
    );
  }

  @override
  Future<HkDay> day(int desk, String ymd) async {
    _online();
    asked.add('day $desk $ymd');
    if (dayError case final code?) throw HkException(code, 502);
    if (ymd == '20261020') {
      return const HkDay(
        slots: [HkTimeSlot(time: '09:00', capacity: 20, available: 0), HkTimeSlot(time: '14:00', capacity: 20, available: 0)],
        capacity: 40,
        taken: 40,
        available: 0,
      );
    }
    return const HkDay(
      slots: [
        HkTimeSlot(time: '09:00', capacity: 4, available: 2),
        HkTimeSlot(time: '10:00', capacity: 4, available: 0),
        HkTimeSlot(time: '14:00', capacity: 4, available: 4),
      ],
      capacity: 12,
      taken: 6,
      available: 6,
    );
  }

  @override
  Future<List<HkWatch>> watches(Map<String, String> auth, {bool past = false}) async {
    _online();
    return [for (final w in watchList.reversed) if (past || w.active) w];
  }

  @override
  Future<HkWatch> watch(Map<String, String> auth, {required int desk, required String start, required String end, required String lang}) async {
    _online();
    if (watchList.any((w) => w.active && w.deskSeq == desk && ymdOf(w.start) == start && ymdOf(w.end) == end)) {
      throw const HkException('duplicate_watch', 409);
    }
    if (watchList.where((w) => w.active).length >= 10) throw const HkException('max_watches_reached', 409);
    final office = (officesOverride ?? _offices).firstWhere((o) => o.desk(desk) != null);
    final watch = HkWatch(
      id: ++_next,
      officeId: office.id,
      officeNameEn: office.nameEn,
      deskSeq: desk,
      booth: office.desk(desk)!.booth,
      start: parseYmd(start)!,
      end: parseYmd(end)!,
      status: 'active',
    );
    watchList.add(watch);
    return watch;
  }

  @override
  Future<void> stop(Map<String, String> auth, int id) async {
    _online();
    final i = watchList.indexWhere((w) => w.id == id);
    final w = watchList[i];
    watchList[i] = HkWatch(
      id: w.id,
      officeId: w.officeId,
      officeNameEn: w.officeNameEn,
      deskSeq: w.deskSeq,
      booth: w.booth,
      start: w.start,
      end: w.end,
      status: 'cancelled',
    );
  }

  @override
  Future<void> test(Map<String, String> auth, String lang) async {
    _online();
    tests.add(lang);
  }
}

/// The places server, played by the test: mosques around Ansan (where
/// [FakeLocation] is), Seoul and Daegu, one without a location; a
/// restaurant and a shop in Ansan; reviews, watches, suggestions.
class FakePlaces implements PlacesSource {
  bool fail = false;

  /// A server before update 6: reviews don't say whose.
  bool oldServer = false;
  final asked = <String>[];

  static Place _p(int id, String name, PlaceKind kind,
          {String? city, String? address, String phone = '', double? lat, double? lon, int reviews = 0, double rating = 0,
          String? photo, String? note, String? telegram, String? menu, String? kakao, String? naver}) =>
      Place.fromJson({
        'id': id, 'name': name, 'buildingType': kind.buildingType, 'city': city, 'address': address, 'phone': phone,
        'lat': lat, 'lon': lon, 'reviewCount': reviews, 'averageRating': rating, 'photo': photo, 'ownerNote': note,
        'telegramUrl': telegram, 'menuUrl': menu, 'kakaoMapUrl': kakao, 'naverMapUrl': naver,
      })!;

  final places = <PlaceKind, List<Place>>{
    PlaceKind.mosque: [
      _p(1, 'Ansan Markaziy Masjidi', PlaceKind.mosque, city: 'Ansan', address: '경기 안산시 단원구 원곡로 5',
          phone: '010-1111-2222, 031-555-6666', lat: 37.33, lon: 126.81, reviews: 3, rating: 4.7,
          note: 'Juma namozi: 13:00\nHar kuni ochiq', telegram: 'https://t.me/ansanmasjid',
          kakao: 'https://place.map.kakao.com/1', naver: 'https://naver.me/abc'),
      _p(2, 'Siheung Masjidi', PlaceKind.mosque, city: 'Siheung', address: '경기 시흥시 정왕동 1', lat: 37.38, lon: 126.80),
      _p(3, 'Seoul Markaziy Masjidi', PlaceKind.mosque, city: 'Seoul', address: '서울 용산구 우사단로10길 39',
          phone: '02-793-6908', lat: 37.533, lon: 126.997, reviews: 12, rating: 4.5, photo: 'Photos/117'),
      _p(4, 'Daegu Masjid', PlaceKind.mosque, city: 'Daegu', address: '대구 북구 대현로 1', lat: 35.87, lon: 128.6),
      _p(5, 'Yangi namozxona', PlaceKind.mosque, address: '경기 화성시 1'),
      _p(6, 'Ansan Nur Masjidi', PlaceKind.mosque, city: 'Ansan', address: '경기 안산시 단원구 2', lat: 37.31, lon: 126.84),
    ],
    PlaceKind.restaurant: [
      _p(101, 'Samarqand Osh Markazi', PlaceKind.restaurant, city: 'Ansan', address: '경기 안산시 단원구 3',
          phone: '010-3333-4444', lat: 37.321, lon: 126.832, reviews: 5, rating: 4.2, menu: 'https://menu.example/osh'),
    ],
    PlaceKind.shop: [
      _p(201, 'Halol Market', PlaceKind.shop, city: 'Ansan', address: '경기 안산시 단원구 4', lat: 37.322, lon: 126.828),
    ],
  };

  final reviews = <int, List<PlaceReview>>{
    1: [
      PlaceReview(rating: 5, text: 'Juda toza, wudu joyi bor', at: DateTime(2026, 10, 1)),
      PlaceReview(rating: 4, at: DateTime(2026, 9, 20)),
      PlaceReview(rating: 5, text: 'Juma namozida joy kam', at: DateTime(2025, 12, 2)),
    ],
  };
  final pending = <int, Set<String>>{};
  final watches = <int, PlaceWatch>{1: const PlaceWatch(count: 43)};
  final suggestions = <(int, String, String)>[];
  final announcements = <(int, String)>[];
  final claims = <int>[];

  /// Codes to answer the next call of that name with: review, suggest, …
  final failNext = <String, String>{};

  Place byId(int id) => places.values.expand((l) => l).firstWhere((p) => p.id == id);

  void _online(String call) {
    asked.add(call);
    if (fail) throw const PlacesException('offline');
    if (failNext.remove(call.split(' ').first) case final code?) throw PlacesException(code, 400);
  }

  /// Where the last nearby search looked from.
  ({double lat, double lon})? lastNear;

  @override
  Future<List<Place>> nearby(PlaceKind kind, double lat, double lon, {int limit = 5}) async {
    _online('nearby ${kind.key} $limit');
    lastNear = (lat: lat, lon: lon);
    final list = [
      for (final p in places[kind]!)
        if (p.located) p,
    ]..sort((a, b) => a.distanceFrom(lat, lon)!.compareTo(b.distanceFrom(lat, lon)!));
    return [
      for (final p in list.take(limit)) Place.fromJson({...p.toJson(), 'distance': p.distanceFrom(lat, lon)})!,
    ];
  }

  @override
  Future<AddressPlaces> nearAddress(PlaceKind kind, String address, {int limit = 5}) async {
    _online('address ${kind.key} $address $limit');
    if (!address.contains('서울')) throw const PlacesException('http_404', 404);
    // Itaewon.
    final near = await nearby(kind, 37.534, 126.994, limit: limit);
    asked.removeLast();
    return (places: near, lat: 37.534, lon: 126.994, label: '서울 용산구 이태원동');
  }

  @override
  Future<PlaceDetail> detail(int id, Map<String, String> auth) async {
    _online('detail $id ${auth['Authorization'] ?? '-'}');
    final place = places.values.expand((l) => l).where((p) => p.id == id).firstOrNull;
    if (place == null) throw const PlacesException('http_404', 404);
    return PlaceDetail(
      place: place,
      reviews: List.of(reviews[id] ?? const []),
      pending: {...?pending[id]},
      watch: watches[id] ?? const PlaceWatch(),
      ownReviews: !oldServer,
    );
  }

  @override
  Future<bool> review(Map<String, String> auth, int id, int rating, String text) async {
    _online('review $id $rating $text');
    final list = reviews[id] ??= [];
    final had = list.any((r) => r.mine);
    list
      ..removeWhere((r) => r.mine)
      ..insert(0, PlaceReview(rating: rating, text: text, at: testNow, mine: true));
    return had;
  }

  @override
  Future<void> deleteReview(Map<String, String> auth, int id) async {
    _online('unreview $id');
    reviews[id]?.removeWhere((r) => r.mine);
  }

  @override
  Future<void> suggest(Map<String, String> auth, int id, String field, String value) async {
    _online('suggest $id $field');
    suggestions.add((id, field, value));
    (pending[id] ??= {}).add(field);
  }

  @override
  Future<PlaceWatch> watch(Map<String, String> auth, int id, {required bool on, required String lang}) async {
    _online('watch $id $on $lang');
    final before = watches[id] ?? const PlaceWatch();
    return watches[id] = before.copyWith(watching: on, count: before.count + (on == before.watching ? 0 : (on ? 1 : -1)));
  }

  @override
  Future<int> reach(Map<String, String> auth, int id) async {
    _online('reach $id');
    return watches[id]?.count ?? 0;
  }

  @override
  Future<int> announce(Map<String, String> auth, int id, String text, String lang) async {
    _online('announce $id');
    announcements.add((id, text));
    return announcements.where((a) => a.$1 == id).length;
  }

  @override
  Future<void> claim(Map<String, String> auth, int id, String lang) async {
    _online('claim $id');
    claims.add(id);
  }

  @override
  Future<List<WatchedPlace>> watched(Map<String, String> auth) async {
    _online('watched');
    return [
      for (final MapEntry(:key, :value) in watches.entries)
        if (value.watching) WatchedPlace(id: key, name: byId(key).name, kind: byId(key).kind),
    ];
  }

  /// The web app's photo list.
  Map<String, List<String>> manifest = {
    'Photos/117': ['png:9991877d', 'jpg:28c75fa8'],
  };

  @override
  Future<Map<String, List<String>>> photoManifest() async {
    _online('photos');
    return manifest;
  }

  /// Photos on the site by path ("Photos/117/1.jpg"), with their version;
  /// how many were looked for.
  Map<String, String> files = {};
  int photoProbes = 0;

  /// Holds every look for a photo until completed.
  Completer<void>? probeGate;

  @override
  Future<String?> photoTag(Uri url) async {
    photoProbes++;
    await probeGate?.future;
    _online('photo');
    return files[url.pathSegments.join('/')];
  }
}


/// The used-car market: Hyundai Sonata (six listings, one sold), Kia K5
/// (one), a Genesis without a price.
class FakeCars implements CarsSource {
  bool fail = false;
  final asked = <String>[];
  final views = <int>[];

  static Map<String, Object?> _car(int id, String brand, String model,
          {int? year, int? price, int? km, String status = 'active', String? fuel, String? gen, bool negotiable = false}) =>
      {
        'id': id, 'brand': brand, 'model': model, 'year': year, 'price_krw': price, 'mileage_km': km, 'status': status,
        'fuel': fuel, 'transmission': 'automatic', 'generation': gen, 'negotiable': negotiable, 'posted_rel': '$id kun oldin',
        'thumb': '/media/cars/$id/t.jpg', 'photo': '/media/cars/$id/1.jpg',
      };

  final cars = <Map<String, Object?>>[
    _car(1, 'Hyundai', 'Sonata', year: 2015, price: 5500000, km: 120000, fuel: 'lpg', gen: 'LF'),
    _car(2, 'Hyundai', 'Sonata', year: 2014, price: 7200000, km: 98000, fuel: 'petrol', gen: 'LF', negotiable: true),
    _car(3, 'Hyundai', 'Sonata', year: 2016, price: 7500000, km: 80000, fuel: 'petrol', gen: 'LF'),
    _car(4, 'Hyundai', 'Sonata', year: 2015, price: 7800000, km: 110000, fuel: 'lpg', gen: 'LF'),
    _car(5, 'Hyundai', 'Sonata', year: 2014, price: 8100000, km: 150000, fuel: 'diesel', gen: 'LF'),
    _car(6, 'Hyundai', 'Sonata', year: 2013, price: 6000000, km: 170000, status: 'sold', gen: 'YF'),
    _car(7, 'Kia', 'K5', year: 2017, price: 9900000, km: 60000, fuel: 'hybrid'),
    _car(8, 'Genesis', 'G80', year: 2018, km: 70000),
  ];

  List<Car> _of(Iterable<Map<String, Object?>> json) => [for (final c in json) Car.fromJson(c)!];

  void _online(String call) {
    asked.add(call);
    if (fail) throw const CarsException('offline');
  }

  @override
  Future<List<CarBrand>> catalog() async {
    _online('catalog');
    return [
      for (final b in ['Hyundai', 'Kia', 'Genesis'])
        CarBrand(brand: b, total: cars.where((c) => c['brand'] == b).length, models: [
          for (final m in {for (final c in cars) if (c['brand'] == b) c['model'] as String})
            (model: m, count: cars.where((c) => c['model'] == m).length),
        ]),
    ];
  }

  @override
  Future<List<Car>> model(String brand, String? model) async {
    _online('model $brand ${model ?? '*'}');
    return _of(cars.where((c) => c['brand'] == brand && (model == null || c['model'] == model)));
  }

  @override
  Future<({List<Car> cars, int count})> search(CarQuery query) async {
    final q = query.params;
    _online('search ${q.entries.map((e) => '${e.key}=${e.value}').join('&')}');
    final found = _of(cars.where((c) =>
        (q['brand'] == null || c['brand'] == q['brand']) &&
        (q['model'] == null || c['model'] == q['model']) &&
        (q['price_max'] == null || ((c['price_krw'] as int?) ?? 0) <= int.parse(q['price_max']!)) &&
        (q['fuel'] == null || q['fuel']!.split(',').contains(c['fuel'])) &&
        (q['status'] == null || c['status'] == q['status'])));
    return (cars: found, count: found.length);
  }

  @override
  Future<Car> car(int id) async {
    _online('car $id');
    final json = cars.firstWhere((c) => c['id'] == id);
    return Car.fromJson({
      ...json,
      'media': [
        {'type': 'photo', 'url': '/media/cars/$id/1.jpg', 'thumb': '/media/cars/$id/t.jpg'},
        {'type': 'video', 'url': '/media/cars/$id/v.mp4', 'thumb': '/media/cars/$id/vt.jpg', 'size_bytes': 5242880},
      ],
      'raw_text': 'Sotiladi ${json['brand']} ${json['model']} ${json['year']}\nNarxi: ${json['price_krw']}\nTel: 010-1234-5678',
      'contact': id == 1 ? '010-1234-5678' : null,
      'contact_handle': id == 2 ? '@sonata_seller' : null,
      'legal_status': 'legal',
      'registration_required': true,
      'source_name': 'Vegukin Avto',
      'views': 12,
    })!;
  }

  @override
  Future<int?> view(int id) async {
    views.add(id);
    return 13;
  }

  // ---- with the account

  /// Saved on the server; alerts; one's posts.
  final favorites = <int>{};
  final alertList = <CarAlert>[];
  final own = <Map<String, Object?>>[];
  final uploads = <(int, String, bool)>[];
  List<CarDuplicate> dupes = const [];
  int _nextAlert = 1, _nextPost = 100;

  void _account(Map<String, String> auth, {bool signIn = false}) {
    if (auth.isEmpty) throw const CarsException('no_session', 401);
    if (signIn && !signedIn) throw const CarsException('sign_in_required', 401);
  }

  /// Whether the account is signed in, as the server sees it.
  bool signedIn = false;

  @override
  Future<Set<int>> favoriteIds(Map<String, String> auth) async {
    _online('favorites');
    _account(auth);
    return {...favorites};
  }

  @override
  Future<void> setFavorite(Map<String, String> auth, int id, {required bool on}) async {
    _online('favorite $id $on');
    _account(auth);
    on ? favorites.add(id) : favorites.remove(id);
  }

  @override
  Future<List<CarAlert>> alerts(Map<String, String> auth) async {
    _online('alerts');
    _account(auth, signIn: true);
    return [...alertList];
  }

  @override
  Future<CarAlert> addAlert(Map<String, String> auth, CarQuery query) async {
    _online('alert ${query.params.entries.map((e) => '${e.key}=${e.value}').join('&')}');
    _account(auth, signIn: true);
    if (query.params.isEmpty) throw const CarsException('validation_failed', 422);
    final alert = CarAlert(
        id: _nextAlert++, brand: query.pick?.brand, model: query.pick?.model, priceMax: query.priceMax, fuels: [...query.fuels]);
    alertList.insert(0, alert);
    return alert;
  }

  @override
  Future<void> deleteAlert(Map<String, String> auth, int id) async {
    _online('unalert $id');
    alertList.removeWhere((a) => a.id == id);
  }

  @override
  Future<List<OwnCar>> ownCars(Map<String, String> auth) async {
    _online('own');
    _account(auth, signIn: true);
    return [for (final c in own.reversed) OwnCar.fromJson(c)!];
  }

  @override
  Future<int> createPost(Map<String, String> auth, CarPost post) async {
    _online('post ${post.brand} ${post.model} ${post.year} ${post.priceKrw} ${post.phone}');
    _account(auth, signIn: true);
    own.add({...post.toJson(), 'id': _nextPost, 'moderation_status': 'draft', 'status': 'active', 'raw_text': post.description});
    return _nextPost++;
  }

  @override
  Future<void> editPost(Map<String, String> auth, int id, CarPost post) async {
    _online('edit $id ${post.priceKrw}');
    final i = own.indexWhere((c) => c['id'] == id);
    own[i] = {...own[i], ...post.toJson()};
  }

  @override
  Future<void> addMedia(Map<String, String> auth, int id, List<int> bytes, String name, {required bool video, required int order}) async {
    _online('media $id $name');
    uploads.add((id, name, video));
  }

  @override
  Future<List<CarDuplicate>> duplicates(Map<String, String> auth, CarPost post, {int? except}) async {
    _online('dupes');
    return dupes;
  }

  @override
  Future<void> submitPost(Map<String, String> auth, int id) async {
    _online('submit $id');
    final i = own.indexWhere((c) => c['id'] == id);
    own[i] = {...own[i], 'moderation_status': 'pending'};
  }

  @override
  Future<void> markSold(Map<String, String> auth, int id) async {
    _online('sold $id');
    final i = own.indexWhere((c) => c['id'] == id);
    own[i] = {...own[i], 'status': 'sold'};
  }

  @override
  Future<void> withdrawPost(Map<String, String> auth, int id) async {
    _online('withdraw $id');
    own.removeWhere((c) => c['id'] == id);
  }
}


/// The housing board: three posts (one with a phone, one with Telegram, one
/// with neither); an address in Ansan found.
class FakeHousing implements HousingSource {
  bool fail = false;
  bool signedIn = false;
  final asked = <String>[];
  final alertList = <HousingAlert>[];
  int _next = 10;

  final board = <Map<String, Object?>>[
    {'id': 1, 'address_display': '경기도 안산시 단원구 원곡동 123', 'body': 'Ikki kishilik xona, oyiga 450,000 won. Tel: 010-1234-5678', 'contact': '01012345678',
     'posted_rel_uz': '2 soat oldin', 'is_new': true, 'lat': 37.33, 'lon': 126.81},
    {'id': 2, 'address_display': '서울특별시 관악구 신림동 5', 'body': 'Yotoqxonada joy bor, depozitsiz. Telegramga yozing.', 'telegram_username': 'xonador',
     'posted_rel_uz': '3 kun oldin', 'lat': 37.48, 'lon': 126.93},
    {'id': 3, 'address_display': '부산광역시 사하구 1', 'body': 'Kontrakt o‘tkaziladi, avgustgacha. Batafsil kelib ko‘ring.', 'posted_rel_uz': '1 oy oldin',
     'lat': 35.1, 'lon': 128.97},
  ];

  void _online(String call, [Map<String, String>? auth, bool signIn = false]) {
    asked.add(call);
    if (fail) throw const HousingException('offline');
    if (auth != null && auth.isEmpty) throw const HousingException('no_session', status: 401);
    if (signIn && !signedIn) throw const HousingException('sign_in_required', status: 401);
  }

  Map<String, Object?> _list(Map<String, Object?> p, {double? km}) => {
        ...p,
        'body_preview': (p['body'] as String).replaceAll(RegExp(r'\d[\d-]{8,}\d'), '•••'),
        'has_contact': p['contact'] != null,
        'has_telegram': p['telegram_username'] != null,
        'distance_km': ?km,
      };

  @override
  Future<HousingPage> posts({String? cursor, double? lat, double? lon}) async {
    _online('posts ${lat == null ? 'recent' : 'near'}');
    final live = board.where((p) => p['status'] != 'deleted').toList();
    if (lat == null) return (posts: [for (final p in live.reversed.toList().reversed) HousingPost.fromJson(_list(p))!], next: null);
    final near = [for (final p in live) (p, ((p['lat'] as double) - lat).abs() * 111)]..sort((a, b) => a.$2.compareTo(b.$2));
    return (posts: [for (final (p, km) in near) HousingPost.fromJson(_list(p, km: km))!], next: null);
  }

  @override
  Future<HousingPost> post(Map<String, String> auth, int id) async {
    _online('post $id', auth);
    final p = board.firstWhere((p) => p['id'] == id, orElse: () => throw const HousingException('not_found', status: 404));
    return HousingPost.fromJson(p, full: true)!;
  }

  @override
  Future<List<HousingPost>> mine(Map<String, String> auth) async {
    _online('mine', auth, true);
    return [for (final p in board.reversed) if (p['is_mine'] == true && p['status'] != 'deleted') HousingPost.fromJson(p, full: true)!];
  }

  @override
  Future<({double lat, double lon, String name})> geocode(Map<String, String> auth, String address) async {
    _online('geocode $address', auth);
    if (!address.contains('안산')) throw const HousingException('geocode_failed', status: 422);
    return (lat: 37.32, lon: 126.82, name: '경기 안산시 단원구 $address');
  }

  @override
  Future<HousingPost> create(Map<String, String> auth, HousingDraft d) async {
    _online('create ${d.address} ${d.contact} ${d.showUsername ? d.username : '-'}', auth, true);
    final post = {'id': _next++, 'address_display': d.address, 'body': d.body, 'contact': d.contact.isEmpty ? null : d.contact,
      'telegram_username': d.showUsername ? d.username : null, 'show_username': d.showUsername, 'contact_username': d.username,
      'posted_rel_uz': 'hozirgina', 'is_new': true, 'is_mine': true, 'status': 'active', 'days_left': 30, 'lat': 37.3};
    board.add(post);
    return HousingPost.fromJson(post, full: true)!;
  }

  @override
  Future<HousingPost> edit(Map<String, String> auth, int id, HousingDraft d) async {
    _online('edit $id', auth, true);
    final i = board.indexWhere((p) => p['id'] == id);
    board[i] = {...board[i], 'body': d.body, 'contact': d.contact};
    return HousingPost.fromJson(board[i], full: true)!;
  }

  @override
  Future<void> delete(Map<String, String> auth, int id) async {
    _online('delete $id', auth, true);
    final i = board.indexWhere((p) => p['id'] == id);
    board[i] = {...board[i], 'status': 'deleted'};
  }

  @override
  Future<int> extend(Map<String, String> auth, int id) async {
    _online('extend $id', auth, true);
    return 30;
  }

  @override
  Future<List<HousingAlert>> alerts(Map<String, String> auth) async {
    _online('alerts', auth, true);
    return [...alertList];
  }

  @override
  Future<void> addAlert(Map<String, String> auth, String address, int radiusKm) async {
    _online('alert $address $radiusKm', auth, true);
    alertList.add(HousingAlert(id: _next++, address: '경기 안산시 단원구 $address', radiusKm: radiusKm));
  }

  @override
  Future<void> deleteAlert(Map<String, String> auth, int id) async {
    _online('unalert $id', auth, true);
    alertList.removeWhere((a) => a.id == id);
  }

  @override
  Future<String?> username(Map<String, String> auth) async => signedIn ? 'ali_uz' : null;
}

/// The job group: links handed out, and one's posts (one open, one taken an
/// hour before the test's clock).
class FakeJobs implements JobsSource {
  bool fail = false;
  final asked = <String>[];
  final sent = <Map<String, Object?>>[];
  int _next = 3;

  final mine = <Map<String, Object?>>[
    {'id': 1, 'message': 'Zavodga 2 kishi kerak, Ansan, kunlik 120,000 won', 'contact': '010-1111-2222', 'status': 'available',
     'commission': true, 'created_at': kst(const Duration(hours: 2))},
    {'id': 2, 'message': 'Qurilishga ishchi kerak, Hwaseong, bir haftaga', 'contact': '@ishchi', 'status': 'reserved',
     'commission': false, 'created_at': kst(const Duration(days: 1)), 'reserved_at': kst(const Duration(hours: 1))},
  ];

  void _online(String call, Map<String, String> auth) {
    asked.add(call);
    if (fail) throw const JobsException('offline');
    if (auth.isEmpty) throw const JobsException('http_401');
  }

  /// The server's way of writing a time [before] the test's clock: Korean time.
  static String kst(Duration before) =>
      testNow.toUtc().subtract(before).add(const Duration(hours: 9)).toIso8601String().substring(0, 19).replaceFirst('T', ' ');

  Map<String, Object?> _post(String id) => mine.firstWhere((p) => '${p['id']}' == id);

  @override
  Future<String> invite(Map<String, String> auth, int user) async {
    _online('invite', auth);
    return 'https://t.me/+test$user';
  }

  @override
  Future<List<JobPost>> posts(Map<String, String> auth, int user) async {
    _online('posts', auth);
    return [for (final p in mine.reversed) JobPost.fromJson(p)!];
  }

  @override
  Future<void> create(Map<String, String> auth, int user, {required String name, required String text, required String contact, required bool commission}) async {
    _online('create', auth);
    final post = {'id': _next++, 'message': text, 'contact': contact, 'status': 'available', 'commission': commission, 'created_at': kst(Duration.zero)};
    sent.add(post);
    mine.add(post);
  }

  @override
  Future<void> edit(Map<String, String> auth, int user, String id, {required String text, required String contact, required bool commission}) async {
    _online('edit $id', auth);
    _post(id).addAll({'message': text, 'contact': contact, 'commission': commission});
  }

  @override
  Future<void> setStatus(Map<String, String> auth, int user, String id, JobStatus status) async {
    _online('status $id ${status.name}', auth);
    _post(id)['status'] = status.name;
  }

  @override
  Future<void> delete(Map<String, String> auth, int user, String id) async {
    _online('delete $id', auth);
    mine.removeWhere((p) => '${p['id']}' == id);
  }
}
