import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/core/app_language.dart';
import 'package:muslim_vegukin/features/prayer/prayer_controller.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';
import 'package:muslim_vegukin/features/widget/home_widget_bridge.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('without a place, the widget is told to open the app', () async {
    final app = TestApp(location: FakeLocation(access: LocationAccess.denied));
    await app.prayer.start();
    final data = widgetPayload(app.prayer, AppLanguage.en);
    expect(data['days'], isNull);
    expect(data['message'], 'Open the app to see prayer times');
    expect(data['brand'], 'Muslim Vegukin');
  });

  test('carries a week of times and labels in the app language', () async {
    final app = TestApp();
    await app.prayer.start();
    final data = widgetPayload(app.prayer, AppLanguage.uz);

    expect(data['city'], 'Ansan');
    expect(data['names'], ['Bomdod', 'Quyosh', 'Peshin', 'Asr', 'Shom', 'Xufton']);
    expect((data['until'] as List)[2], 'PESHINGACHA');
    expect((data['until'] as List)[1], 'BOMDOD TUGASHIGA');

    final days = data['days'] as List;
    expect(days, hasLength(PrayerController.daysAhead));
    final today = days.first as Map<String, dynamic>;
    expect(today['date'], '2026-10-17');
    expect(today['line1'], 'Shanba, 17-oktabr');
    expect(today['line2'], '6-Jumodul avval, 1448');
    expect((today['times'] as List).first, DateTime(2026, 10, 17, 5).millisecondsSinceEpoch);
    expect((days.last as Map)['date'], '2026-10-24');
  });
}
