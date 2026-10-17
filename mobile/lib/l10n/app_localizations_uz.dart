// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get tagline => 'Koreyadagi musulmonlar uchun';

  @override
  String get greetingLabel => 'Assalomu alaykum';

  @override
  String get languageQuestion => 'Qaysi tilda davom etamiz?';

  @override
  String get languageNote => 'Barcha bo‘limlar mavjud';

  @override
  String get continueAction => 'Davom etish';

  @override
  String get saveAction => 'Saqlash';

  @override
  String get changeLaterHint =>
      'Tilni keyinroq sozlamalardan o‘zgartirish mumkin';

  @override
  String get homeTitle => 'Bosh sahifa';

  @override
  String get homePlaceholder => 'Bosh sahifa keyingi bosqichda quriladi.';

  @override
  String get changeLanguage => 'Tilni o‘zgartirish';
}
