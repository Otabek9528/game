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
import 'package:muslim_vegukin/core/theme_controller.dart';
import 'package:muslim_vegukin/features/home/feature_catalog.dart';
import 'package:muslim_vegukin/features/parcel/parcel_models.dart';
import 'package:muslim_vegukin/features/parcel/parcel_source.dart';
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
      parcels: this.parcels,
      openLink: (uri) async => links.add(uri),
      shareText: (text) async => shared.add(text),
      linksScript: () async => linksScript,
      system: system,
      barcodes: barcodes,
      qna: qna,
      businesses: this.businesses,
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

  /// What was pushed to each user id, oldest first.
  final inboxes = <int, List<InboxItem>>{};
  int _alerts = 0;
  int pageSize = 50;

  /// An alert pushed to [userId], as the server keeps it.
  InboxItem alert(int userId, String title, {String body = '', Map<String, String> data = const {}, DateTime? at}) {
    final item = InboxItem(id: ++_alerts, title: title, body: body, data: data, at: at ?? testNow);
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
