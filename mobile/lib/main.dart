import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the status and navigation bars; screens pad themselves.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // The bundled fonts' licence, shown on Flutter's licences page.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Playfair Display', 'Amiri'], text);
  });

  final controller = LocaleController(await PrefsLanguageStore.open());

  runApp(VegukinApp(
    controller: controller,
    deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
  ));
}
