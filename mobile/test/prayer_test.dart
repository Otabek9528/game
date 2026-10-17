import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/prayer/prayer_controller.dart';
import 'package:muslim_vegukin/features/prayer/prayer_models.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';

import 'support/fakes.dart';

void main() {
  final day = dayAt(DateTime(2026, 10, 17));
  DateTime at(int h, int m, [int d = 17]) => DateTime(2026, 10, d, h, m);

  group('PrayerMoment', () {
    test('before Fajr, Isha is still current and Fajr is next', () {
      final m = PrayerMoment.at(day, at(3, 0));
      expect(m.current, Prayer.isha);
      expect(m.next, Prayer.fajr);
      expect(m.nextAt, at(5, 0));
      expect(m.remaining(at(3, 0)), const Duration(hours: 2));
    });

    test('between Fajr and sunrise the countdown runs to sunrise', () {
      final m = PrayerMoment.at(day, at(6, 0));
      expect(m.current, Prayer.fajr);
      expect(m.next, Prayer.sunrise);
      expect(m.progress, closeTo(60 / 90, 1e-9));
    });

    test('exactly on a prayer time, that prayer has begun', () {
      final m = PrayerMoment.at(day, at(12, 0));
      expect(m.current, Prayer.dhuhr);
      expect(m.next, Prayer.asr);
      expect(m.progress, 0);
    });

    test('after Isha, the next Fajr is tomorrow', () {
      final m = PrayerMoment.at(day, at(22, 0));
      expect(m.current, Prayer.isha);
      expect(m.next, Prayer.fajr);
      expect(m.nextAt, at(5, 0, 18));
    });

    test('the day strip fills whole windows plus the current fraction', () {
      final m = PrayerMoment.at(day, at(13, 45)); // halfway through Dhuhr
      expect(m.dayFraction, closeTo((2 + 0.5) / 6, 1e-9));
    });
  });

  group('PrayerDay', () {
    test('reads Aladhan times with or without a time-zone suffix', () {
      final data = {
        'timings': {
          'Fajr': '05:05 (KST)',
          'Sunrise': '06:36',
          'Dhuhr': '12:09',
          'Asr': '15:59',
          'Maghrib': '17:41',
          'Isha': '19:06',
        },
        'date': {
          'hijri': {'day': '06', 'month': {'number': 5, 'en': 'Jumādá al-ūlá'}, 'year': '1448'},
        },
      };
      final parsed = PrayerDay.fromAladhan(data, date: DateTime(2026, 10, 17, 9), key: 'k');
      expect(parsed.date, DateTime(2026, 10, 17));
      expect(parsed.times[Prayer.fajr], at(5, 5));
      expect(parsed.times[Prayer.isha], at(19, 6));
      expect((parsed.hijriDay, parsed.hijriMonth, parsed.hijriYear), (6, 5, 1448));
    });

    test('survives being saved and read back', () {
      final back = PrayerDay.fromJson(jsonDecode(jsonEncode(day.toJson())) as Map<String, dynamic>);
      expect(back.times, day.times);
      expect(back.key, day.key);
    });
  });

  test('unknown prayer settings fall back to MWL + Hanafi, like the web app', () {
    expect(PrayerSettings.fromJson({'method': '9', 'madhab': 'x'}), const PrayerSettings());
    expect(
      PrayerSettings.fromJson({'method': '4', 'madhab': '0'}),
      const PrayerSettings(method: '4', madhab: '0'),
    );
  });

  group('PrayerController', () {
    test('without a location or permission, it waits for the user', () async {
      final app = TestApp(location: FakeLocation(access: LocationAccess.denied));
      await app.prayer.start();
      expect(app.prayer.status, PrayerStatus.needsPermission);
      expect(app.location.requests, 0);
    });

    test('blocked permission and GPS off get their own states', () async {
      final blocked = TestApp(location: FakeLocation(access: LocationAccess.deniedForever));
      await blocked.prayer.start();
      expect(blocked.prayer.status, PrayerStatus.permissionBlocked);

      final off = TestApp(location: FakeLocation(access: LocationAccess.serviceOff));
      await off.prayer.start();
      expect(off.prayer.status, PrayerStatus.locationOff);
    });

    test('the button asks for permission, locates and loads the times', () async {
      final app = TestApp(location: FakeLocation(access: LocationAccess.denied));
      await app.prayer.start();
      await app.prayer.locate(userAsked: true);

      expect(app.location.requests, 1);
      expect(app.prayer.status, PrayerStatus.ready);
      expect(app.prayer.place?.city, 'Ansan');
      expect(app.store.read('location'), isNotNull);
      expect(app.store.read('prayer_day'), isNotNull);
    });

    test('a saved place and day show at once, with no network', () async {
      final first = TestApp();
      await first.prayer.start();
      expect(first.times.calls, 1);

      final second = TestApp(store: first.store);
      await second.prayer.start();
      expect(second.prayer.status, PrayerStatus.ready);
      expect(second.times.calls, 0);
      expect(second.location.fixes, 0);
    });

    test('a saved place older than 6 hours is refreshed in the background', () async {
      final first = TestApp();
      await first.prayer.start();

      final later = TestApp(store: first.store, now: testNow.add(const Duration(hours: 7)));
      await later.prayer.start();
      expect(later.location.fixes, 1);
    });

    test('a small move keeps the saved place, so cached times stay valid', () async {
      final app = TestApp();
      await app.prayer.start();
      final before = app.prayer.place!;
      app.location
        ..lat = before.lat + 0.01 // ~1 km
        ..city = 'Elsewhere';
      await app.prayer.locate(userAsked: true);

      expect(app.prayer.place!.lat, before.lat);
      expect(app.prayer.place!.city, 'Ansan');
      expect(app.location.cityLookups, 1);
      expect(app.times.calls, 1);
    });

    test('times that fail to load say so', () async {
      final app = TestApp(times: FakeTimes()..fail = true);
      await app.prayer.start();
      expect(app.prayer.status, PrayerStatus.timesFailed);
    });

    test('new settings from the web prayers page refetch the times', () async {
      final app = TestApp();
      await app.prayer.start();
      await app.prayer.applySettings(const PrayerSettings(method: '4', madhab: '0'));

      expect(app.times.calls, 2);
      expect(app.times.lastSettings, const PrayerSettings(method: '4', madhab: '0'));
      expect(app.store.read('prayer_settings'), contains('"method":"4"'));
    });
  });
}
