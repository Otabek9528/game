import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/language_screen.dart';
import '../prayers/prayers_screen.dart';
import '../links/links_screen.dart';
import '../parcel/parcel_controller.dart';
import '../parcel/parcel_screen.dart';
import '../support/community_screen.dart';
import '../support/donation_screen.dart';
import '../qibla/qibla_screen.dart';
import 'feature_catalog.dart';
import 'prayer_card.dart';

/// The home screen: prayer card, business directory band, and every section
/// of the app — the same layout as the web app's home page.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<BusinessStats?> _stats = widget.services.businessStats();

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First launch: location, camera and "Alarms & reminders", asked once,
    // over the home screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Someone who uses the parcel page: its lists are fetched behind the
      // home screen, so the page opens fresh even on a slow line.
      unawaited(warmParcels(_services.parcels, _services.store));
      await _services.permissions.askOnce();
      await _takeWidgetAction();
      await _offerExactAlarms();
    });
  }

  /// "Alarms & reminders" has no system dialog: a short explanation, then
  /// its page. Without it the widget's countdown can't switch on the dot.
  Future<void> _offerExactAlarms() async {
    if (!await _services.permissions.shouldOfferExactAlarms() || !mounted) return;
    final s = AppLocalizations.of(context);
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.exactAlarmsTitle),
        content: Text(s.exactAlarmsBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.exactAlarmsLater)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.exactAlarmsAllow)),
        ],
      ),
    );
    if (allow ?? false) await _services.permissions.openExactAlarmSettings();
  }

  /// Opened from a widget's city (refresh it) or a prayer reminder (show
  /// the prayers page).
  Future<void> _takeWidgetAction() async {
    switch (await _services.homeWidget.takeLaunchAction()) {
      case 'refresh_location':
        await _services.prayer.locate(userAsked: true);
      case 'open_prayers':
        if (mounted) _openPrayers();
    }
  }

  void _openPrayers() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PrayersScreen(services: _services)),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background (or from system settings after allowing
    // location): pick up a new day, a stale location or a new permission.
    if (state == AppLifecycleState.resumed) {
      _services.prayer.refresh();
      _services.reminders.checkNotifications();
      _takeWidgetAction();
    }
  }

  Future<void> _refresh() async {
    setState(() => _stats = _services.businessStats());
    await Future.wait([_services.prayer.refresh(), _stats]);
  }

  void _open(Feature feature) {
    HapticFeedback.lightImpact();
    final native = switch (feature.id) {
      // The phone's full sensors and camera.
      'qibla' => (BuildContext _) => QiblaScreen(services: _services),
      'parcel' => (BuildContext _) => ParcelScreen(services: _services),
      'links' => (BuildContext _) => LinksScreen(services: _services),
      'donation' => (BuildContext _) => DonationScreen(services: _services),
      'community' => (BuildContext _) => CommunityScreen(services: _services),
      _ => null,
    };
    if (native != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: native));
      return;
    }
    _services.openFeature(context, feature, _services);
  }

  void _openLanguage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LanguageScreen(
          services: _services,
          initialLanguage: _services.locale.language ?? AppLanguage.uz,
          isOnboarding: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final language = _services.locale.language ?? AppLanguage.uz;
    final showUzTag = language != AppLanguage.uz;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              language: language,
              onLanguage: _openLanguage,
              onTheme: () {
                HapticFeedback.selectionClick();
                _services.theme.toggle(Theme.of(context).brightness);
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: p.accent,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      sliver: SliverList.list(
                        children: [
                          PrayerCard(
                            controller: _services.prayer,
                            language: language,
                            onOpen: _openPrayers,
                          ),
                          const SizedBox(height: 14),
                          FutureBuilder(
                            future: _stats,
                            builder: (context, snapshot) => _BusinessBand(
                              stats: snapshot.data,
                              showUzTag: showUzTag,
                              onTap: () => _open(businessFeature),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        0,
                        14,
                        20 + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverGrid.builder(
                        itemCount: featureGrid.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          // Room for the emoji and two lines of label at
                          // the user's text size (both grow with it).
                          mainAxisExtent: math.max(112, 36 + 68 * textScale),
                        ),
                        itemBuilder: (context, i) {
                          final feature = featureGrid[i];
                          return _FeatureTile(
                            emoji: feature.emoji,
                            label: feature.label(s),
                            isNew: feature.isNew,
                            uzTag: showUzTag && feature.uzbekOnly,
                            onTap: () => _open(feature),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.language, required this.onLanguage, required this.onTheme});

  final AppLanguage language;
  final VoidCallback onLanguage;

  /// Day ↔ night.
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return DecoratedBox(
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
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
          child: Row(
            children: [
              const KhatamMark(size: 38, glow: false),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Muslim Vegukin',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Brand.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              _ThemeButton(onTap: onTheme),
              const SizedBox(width: 8),
              Tooltip(
                message: s.changeLanguage,
                child: TextButton.icon(
                  onPressed: onLanguage,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.translate_rounded, size: 17),
                  label: Text(
                    language.code.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width and gold, so it reads as its own section rather than one more
/// tile in the grid — as on the web.
class _BusinessBand extends StatelessWidget {
  const _BusinessBand({required this.stats, required this.showUzTag, required this.onTap});

  final BusinessStats? stats;
  final bool showUzTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Brand.gold300 : const Color(0xFF6B4E0A);
    final sub = dark ? const Color(0xFFCDB57A) : const Color(0xFF8A6A1F);
    final stats = this.stats;

    final band = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF2E2614), Color(0xFF241D10)]
                : const [Color(0xFFFFF8E1), Color(0xFFFCEBB6)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Brand.gold500.withValues(alpha: dark ? 0.45 : 0.6)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF3A3018) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(businessFeature.emoji, style: const TextStyle(fontSize: 27)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessFeature.label(s),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: Brand.displayFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 18.5,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stats == null
                            ? s.businessTagline
                            : '${s.businessCount(stats.businesses)} · ${s.categoryCount(stats.categories)}',
                        style: TextStyle(fontSize: 13, color: sub),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: ink),
              ],
            ),
          ),
        ),
      ),
    );

    // Badges sit on the band's top edge, so the title keeps the full width.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        band,
        Positioned(
          top: -8,
          right: 16,
          child: Row(
            children: [
              if (showUzTag) ...[
                _UzTag(hint: s.uzOnlyHint, filled: true),
                const SizedBox(width: 5),
              ],
              _NewBadge(label: s.newBadge),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.emoji,
    required this.label,
    required this.isNew,
    required this.uzTag,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isNew;
  final bool uzTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 31, height: 1.15)),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isNew) Positioned(top: 6, right: 6, child: _NewBadge(label: s.newBadge)),
            if (uzTag) Positioned(top: 6, left: 6, child: _UzTag(hint: s.uzOnlyHint)),
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: p.action, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Marks a section whose pages are only in Uzbek, for people using the app
/// in another language.
class _UzTag extends StatelessWidget {
  const _UzTag({required this.hint, this.filled = false});

  final String hint;

  /// Backed with the card colour, for when it sits across a border.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hint,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: filled ? VegukinPalette.of(context).card : null,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Brand.gold500, width: 1.2),
        ),
        child: const Text(
          'UZ',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Brand.gold500,
          ),
        ),
      ),
    );
  }
}

/// The sun at night, the moon by day: what a tap switches to.
class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: dark ? s.themeToDay : s.themeToNight,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.6, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(dark),
                size: 20,
                color: dark ? Brand.gold300 : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
