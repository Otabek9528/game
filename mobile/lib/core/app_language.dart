import 'dart:ui';

/// The languages the app is written in.
///
/// Each one is named in its own language ("Русский", not "Russian"): someone
/// looking for their language scans for the word they know. The first-launch
/// page shows a letter of each script; the home screen's quick menu adds the
/// flag people expect there, next to the name.
enum AppLanguage {
  uz(code: 'uz', nativeName: 'O‘zbekcha', glyph: 'O‘', flag: '🇺🇿'),
  ru(code: 'ru', nativeName: 'Русский', glyph: 'Я', flag: '🇷🇺'),
  en(code: 'en', nativeName: 'English', glyph: 'Aa', flag: '🇬🇧');

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.glyph,
    required this.flag,
  });

  final String code;
  final String nativeName;

  /// A letter that is unmistakably this language's script, used as its icon.
  final String glyph;

  /// As in the home screen's language menu.
  final String flag;

  Locale get locale => Locale(code);

  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// Best guess from the phone's language settings. It only decides which
  /// option starts selected; the user still confirms it.
  ///
  /// Phones set to Kazakh, Kyrgyz, Tajik or Turkmen get Russian, the language
  /// those users most likely read among the three. Anything else (Korean
  /// included — common for people living in Korea) falls back to Uzbek, the
  /// app's main audience.
  static AppLanguage guessFrom(List<Locale> deviceLocales) {
    const russianReaders = {'ru', 'kk', 'ky', 'tg', 'tk', 'be'};
    for (final locale in deviceLocales) {
      final code = locale.languageCode;
      if (code == 'uz') return uz;
      if (russianReaders.contains(code)) return ru;
      if (code == 'en') return en;
    }
    return uz;
  }
}
