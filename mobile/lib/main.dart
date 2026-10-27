import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'app_services.dart';
import 'core/account.dart';
import 'core/activity_log.dart';
import 'core/app_language.dart';
import 'core/google_auth.dart';
import 'core/key_value_store.dart';
import 'core/locale_controller.dart';
import 'core/push.dart';
import 'core/theme_controller.dart';
import 'features/home/sections.dart';
import 'features/prayer/prayer_controller.dart';
import 'features/prayer/prayer_sources.dart';
import 'features/reminders/reminder_controller.dart';
import 'features/widget/home_widget_bridge.dart';
import 'startup_failed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _start();
  } catch (error, stack) {
    // Before the first frame nothing is drawn: without this the phone would
    // stay on the green splash screen, saying nothing.
    debugPrint('Startup failed: $error\n$stack');
    runApp(StartupFailed(error: error));
  }
}

Future<void> _start() async {
  // Draw behind the status and navigation bars; screens pad themselves.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // The bundled fonts' licence, shown on Flutter's licences page.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Playfair Display', 'Amiri'], text);
  });

  // Weekday and month names for the dates on the prayer card.
  await initializeDateFormatting();

  // The phone's saved settings; a storage that never answers is a failure
  // too, said as one, rather than a splash screen forever.
  const wait = Duration(seconds: 10);
  final store = await PrefsKeyValueStore.open().timeout(wait);
  final prayer = PrayerController(location: DeviceLocationSource(), times: AladhanSource(), store: store);
  final locale = LocaleController(await PrefsLanguageStore.open().timeout(wait));
  final homeWidget = HomeWidgetBridge();
  final reminders = ReminderController(store);
  final services = AppServices(
    store: store,
    locale: locale,
    theme: ThemeController(store),
    prayer: prayer,
    permissions: DevicePermissions(store, prayer, homeWidget),
    openFeature: openInBrowser,
    homeWidget: homeWidget,
    reminders: reminders,
    activity: HttpActivityLog(store),
    account: AccountController(
      store: store,
      source: const HttpAccountSource(),
      push: FirebasePushService(),
      google: GoogleSignInAuth(),
      // Before the language is chosen: the one the language screen offers.
      language: () => locale.language ?? AppLanguage.guessFrom(WidgetsBinding.instance.platformDispatcher.locales),
    ),
  );

  // The home-screen widgets and the prayer reminders follow the prayer
  // times, in the app's language; both are refreshed whenever the times,
  // the language or the reminder choices change.
  void publish() {
    final language = locale.language ?? AppLanguage.uz;
    homeWidget.publish(prayer, language);
    reminders.publish(prayer, language);
  }

  prayer.addListener(publish);
  locale.addListener(publish);
  reminders.addListener(publish);

  // Fills the prayer card from the saved days straight away. Permissions are
  // asked once, from the home screen, after the language is chosen.
  prayer.start();

  runApp(VegukinApp(services: services, deviceLocales: WidgetsBinding.instance.platformDispatcher.locales));
}
