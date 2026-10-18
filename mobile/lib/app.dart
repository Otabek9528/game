import 'package:flutter/material.dart';

import 'app_services.dart';
import 'core/app_language.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/language_screen.dart';
import 'l10n/app_localizations.dart';

class VegukinApp extends StatefulWidget {
  const VegukinApp({
    super.key,
    required this.services,
    required this.deviceLocales,
  });

  final AppServices services;

  /// The phone's preferred languages, best first.
  final List<Locale> deviceLocales;

  @override
  State<VegukinApp> createState() => _VegukinAppState();
}

class _VegukinAppState extends State<VegukinApp> {
  late final AppLanguage _guess = AppLanguage.guessFrom(widget.deviceLocales);

  // Decided once at launch. Picking a language later must not swap the root
  // screen out from under the navigator; the language screen navigates on.
  late final bool _needsLanguage = !widget.services.locale.hasChosen;

  @override
  Widget build(BuildContext context) {
    final locale = widget.services.locale;
    final theme = widget.services.theme;
    return ListenableBuilder(
      listenable: Listenable.merge([locale, theme]),
      builder: (context, _) => MaterialApp(
        title: 'Muslim Vegukin',
        debugShowCheckedModeBanner: false,
        theme: VegukinTheme.light,
        darkTheme: VegukinTheme.dark,
        themeMode: theme.mode,
        locale: (locale.language ?? _guess).locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: _needsLanguage
            ? LanguageScreen(services: widget.services, initialLanguage: _guess)
            : HomeScreen(services: widget.services),
      ),
    );
  }
}
