import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../prayers/prayers_screen.dart';
import '../../core/account.dart';
import '../account/account_screen.dart';
import '../account/inbox_screen.dart';
import '../parcel/parcel_controller.dart';
import 'feature_catalog.dart';
import 'prayer_card.dart';
import 'sections.dart';

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
  late Future<int?> _visits = widget.services.todayVisits();

  /// When the app went to the background: back after half an hour or more
  /// is a new visit, as the server counts them.
  DateTime? _away;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _services.activity.log('open');
    // First launch: location, camera and "Alarms & reminders", asked once,
    // over the home screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Someone who uses the parcel page: its lists are fetched behind the
      // home screen, so the page opens fresh even on a slow line.
      unawaited(warmParcels(_services.parcels, _services.store, clock: _services.clock));
      await _services.permissions.askOnce();
      unawaited(_services.account.startPush());
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
    _services.activity.log('prayers');
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
    if (state == AppLifecycleState.paused) _away ??= DateTime.now();
    if (state == AppLifecycleState.resumed) {
      if (_away case final away? when DateTime.now().difference(away) >= const Duration(minutes: 30)) {
        _services.activity.log('open');
      }
      _away = null;
      setState(() {
        _visits = _services.todayVisits();
      });
      _services.prayer.refresh();
      _services.reminders.checkNotifications();
      _services.account.refreshInbox();
      _services.account.recheckPush();
      _takeWidgetAction();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _stats = _services.businessStats();
      _visits = _services.todayVisits();
    });
    await Future.wait([_services.prayer.refresh(), _stats, _visits]);
  }

  void _open(Feature feature) => openSection(context, feature, _services);

  /// From the header's menu; the full page is for the first launch only.
  void _chooseLanguage(AppLanguage language) {
    HapticFeedback.selectionClick();
    if (language != _services.locale.language) unawaited(_services.locale.choose(language));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final language = _services.locale.language ?? AppLanguage.uz;
    final features = featuresFor(language);
    final scaler = MediaQuery.textScalerOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              language: language,
              account: _services.account,
              onInbox: () => openInbox(context, _services),
              onAccount: () => openAccount(context, _services),
              onLanguage: _chooseLanguage,
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
                          if (showsBusiness(language)) ...[
                            FutureBuilder(
                              future: _stats,
                              builder: (context, snapshot) => _BusinessBand(
                                stats: snapshot.data,
                                onTap: () => _open(businessFeature),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      sliver: SliverGrid.builder(
                        itemCount: features.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          // Exactly the emoji and two lines of label at the
                          // user's text size (both grow with it), so a
                          // one-line label leaves no tall gap below it.
                          mainAxisExtent: _FeatureTile.height(scaler),
                        ),
                        itemBuilder: (context, i) {
                          final feature = features[i];
                          return _FeatureTile(
                            emoji: feature.emoji,
                            label: feature.label(s),
                            isNew: feature.isNew,
                            onTap: () => _open(feature),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(14, 18, 14, 18 + MediaQuery.paddingOf(context).bottom),
                      sliver: SliverToBoxAdapter(
                        child: FutureBuilder(
                          future: _visits,
                          builder: (context, snapshot) => snapshot.data == null
                              ? const SizedBox.shrink()
                              : _TodayVisits(count: snapshot.data!, locale: language.code),
                        ),
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

/// Today's visits to the whole project, with a blue dot that beats: alive.
class _TodayVisits extends StatefulWidget {
  const _TodayVisits({required this.count, required this.locale});

  final int count;
  final String locale;

  @override
  State<_TodayVisits> createState() => _TodayVisitsState();
}

class _TodayVisitsState extends State<_TodayVisits> with SingleTickerProviderStateMixin {
  late final _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    const blue = Color(0xFF2F80ED);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: AnimatedBuilder(
            animation: _beat,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 8 + 10 * _beat.value,
                  height: 8 + 10 * _beat.value,
                  decoration: BoxDecoration(color: blue.withValues(alpha: 0.35 * (1 - _beat.value)), shape: BoxShape.circle),
                ),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: blue, shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppLocalizations.of(context).homeVisitsToday(NumberFormat.decimalPattern(widget.locale).format(widget.count)),
            style: TextStyle(fontSize: 13, color: p.inkMuted),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.language,
    required this.account,
    required this.onInbox,
    required this.onAccount,
    required this.onLanguage,
    required this.onTheme,
  });

  final AppLanguage language;
  final AccountController account;
  final VoidCallback onInbox;
  final VoidCallback onAccount;
  final ValueChanged<AppLanguage> onLanguage;

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
              // On a narrow phone the name takes two lines rather than
              // losing its end.
              const Expanded(
                child: Text(
                  'Muslim Vegukin',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Brand.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.05,
                    color: Colors.white,
                  ),
                ),
              ),
              _InboxButton(account: account, onTap: onInbox),
              // Who the app is signed in as, at a glance: their photo or initials.
              IconButton(
                onPressed: onAccount,
                tooltip: s.accountTitle,
                visualDensity: VisualDensity.compact,
                icon: ListenableBuilder(
                  listenable: account,
                  builder: (context, _) => account.signedIn
                      ? AccountAvatar(account: account, size: 28, onDark: true)
                      : const Icon(Icons.account_circle_outlined, color: Colors.white),
                ),
              ),
              _ThemeButton(onTap: onTheme),
              const SizedBox(width: 8),
              _LanguageMenu(current: language, onSelected: onLanguage, tooltip: s.changeLanguage),
            ],
          ),
        ),
      ),
    );
  }
}

/// The header's language button: a menu of the languages, each with its flag
/// and its own name, the current one ticked.
class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.current, required this.onSelected, required this.tooltip});

  final AppLanguage current;
  final ValueChanged<AppLanguage> onSelected;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
      ),
      menuChildren: [
        for (final language in AppLanguage.values)
          MenuItemButton(
            onPressed: () => onSelected(language),
            style: MenuItemButton.styleFrom(
              minimumSize: const Size(200, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: language == current ? p.cardSelected : null,
            ),
            leadingIcon: Text(language.flag, style: const TextStyle(fontSize: 22)),
            trailingIcon: language == current ? Icon(Icons.check_rounded, size: 20, color: p.accent) : null,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Text(
                language.nativeName,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: language == current ? FontWeight.w800 : FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ),
          ),
      ],
      builder: (context, menu, _) => Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            menu.isOpen ? menu.close() : menu.open();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // An icon's size whatever the text size, as the icon it replaces.
              Text(current.flag, textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(current.code.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
  const _BusinessBand({required this.stats, required this.onTap});

  final BusinessStats? stats;
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

    // The badge sits on the band's top edge, so the title keeps the full width.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        band,
        Positioned(top: -8, right: 16, child: _NewBadge(label: s.newBadge)),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.emoji,
    required this.label,
    required this.isNew,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isNew;
  final VoidCallback onTap;

  static const _top = 14.0;
  static const _gap = 6.0;
  static const _bottom = 10.0;
  static const _emoji = TextStyle(fontSize: 31, height: 1.15);
  static const _labelSize = 12.5;
  static const _labelHeight = 1.25;

  bool get _oneWord => !label.contains(' ') && !label.contains('-');

  TextStyle _labelStyle(VegukinPalette p) =>
      TextStyle(fontSize: _labelSize, height: _labelHeight, fontWeight: FontWeight.w600, color: p.ink);

  /// A tile's height: padding, the emoji and room for two lines of label.
  static double height(TextScaler scaler) =>
      _top + scaler.scale(_emoji.fontSize!) * _emoji.height! + _gap + scaler.scale(_labelSize) * _labelHeight * 2 + _bottom + 1;

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
                padding: const EdgeInsets.fromLTRB(6, _top, 6, _bottom),
                child: Column(
                  children: [
                    Text(emoji, style: _emoji),
                    const SizedBox(height: _gap),
                    // The two lines' room, a one-line label in its middle:
                    // the emojis of a row stay level and no tile has a
                    // gap at its foot.
                    Expanded(
                      child: Center(
                        child: _oneWord
                            // A single long word with large text: a touch
                            // smaller rather than split ("Bildirishnomala / r").
                            ? FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: _labelStyle(p)))
                            : Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _labelStyle(p),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isNew) Positioned(top: 6, right: 6, child: _NewBadge(label: s.newBadge)),
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

/// The sun at night, the moon by day: what a tap switches to.
/// The inbox, with how many alerts came since it was last opened.
class _InboxButton extends StatelessWidget {
  const _InboxButton({required this.account, required this.onTap});

  final AccountController account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final unread = account.unread;
        return Semantics(
          label: unread > 0 ? s.inboxUnread(unread) : null,
          child: IconButton(
            onPressed: onTap,
            tooltip: s.inboxTitle,
            visualDensity: VisualDensity.compact,
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              backgroundColor: Brand.gold300,
              textColor: const Color(0xFF3D2C05),
              child: Icon(
                unread > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

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
