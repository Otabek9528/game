import 'package:flutter/material.dart';

import 'core/app_language.dart';
import 'core/locale_controller.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/language_screen.dart';
import 'l10n/app_localizations.dart';

class VegukinApp extends StatefulWidget {
  const VegukinApp({
    super.key,
    required this.controller,
    required this.deviceLocales,
  });

  final LocaleController controller;

  /// The phone's preferred languages, best first.
  final List<Locale> deviceLocales;

  @override
  State<VegukinApp> createState() => _VegukinAppState();
}

class _VegukinAppState extends State<VegukinApp> {
  late final AppLanguage _guess = AppLanguage.guessFrom(widget.deviceLocales);

  // Decided once at launch. Picking a language later must not swap the root
  // screen out from under the navigator; the language screen navigates on.
  late final bool _needsLanguage = !widget.controller.hasChosen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => MaterialApp(
        title: 'Muslim Vegukin',
        debugShowCheckedModeBanner: false,
        theme: VegukinTheme.light,
        darkTheme: VegukinTheme.dark,
        themeMode: ThemeMode.system,
        locale: (widget.controller.language ?? _guess).locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: _needsLanguage
            ? LanguageScreen(
                controller: widget.controller,
                initialLanguage: _guess,
              )
            : HomeScreen(controller: widget.controller),
      ),
    );
  }
}
