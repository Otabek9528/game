// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline => 'For Muslims in Korea';

  @override
  String get greetingLabel => 'Peace be upon you';

  @override
  String get languageQuestion => 'Which language suits you?';

  @override
  String get languageNote => 'Some sections are in Uzbek only for now';

  @override
  String get continueAction => 'Continue';

  @override
  String get saveAction => 'Save';

  @override
  String get changeLaterHint => 'You can change this later in Settings';

  @override
  String get homeTitle => 'Home';

  @override
  String get homePlaceholder => 'The home screen is the next step.';

  @override
  String get changeLanguage => 'Change language';
}
