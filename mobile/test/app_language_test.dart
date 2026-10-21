import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/core/app_language.dart';

void main() {
  group('AppLanguage.guessFrom', () {
    test('picks the first supported language in the phone list', () {
      expect(
        AppLanguage.guessFrom(const [Locale('ko'), Locale('ru'), Locale('en')]),
        AppLanguage.ru,
      );
    });

    test('Uzbek phones get Uzbek, whatever the script', () {
      expect(
        AppLanguage.guessFrom(const [
          Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
        ]),
        AppLanguage.uz,
      );
    });

    test('Central Asian languages fall back to Russian', () {
      for (final code in ['kk', 'ky', 'tg', 'tk']) {
        expect(AppLanguage.guessFrom([Locale(code)]), AppLanguage.ru, reason: code);
      }
    });

    test('English phones get English', () {
      expect(
        AppLanguage.guessFrom(const [Locale('en', 'US')]),
        AppLanguage.en,
      );
    });

    test('anything else gets Uzbek', () {
      expect(AppLanguage.guessFrom(const [Locale('ko', 'KR')]), AppLanguage.uz);
      expect(AppLanguage.guessFrom(const []), AppLanguage.uz);
    });
  });

  test('fromCode round-trips and rejects unknown codes', () {
    for (final language in AppLanguage.values) {
      expect(AppLanguage.fromCode(language.code), language);
    }
    expect(AppLanguage.fromCode('de'), isNull);
    expect(AppLanguage.fromCode(null), isNull);
  });
}
