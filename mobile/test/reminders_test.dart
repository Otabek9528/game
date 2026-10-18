import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/prayer/prayer_models.dart';
import 'package:muslim_vegukin/features/reminders/reminders.dart';
import 'package:muslim_vegukin/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

import 'support/fakes.dart';

void main() {
  final uz = lookupAppLocalizations(const Locale('uz'));
  final en = lookupAppLocalizations(const Locale('en'));
  // Times in the fakes: Imsak 04:50, Fajr 05:00, sunrise 06:30, Dhuhr 12:00,
  // Asr 15:30, Maghrib 18:00, Isha 19:30.
  final today = dayAt(DateTime(2026, 10, 17));
  final tomorrow = dayAt(DateTime(2026, 10, 18));

  group('a slot\'s window', () {
    test('runs to the next time; Isha runs to tomorrow\'s Fajr', () {
      final dhuhr = slotWindow(today, ReminderSlot.dhuhr)!;
      expect(dhuhr.range, (before: 60, after: 209));
      final isha = slotWindow(today, ReminderSlot.isha, nextDay: tomorrow)!;
      expect(isha.end, DateTime(2026, 10, 18, 5, 0));
      expect(isha.range.after, 569);
    });

    test('before never reaches back past the previous time', () {
      // Suhoor ends 10 minutes before Fajr: after is capped at 9.
      expect(slotWindow(today, ReminderSlot.imsak)!.range, (before: 60, after: 9));
      expect(slotWindow(today, ReminderSlot.fajr)!.range, (before: 60, after: 89));
    });

    test('offsets outside the window are pulled back in', () {
      final fajr = slotWindow(today, ReminderSlot.fajr)!;
      expect(fajr.at(300), DateTime(2026, 10, 17, 6, 29));
      expect(fajr.at(-90), DateTime(2026, 10, 17, 4, 0));
    });
  });

  group('the schedule', () {
    test('only reminders that are on and still to come, soonest first', () {
      final settings = ReminderSettings.defaults
          .withReminder(ReminderSlot.dhuhr, const Reminder(mode: ReminderMode.sound, offset: -10))
          .withReminder(ReminderSlot.asr, const Reminder());
      final list = reminderSchedule(
        days: [today, tomorrow],
        settings: settings,
        s: uz,
        city: 'Shirin',
        now: DateTime(2026, 10, 17, 11, 0),
      );
      expect(list.first.at, DateTime(2026, 10, 17, 11, 50));
      expect(list.first.mode, ReminderMode.sound);
      expect(list.where((r) => r.slot == ReminderSlot.asr), isEmpty);
      // Today: Dhuhr, Maghrib, Isha. Tomorrow: Fajr, Dhuhr, Maghrib, Isha.
      expect(list.length, 7);
      expect(list.map((r) => r.id).toSet().length, 7);
    });

    test('texts say what happened and when, in the app\'s language', () {
      final settings = ReminderSettings.defaults
          .withReminder(ReminderSlot.dhuhr, const Reminder(mode: ReminderMode.vibrate, offset: -10))
          .withReminder(ReminderSlot.asr, const Reminder(mode: ReminderMode.silent, offset: 75))
          .withReminder(ReminderSlot.sunrise, const Reminder(mode: ReminderMode.silent));
      List<ScheduledReminder> run(AppLocalizations s) => reminderSchedule(
            days: [today],
            settings: settings,
            s: s,
            city: 'Shirin',
            now: DateTime(2026, 10, 17, 6, 0),
          );
      final texts = {for (final r in run(uz)) r.slot: r.title};
      expect(texts[ReminderSlot.sunrise], 'Quyosh chiqdi — Bomdod vaqti tugadi');
      expect(texts[ReminderSlot.dhuhr], 'Peshin vaqtiga 10 daq qoldi');
      expect(texts[ReminderSlot.asr], 'Asr vaqti kirganiga 1 soat 15 daq bo‘ldi');
      expect(texts[ReminderSlot.maghrib], 'Shom vaqti kirdi');
      final asr = run(en).firstWhere((r) => r.slot == ReminderSlot.asr);
      expect(asr.title, 'Asr began 1 h 15 min ago');
      expect(asr.body, 'Asr: 15:30 – 18:00 · Shirin');
    });

    test('suhoor is skipped in days saved without it', () {
      final old = PrayerDay(
        date: today.date,
        times: today.times,
        hijriDay: 6,
        hijriMonth: 5,
        hijriYear: 1448,
        key: 'k',
      );
      final list = reminderSchedule(
        days: [old],
        settings: const ReminderSettings({ReminderSlot.imsak: Reminder(mode: ReminderMode.sound)}),
        s: uz,
        city: 'Shirin',
        now: DateTime(2026, 10, 17, 0, 0),
      );
      expect(list, isEmpty);
    });
  });

  test('choices survive being saved and read back', () {
    final settings = ReminderSettings.defaults
        .withReminder(ReminderSlot.isha, const Reminder(mode: ReminderMode.sound, offset: 25));
    final back = ReminderSettings.fromJson(settings.toJson());
    for (final slot in ReminderSlot.values) {
      expect(back[slot], settings[slot]);
    }
  });

  test('offsets read as people say them', () {
    expect(offsetText(uz, 0), 'Vaqtida');
    expect(offsetText(uz, -15), '15 daq oldin');
    expect(offsetText(uz, 120), '2 soat keyin');
    expect(offsetText(en, 90), '1 h 30 min after');
  });
}
