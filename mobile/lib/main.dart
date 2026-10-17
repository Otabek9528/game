import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'app_services.dart';
import 'core/key_value_store.dart';
import 'core/locale_controller.dart';
import 'features/prayer/prayer_controller.dart';
import 'features/prayer/prayer_sources.dart';
import 'features/web/web_feature_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the status and navigation bars; screens pad themselves.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // The bundled fonts' licence, shown on Flutter's licences page.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Playfair Display', 'Amiri'], text);
  });

  // Weekday and month names for the dates on the prayer card.
  await initializeDateFormatting();

  final store = await PrefsKeyValueStore.open();
  final prayer = PrayerController(
    location: DeviceLocationSource(),
    times: AladhanSource(),
    store: store,
  );
  final services = AppServices(
    locale: LocaleController(await PrefsLanguageStore.open()),
    prayer: prayer,
    openFeature: openWebFeature,
  );

  // Fills the prayer card from the saved day straight away. It never asks for
  // permission on its own; that waits for the user to tap the card's button.
  prayer.start();

  runApp(VegukinApp(
    services: services,
    deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
  ));
}
