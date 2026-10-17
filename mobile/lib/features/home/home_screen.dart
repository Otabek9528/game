import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_language.dart';
import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/language_screen.dart';

/// Placeholder until the real home screen (prayer card + features) is built.
/// For now it proves the chosen language stuck, and lets you change it.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final LocaleController controller;

  void _openLanguage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LanguageScreen(
          controller: controller,
          initialLanguage: controller.language ?? AppLanguage.uz,
          isOnboarding: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final language = controller.language ?? AppLanguage.uz;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: p.hero.sublist(1),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
                  child: Row(
                    children: [
                      const KhatamMark(size: 40, glow: false),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Muslim Vegukin',
                          style: TextStyle(
                            fontFamily: Brand.displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openLanguage(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.translate_rounded, size: 18),
                        label: Text(language.code.toUpperCase()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.homeTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.homePlaceholder,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: p.inkSoft),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => _openLanguage(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.accent,
                          side: BorderSide(color: p.hairlineStrong),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.translate_rounded, size: 18),
                        label: Text(s.changeLanguage),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
