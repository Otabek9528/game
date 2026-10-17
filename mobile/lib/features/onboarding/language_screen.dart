import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_language.dart';
import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';

/// First screen on a fresh install, and the language setting later on.
///
/// Nobody has chosen a language yet, so nothing on this screen may assume one:
/// the greeting is Arabic, which every user of the app reads, the label above
/// the list is in all three languages, and each option is described in its
/// own language. Everything else follows the highlighted option as it
/// changes, so the user sees the app speak their language before they commit.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({
    super.key,
    required this.controller,
    required this.initialLanguage,
    this.isOnboarding = true,
  });

  final LocaleController controller;

  /// Highlighted when the screen opens: the saved choice, or a guess from the
  /// phone's settings on first launch.
  final AppLanguage initialLanguage;

  /// First launch: continues to the home screen.
  /// From settings: saves and goes back.
  final bool isOnboarding;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

/// Not translated on purpose: it has to make sense before a language exists.
const _trilingualLabel = 'TIL · ЯЗЫК · LANGUAGE';

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  late AppLanguage _selected = widget.initialLanguage;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _introStarted = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introStarted) return;
    _introStarted = true;
    // Respect the system "remove animations" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _select(AppLanguage language) {
    if (language == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = language);
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    await widget.controller.choose(_selected);
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (!widget.isOnboarding) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => HomeScreen(controller: widget.controller),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  /// Fades and lifts [child] in during the [begin]–[end] part of the intro.
  Widget _reveal(double begin, double end, Widget child, {double lift = 16}) {
    final curve = CurvedAnimation(
      parent: _intro,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, lift * (1 - curve.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = VegukinPalette.of(context);
    final s = lookupAppLocalizations(_selected.locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.page,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Short screens (older and smaller phones) get a one-row header,
            // so all three options and the button fit without scrolling.
            final compact = constraints.maxHeight < 700;
            final heroHeight = compact
                ? 0.0
                : (constraints.maxHeight * 0.42).clamp(300.0, 380.0);
            // Fills the screen when it fits; scrolls with very large text
            // instead of overflowing.
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: heroHeight),
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Runs on under the panel, so the panel's rounded
                            // top corners show emerald behind them.
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: -40,
                              child: _HeroBackground(palette: palette),
                            ),
                            compact
                                ? _buildCompactHero(context, s, palette)
                                : _buildHero(context, s, palette),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildPanel(context, s, palette, compact),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The mark grows in with a slight overshoot as the screen opens.
  Widget _animatedMark(VegukinPalette palette, {required double size}) {
    final grow = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    return ScaleTransition(
      scale: Tween(begin: 0.6, end: 1.0).animate(grow),
      child: FadeTransition(
        opacity: grow,
        child: KhatamRosette(
          size: size * 2.6,
          color: palette.goldSoft.withValues(alpha: 0.16),
          child: KhatamMark(size: size),
        ),
      ),
    );
  }

  Widget _greeting(AppLocalizations s, VegukinPalette palette, double size) {
    return Text(
      'السلام عليكم',
      textDirection: TextDirection.rtl,
      semanticsLabel: s.greetingLabel,
      style: TextStyle(
        fontFamily: Brand.arabicFont,
        fontWeight: FontWeight.w700,
        fontSize: size,
        height: 1.3,
        color: palette.goldSoft,
      ),
    );
  }

  Widget _appName(double size) {
    return Text(
      'Muslim Vegukin',
      style: TextStyle(
        fontFamily: Brand.displayFont,
        fontWeight: FontWeight.w700,
        fontSize: size,
        height: 1.15,
        color: Colors.white,
      ),
    );
  }

  Widget _tagline(AppLocalizations s, double size, TextAlign align) {
    return _Crossfade(
      alignment: align == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      child: Text(
        s.tagline,
        key: ValueKey('tagline-${_selected.code}'),
        textAlign: align,
        style: TextStyle(
          fontSize: size,
          height: 1.35,
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
    );
  }

  Widget _buildHero(
    BuildContext context,
    AppLocalizations s,
    VegukinPalette palette,
  ) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _animatedMark(palette, size: 88),
                  const SizedBox(height: 22),
                  _reveal(0.15, 0.6, _greeting(s, palette, 30)),
                  const SizedBox(height: 10),
                  _reveal(0.25, 0.7, _appName(28)),
                  const SizedBox(height: 6),
                  _reveal(0.3, 0.75, _tagline(s, 14.5, TextAlign.center)),
                ],
              ),
            ),
          ),
          if (!widget.isOnboarding)
            Positioned(top: 4, left: 4, child: _backButton(context)),
        ],
      ),
    );
  }

  Widget _buildCompactHero(
    BuildContext context,
    AppLocalizations s,
    VegukinPalette palette,
  ) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(widget.isOnboarding ? 24 : 4, 18, 20, 30),
        child: Row(
          children: [
            if (!widget.isOnboarding) _backButton(context),
            _animatedMark(palette, size: 60),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reveal(0.15, 0.6, _greeting(s, palette, 22)),
                  _reveal(0.25, 0.7, _appName(23)),
                  const SizedBox(height: 2),
                  _reveal(0.3, 0.75, _tagline(s, 13.5, TextAlign.start)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    AppLocalizations s,
    VegukinPalette palette,
    bool compact,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // The panel itself is opaque from the first frame (the emerald runs on
    // underneath it); only what is on it fades in.
    return Container(
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, compact ? 22 : 26, 20, 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _reveal(
            0.3,
            0.75,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _trilingualLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Crossfade(
                    alignment: Alignment.topLeft,
                    child: Text(
                      s.languageQuestion,
                      key: ValueKey('question-${_selected.code}'),
                      style: compact
                          ? textTheme.headlineSmall?.copyWith(fontSize: 22)
                          : textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          for (final (i, language) in AppLanguage.values.indexed)
            _reveal(
              0.42 + i * 0.08,
              0.82 + i * 0.06,
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LanguageOption(
                  language: language,
                  note: lookupAppLocalizations(language.locale).languageNote,
                  selected: language == _selected,
                  onTap: () => _select(language),
                ),
              ),
            ),
          const Spacer(),
          SizedBox(height: compact ? 8 : 18),
          _reveal(
            0.6,
            1,
            lift: 8,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _saving ? null : _confirm,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: _Crossfade(
                          child: Text(
                            widget.isOnboarding
                                ? s.continueAction
                                : s.saveAction,
                            key: ValueKey('action-${_selected.code}'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        widget.isOnboarding
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (widget.isOnboarding) ...[
                  const SizedBox(height: 12),
                  _Crossfade(
                    child: Text(
                      s.changeLaterHint,
                      key: ValueKey('hint-${_selected.code}'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: palette.inkMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.palette});

  final VegukinPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.hero,
        ),
      ),
      child: CustomPaint(
        painter: KhatamLatticePainter(
          color: palette.goldSoft.withValues(alpha: 0.075),
        ),
      ),
    );
  }
}

/// Swaps text with a short crossfade when its key changes, easing any change
/// in height so the layout below glides instead of jumping.
class _Crossfade extends StatelessWidget {
  const _Crossfade({required this.child, this.alignment = Alignment.center});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: alignment,
          children: [...previous, ?current],
        ),
        child: child,
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    const duration = Duration(milliseconds: 200);
    final radius = BorderRadius.circular(18);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? p.cardSelected : p.card,
          borderRadius: radius,
          border: Border.all(
            color: selected ? p.accent : p.hairline,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D44341E),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: duration,
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? p.action : p.badge,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      language.glyph,
                      style: TextStyle(
                        fontFamily: Brand.displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        height: 1,
                        color: selected ? Colors.white : p.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.nativeName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: p.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _RadioMark(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? p.action : Colors.transparent,
        border: Border.all(
          color: selected ? p.action : p.hairlineStrong,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        scale: selected ? 1 : 0,
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      ),
    );
  }
}
