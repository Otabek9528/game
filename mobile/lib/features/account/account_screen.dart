import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/account.dart';
import '../../core/app_language.dart';
import '../../core/config.dart';
import '../../core/google_auth.dart';
import '../../core/system.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_logos.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../hikorea/hikorea_kit.dart';
import '../hikorea/hikorea_watches.dart';
import '../home/feature_catalog.dart';
import '../home/sections.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/notify_models.dart';
import '../onboarding/language_screen.dart';
import '../prayers/prayers_screen.dart';
import '../reminders/reminders.dart';
import '../widget/widget_offer.dart';
import 'inbox_screen.dart';
import 'privacy_screen.dart';

void openAccount(BuildContext context, AppServices services) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AccountScreen(services: services)));
}

/// Asks the person to sign in, for something that needs a name (a review,
/// a claim, an announcement). Returns whether they are signed in now.
///
/// [telegramOnly]: a section that works through Telegram (housing, cars,
/// jobs, business); the sheet says so and offers Telegram alone.
Future<bool> askToSignIn(BuildContext context, AppServices services, {bool telegramOnly = false}) async {
  if (services.account.signedIn) return true;
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: VegukinPalette.of(context).card,
    // Scrolls when WhatsApp's steps outgrow a small screen or large text.
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(context).bottom),
      child: SignInPanel(
        services: services,
        telegramOnly: telegramOnly,
        onSignedIn: () => Navigator.pop(context, true),
      ),
    ),
  );
  return done ?? services.account.signedIn;
}

/// The person's page, in the order it is used:
///
/// * who the app is signed in as (or, for a guest, why and how to sign in);
/// * what needs doing, only when something does: notifications off, prayer
///   reminders that would come late;
/// * what reaches them and what they follow: the inbox, places and areas,
///   HiKorea;
/// * how it reaches this phone: notifications, prayer reminders, and a test
///   that says what actually arrived, here and in the Telegram bot;
/// * the app: language, dark mode, sharing it, writing to us;
/// * last and quiet, signing out and deleting the account; the version.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with WidgetsBindingObserver {
  late final HikoreaKit _hikorea = HikoreaKit(widget.services);

  /// The areas and places watched, as last known; refreshed on opening.
  NotifyMe? _notify;

  /// Reminders are on but Android would let them come late.
  bool _alarmsLate = false;

  /// How the app can add the home-screen widget (`pin`, `guide`), if it can.
  String? _widgetOffer;

  AppServices get _services => widget.services;
  AccountController get _account => _services.account;

  /// Prayers with a reminder on.
  int get _reminders => ReminderSlot.values.where((slot) => _services.reminders.settings[slot].isOn).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notify = cachedNotifyMe(_services);
    unawaited(_hikorea.refreshWatches());
    unawaited(_account.refreshInbox());
    unawaited(_recheck());
    unawaited(_refreshNotify());
    unawaited(_services.homeWidget.offer().then((offer) {
      if (mounted) setState(() => _widgetOffer = offer);
    }));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hikorea.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings: notifications or alarms may be on now.
    if (state == AppLifecycleState.resumed) unawaited(_recheck());
  }

  Future<void> _recheck() async {
    await _account.recheckPush();
    final late = _reminders > 0 && await _services.homeWidget.exactAlarmsMissing();
    if (mounted && late != _alarmsLate) setState(() => _alarmsLate = late);
  }

  Future<void> _refreshNotify() async {
    try {
      final me = await _services.places.notifyMe(await _account.headers());
      keepNotifyMe(_services, me);
      if (mounted) setState(() => _notify = me);
    } catch (_) {
      // Offline: the counts kept from before stand.
    }
  }

  Future<void> _openNotifications() async {
    _services.activity.log('notifications');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(services: _services),
        settings: const RouteSettings(name: 'notifications'),
      ),
    );
    if (mounted) setState(() => _notify = cachedNotifyMe(_services));
  }

  String? _watching(AppLocalizations s) {
    final me = _notify;
    if (me == null) return null;
    final parts = [
      if (me.areas.isNotEmpty) s.accountAreas(me.areas.length),
      if (me.watches.isNotEmpty) s.accountPlaces(me.watches.length),
    ];
    return parts.isEmpty ? s.accountNoneYet : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: Text(s.accountTitle),
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_account, _hikorea, _services.locale, _services.theme, _services.reminders]),
        builder: (context, _) {
          final user = _account.user;
          final signedIn = user != null && user.signedIn;
          final pushOff = _account.pushChecked && !_account.pushAllowed;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + MediaQuery.paddingOf(context).bottom),
            children: [
              _ProfileHeader(services: _services),
              if (pushOff)
                _Attention(
                  icon: Icons.notifications_off_rounded,
                  title: s.accountPushOffTitle,
                  body: s.accountPushOff,
                  action: s.accountTurnOn,
                  onAction: _services.reminders.openNotificationSettings,
                ),
              if (_alarmsLate)
                _Attention(
                  icon: Icons.alarm_rounded,
                  title: s.accountAlarmsTitle,
                  body: s.accountAlarmsBody,
                  action: s.accountAllow,
                  onAction: _services.homeWidget.openExactAlarmSettings,
                ),
              _SectionTitle(s.accountMine),
              _RowsCard(
                children: [
                  _NavRow(
                    icon: Icons.inbox_rounded,
                    title: s.inboxTitle,
                    value: _account.unread > 0
                        ? s.inboxUnread(_account.unread)
                        : _account.inbox.isEmpty
                        ? s.accountInboxNone
                        : s.accountInboxAll(_account.inbox.length),
                    highlight: _account.unread > 0,
                    onTap: () => openInbox(context, _services),
                  ),
                  _NavRow(
                    icon: Icons.place_rounded,
                    title: s.accountPlacesWatches,
                    value: _watching(s),
                    onTap: _openNotifications,
                  ),
                  _NavRow(
                    icon: Icons.event_available_rounded,
                    title: s.accountHikoreaWatches,
                    value: switch (_hikorea.watches?.length) {
                      null => null,
                      0 => s.accountNoneYet,
                      final n => s.accountActive(n),
                    },
                    onTap: () => openWatches(context, _hikorea),
                  ),
                ],
              ),
              _SectionTitle(s.accountNotifications),
              _NotificationsCard(services: _services, reminders: _reminders, off: pushOff),
              _SectionTitle(s.accountApp),
              _RowsCard(
                children: [
                  _NavRow(
                    icon: Icons.translate_rounded,
                    title: s.accountLanguage,
                    value: (_services.locale.language ?? AppLanguage.uz).nativeName,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LanguageScreen(
                          services: _services,
                          initialLanguage: _services.locale.language ?? AppLanguage.uz,
                          isOnboarding: false,
                        ),
                      ),
                    ),
                  ),
                  _SwitchRow(
                    icon: Icons.dark_mode_outlined,
                    title: s.accountDarkMode,
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (_) {
                      HapticFeedback.selectionClick();
                      unawaited(_services.theme.toggle(Theme.of(context).brightness));
                    },
                  ),
                  if (_widgetOffer case final offer?)
                    _NavRow(
                      icon: Icons.widgets_outlined,
                      title: s.accountWidget,
                      onTap: () => showAddWidget(context, _services, offer),
                    ),
                  _NavRow(
                    icon: Icons.share_rounded,
                    title: s.accountShare,
                    onTap: () => unawaited(_services.shareText(s.accountShareText(AppConfig.playStoreUrl))),
                  ),
                  _NavRow(
                    icon: Icons.forum_rounded,
                    title: s.accountFeedback,
                    onTap: () => openSection(context, featureGrid.firstWhere((f) => f.id == 'community'), _services),
                  ),
                  _NavRow(
                    icon: Icons.privacy_tip_outlined,
                    title: s.accountPrivacy,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => PrivacyScreen(services: _services))),
                  ),
                ],
              ),
              if (signedIn) ...[_SectionTitle(s.accountManage), _Manage(user: user, services: _services)],
              _Version(system: _services.system),
            ],
          );
        },
      ),
    );
  }
}

/// Something to put right, at the top, only while it needs it.
class _Attention extends StatelessWidget {
  const _Attention({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _amber.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD97706)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3, color: p.ink),
                ),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The app's version, at the very bottom, for when someone asks.
class _Version extends StatefulWidget {
  const _Version({required this.system});

  final SystemBridge system;

  @override
  State<_Version> createState() => _VersionState();
}

class _VersionState extends State<_Version> {
  late final Future<DeviceInfo?> _device = widget.system.device();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return FutureBuilder<DeviceInfo?>(
      future: _device,
      builder: (context, snapshot) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Text(
          ['Muslim Vegukin', if (snapshot.data case final device?) s.accountVersion(device.version)].join(' · '),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: p.inkMuted),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 22, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: p.inkMuted),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.hairline),
      ),
      child: child,
    );
  }
}

String providerName(String? provider) => switch (provider) {
      'google' => 'Google',
      'whatsapp' => 'WhatsApp',
      'telegram' => 'Telegram',
      _ => '',
    };

BrandLogo? providerLogo(String? provider) => switch (provider) {
      'google' => BrandLogo.google,
      'whatsapp' => BrandLogo.whatsapp,
      'telegram' => BrandLogo.telegram,
      _ => null,
    };

/// The person: photo (or initials) and the mark of where they signed in.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.account, this.size = 40, this.badge = false, this.onDark = false});

  final AccountController account;
  final double size;

  /// The provider's mark at the corner.
  final bool badge;

  /// On the green header: a white ring, white initials.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final user = account.user;
    final photo = account.photo;
    final signedIn = user?.signedIn ?? false;
    final name = (user?.name ?? user?.detail ?? '').trim();
    final initials = [for (final word in name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2)) word.characters.first]
        .join()
        .toUpperCase();
    final Widget face;
    if (photo != null) {
      face = Image.memory(photo, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink());
    } else if (signedIn && initials.isNotEmpty) {
      face = Container(
        alignment: Alignment.center,
        color: onDark ? Colors.white.withValues(alpha: 0.18) : p.accent.withValues(alpha: 0.14),
        child: Text(initials,
            style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w800, color: onDark ? Colors.white : p.accent)),
      );
    } else {
      face = Container(
        alignment: Alignment.center,
        color: onDark ? Colors.white.withValues(alpha: 0.18) : p.badge,
        child: Icon(Icons.person_rounded, size: size * 0.62, color: onDark ? Colors.white : p.inkMuted),
      );
    }
    final logo = providerLogo(user?.provider);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: size >= 48 ? 2.5 : 1.5) : null,
            ),
            child: ClipOval(child: SizedBox.square(dimension: size, child: face)),
          ),
          if (badge && signedIn && logo != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                // Telegram's mark is itself a disc: it fills the badge.
                padding: EdgeInsets.all(logo == BrandLogo.telegram ? 0 : size * 0.05),
                decoration: BoxDecoration(
                  color: logo == BrandLogo.telegram ? const Color(0xFF26A5E4) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: onDark ? p.hero.last : p.card, width: 2),
                ),
                child: FittedBox(child: BrandLogoMark(logo)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Who the app is signed in as, on the page's green: or, for a guest, why
/// and how to sign in.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final account = services.account;
    final user = account.user;
    final signedIn = user != null && user.signedIn;
    final name = signedIn ? (user.name ?? user.detail ?? providerName(user.provider)) : s.accountGuest;
    const radius = BorderRadius.all(Radius.circular(24));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero.sublist(1)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(painter: KhatamLatticePainter(color: Colors.white.withValues(alpha: 0.05))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AccountAvatar(account: account, size: 72, badge: true, onDark: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: Brand.displayFont,
                              fontSize: 23,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (signedIn && user.detail != null && user.detail != name) ...[
                            const SizedBox(height: 3),
                            Text(user.detail!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14.5, color: Colors.white.withValues(alpha: 0.85))),
                          ],
                          if (signedIn) ...[
                            const SizedBox(height: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: Text(
                                  s.signedInWith(providerName(user.provider)),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (signedIn && user.provider == 'whatsapp' && account.photo == null) ...[
                  const SizedBox(height: 12),
                  Text(s.accountNoPhoto, style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.75))),
                ],
                if (!signedIn) ...[
                  const SizedBox(height: 14),
                  Text(s.accountGuestBody,
                      style: TextStyle(fontSize: 14, height: 1.45, color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (await askToSignIn(context, services)) {
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(s.signInDone), behavior: SnackBarBehavior.floating));
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Brand.emerald800),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(s.accountSignIn),
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

/// How messages reach this phone: whether notifications show, the prayer
/// reminders, and a test that says what actually arrived (the server only
/// knows it handed it on), here and, for a Telegram account, in the bot.
class _NotificationsCard extends StatefulWidget {
  const _NotificationsCard({required this.services, required this.reminders, required this.off});

  final AppServices services;

  /// Prayers with a reminder on.
  final int reminders;

  /// The phone doesn't show the app's notifications.
  final bool off;

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

/// Where the test is on this phone.
enum _Phone { idle, waiting, arrived, notArrived, away, noToken, serverFailed, offline }

class _NotificationsCardState extends State<_NotificationsCard> with WidgetsBindingObserver {
  /// How long a test may take to arrive before it is said not to have.
  static const _patience = Duration(seconds: 20);

  _Phone _phone = _Phone.idle;
  TestPushResult? _result;
  Timer? _timer;

  /// The app went to the background while waiting: the test may be in the
  /// notification panel, where the app can't see it.
  bool _left = false;

  AccountController get _account => widget.services.account;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _account.addListener(_maybeArrived);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _account.removeListener(_maybeArrived);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_phone != _Phone.waiting) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) _left = true;
    if (state == AppLifecycleState.resumed && _left && _account.testArrivedAt == null) _settle(_Phone.away);
  }

  void _maybeArrived() {
    if (_phone == _Phone.waiting && _account.testArrivedAt != null) _settle(_Phone.arrived);
  }

  void _settle(_Phone phone) {
    _timer?.cancel();
    if (mounted) setState(() => _phone = phone);
  }

  Future<void> _send() async {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _phone = _Phone.waiting;
      _result = null;
      _left = false;
    });
    final TestPushResult result;
    try {
      result = await _account.sendTestPush();
    } on AccountException {
      _settle(_Phone.offline);
      return;
    }
    if (!mounted) return;
    setState(() => _result = result);
    switch (result.push) {
      case 'sent':
        if (_account.testArrivedAt != null) return _settle(_Phone.arrived);
        _timer = Timer(_patience, () => _settle(_left ? _Phone.away : _Phone.notArrived));
      case 'no_token' || 'rejected':
        _settle(_Phone.noToken);
      default:
        _settle(_Phone.serverFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final services = widget.services;
    final telegram = _account.user?.provider == 'telegram';
    final result = _result;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NavRow(
            icon: widget.off ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
            title: s.accountOnPhone,
            value: widget.off ? s.accountOff : s.accountOn,
            pill: widget.off ? _Pill.warn : _Pill.good,
            onTap: services.reminders.openNotificationSettings,
          ),
          Divider(height: 1, thickness: 1, indent: 62, color: p.hairline),
          _NavRow(
            icon: Icons.access_alarm_rounded,
            title: s.accountReminders,
            value: widget.reminders > 0 ? s.accountRemindersCount(widget.reminders) : s.accountOff,
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PrayersScreen(services: services))),
          ),
          if (!widget.off) ...[
            Divider(height: 1, thickness: 1, indent: 62, color: p.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _RowIcon(Icons.send_rounded),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.accountTestTitle,
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              telegram ? s.accountTestToBoth : s.accountTestToPhone,
                              style: TextStyle(fontSize: 13, height: 1.3, color: p.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _phone == _Phone.waiting ? null : _send,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(s.accountTestSend),
                      ),
                    ],
                  ),
                  if (_phone != _Phone.idle) ...[
                    const SizedBox(height: 10),
                    switch (_phone) {
                      _Phone.waiting => _Outcome.waiting(s.accountTestWaiting),
                      _Phone.arrived => _Outcome.good(s.accountTestArrived),
                      _Phone.notArrived => _Outcome.bad(
                        s.accountTestNotArrived,
                        help: s.accountTestNotArrivedHelp,
                        action: s.accountSettings,
                        onAction: services.reminders.openNotificationSettings,
                      ),
                      _Phone.away => _Outcome.info(s.accountTestCheckShade),
                      _Phone.noToken => _Outcome.bad(s.accountTestNoToken),
                      _Phone.serverFailed => _Outcome.bad(s.accountTestServerFailed),
                      _Phone.offline || _Phone.idle => _Outcome.bad(s.accountTestFailed),
                    },
                  ],
                  if (result?.telegram case final bot?) ...[
                    const SizedBox(height: 6),
                    switch (bot) {
                      'sent' => _Outcome.good(s.accountTestBotSent),
                      'blocked' => _Outcome.bad(s.accountTestBotBlocked),
                      _ => _Outcome.bad(s.accountTestBotFailed),
                    },
                    if (result?.bot case final name?)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 40),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => services.openLink(Uri.parse('https://t.me/$name')),
                            icon: const Icon(Icons.telegram, size: 18),
                            label: Text(s.accountOpenBot),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One line of a test's outcome: a mark, what happened, and how to put it right.
class _Outcome extends StatelessWidget {
  const _Outcome.good(this.text) : kind = 0, help = null, action = null, onAction = null;
  const _Outcome.bad(this.text, {this.help, this.action, this.onAction}) : kind = 1;
  const _Outcome.info(this.text) : kind = 2, help = null, action = null, onAction = null;
  const _Outcome.waiting(this.text) : kind = 3, help = null, action = null, onAction = null;

  final String text;
  final int kind;
  final String? help;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final red = Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    final (Widget mark, Color ink) = switch (kind) {
      0 => (Icon(Icons.check_circle_rounded, size: 20, color: p.accent), p.accent),
      1 => (Icon(Icons.error_rounded, size: 20, color: red), red),
      2 => (Icon(Icons.info_rounded, size: 20, color: p.inkSoft), p.inkSoft),
      _ => (const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2)), p.inkSoft),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 34, child: Center(child: mark)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w700, color: ink),
              ),
              if (help != null) ...[
                const SizedBox(height: 3),
                Text(help!, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft)),
              ],
              if (action != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 40)),
                  child: Text(action!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rows in one card, with hairlines between.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.hairline)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 62, color: p.hairline),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 19, color: p.accent),
    );
  }
}

/// How a row's value stands out: news (gold), all well (green), a problem (amber).
enum _Pill { none, news, good, warn }

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    this.value,
    bool highlight = false,
    _Pill pill = _Pill.none,
    required this.onTap,
  }) : pill = highlight ? _Pill.news : pill;

  final IconData icon;
  final String title;

  /// On the right: a count, the current choice; null while loading.
  final String? value;
  final _Pill pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final value = this.value;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            _RowIcon(icon),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink))),
            // At most a third of the row, so the arrows line up.
            if (value != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width / 3),
                child: switch (pill) {
                  _Pill.none => Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 14, color: p.inkMuted),
                  ),
                  _ => DecoratedBox(
                    decoration: BoxDecoration(
                      color: switch (pill) {
                        _Pill.news => Brand.gold300,
                        _Pill.good => p.accent.withValues(alpha: 0.12),
                        _ => const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      },
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: switch (pill) {
                            _Pill.news => const Color(0xFF3D2C05),
                            _Pill.good => p.accent,
                            _ => const Color(0xFFB45309),
                          },
                        ),
                      ),
                    ),
                  ),
                },
              ),
            Icon(Icons.chevron_right_rounded, color: p.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.icon, required this.title, required this.value, required this.onChanged});

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        child: Row(
          children: [
            _RowIcon(icon),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink))),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Signing out and deleting the account: last, and quiet.
class _Manage extends StatelessWidget {
  const _Manage({required this.user, required this.services});

  final AppUser user;
  final AppServices services;

  // The page changes as soon as the account does, so its messages go through
  // the messenger taken beforehand.

  Future<void> _signOut(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await services.account.signOut();
    } on AccountException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.signInFailed)));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.accountDeleteTitle),
        content: Text(user.provider == 'telegram'
            ? '${s.accountDeleteBody} ${s.accountDeleteTelegram}'
            : s.accountDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.signInCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: Text(s.accountDeleteConfirm),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await services.account.deleteAccount();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.accountDeleted)));
    } on AccountException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.signInFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: Text(s.signOut),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _delete(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: Text(s.accountDelete),
          ),
        ],
      ),
    );
  }
}

/// The ways to sign in, and the wait while the person says Yes in a bot.
/// WhatsApp first says what will happen there: the person has to send the
/// typed-in code themselves, which nothing else asks of them.
class SignInPanel extends StatefulWidget {
  const SignInPanel({super.key, required this.services, required this.onSignedIn, this.telegramOnly = false});

  final AppServices services;
  final VoidCallback onSignedIn;
  final bool telegramOnly;

  @override
  State<SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<SignInPanel> with WidgetsBindingObserver {
  /// The provider being signed in with, while it is.
  String? _busy;
  LoginLink? _link;
  String? _linkProvider;
  DateTime? _linkUntil;
  Timer? _poll;
  String? _error;

  /// WhatsApp's steps, shown before it opens.
  bool _whatsappSteps = false;

  AccountController get _account => widget.services.account;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the bot: look straight away instead of at the next tick.
    if (state == AppLifecycleState.resumed && _link != null) _check();
  }

  List<String> get _providers {
    if (widget.telegramOnly) return const ['telegram'];
    final language = widget.services.locale.language ?? AppLanguage.uz;
    // Uzbeks have Telegram; most others use WhatsApp.
    final order = language == AppLanguage.uz ? const ['telegram', 'whatsapp', 'google'] : const ['whatsapp', 'google', 'telegram'];
    return [for (final p in order) if (p != 'google' || googleSignInAvailable) p];
  }

  Future<void> _start(String provider) async {
    final s = AppLocalizations.of(context);
    HapticFeedback.selectionClick();
    setState(() {
      _busy = provider;
      _error = null;
    });
    try {
      if (provider == 'google') {
        final done = await _account.signInWithGoogle();
        if (!mounted) return;
        setState(() => _busy = null);
        if (done) widget.onSignedIn();
        return;
      }
      final link = await _account.startLink(provider);
      if (!mounted) return;
      setState(() {
        _busy = null;
        _whatsappSteps = false;
        _link = link;
        _linkProvider = provider;
        _linkUntil = DateTime.now().add(link.expiresIn);
      });
      _poll = Timer.periodic(const Duration(milliseconds: 2500), (_) => _check());
      await widget.services.openLink(link.url);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = null;
        _whatsappSteps = false;
        _error = s.signInFailed;
      });
    }
  }

  Future<void> _check() async {
    final link = _link;
    if (link == null) return;
    final s = AppLocalizations.of(context);
    if (_linkUntil != null && DateTime.now().isAfter(_linkUntil!)) {
      _stop(s.signInExpired);
      return;
    }
    try {
      final status = await _account.checkLink(link.code);
      if (!mounted || _link != link) return;
      switch (status) {
        case 'done':
          _stop(null);
          widget.onSignedIn();
        case 'expired' || 'cancelled':
          _stop(s.signInExpired);
      }
    } on AccountException {
      // Offline for a moment: the next tick tries again.
    }
  }

  void _stop(String? error) {
    _poll?.cancel();
    _poll = null;
    if (!mounted) return;
    setState(() {
      _link = null;
      _linkProvider = null;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final link = _link;
    if (_whatsappSteps && link == null) return _whatsappIntro(s, p);
    if (link != null) {
      final app = providerName(_linkProvider);
      final whatsapp = _linkProvider == 'whatsapp';
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Center(child: SizedBox.square(dimension: 34, child: CircularProgressIndicator(strokeWidth: 3))),
          const SizedBox(height: 16),
          Text(whatsapp ? s.signInWaWaitingTitle : s.signInWaitingTitle(app),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(height: 6),
          Text(whatsapp ? s.signInWaWaitingBody : s.signInWaitingBody,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => widget.services.openLink(link.url),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(s.signInOpenAgain(app)),
          ),
          TextButton(onPressed: () => _stop(null), child: Text(s.signInCancel)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.signInTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
        const SizedBox(height: 6),
        Text(widget.telegramOnly ? s.signInTelegramNote : s.signInWhy,
            style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
        const SizedBox(height: 16),
        for (final provider in _providers) ...[
          _ProviderButton(
            provider: provider,
            label: switch (provider) {
              'google' => s.signInGoogle,
              'whatsapp' => s.signInWhatsApp,
              _ => s.signInTelegram,
            },
            busy: _busy == provider,
            onTap: _busy != null
                ? null
                : provider == 'whatsapp'
                    ? () => setState(() {
                          _whatsappSteps = true;
                          _error = null;
                        })
                    : () => _start(provider),
          ),
          const SizedBox(height: 10),
        ],
        if (_error != null)
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: Color(0xFFB91C1C))),
      ],
    );
  }

  /// What happens in WhatsApp, before it opens: send the typed-in message,
  /// tap Yes, come back.
  Widget _whatsappIntro(AppLocalizations s, VegukinPalette p) {
    const green = Color(0xFF25D366);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final busy = _busy == 'whatsapp';
    final steps = [s.signInWaStep1, s.signInWaStep2, s.signInWaStep3, s.signInWaStep4];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const BrandLogoMark(BrandLogo.whatsapp, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.signInWaTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final (i, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: green.withValues(alpha: 0.16), shape: BoxShape.circle),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800, color: dark ? green : const Color(0xFF0E7A3F))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(step, style: TextStyle(fontSize: 15, height: 1.35, color: p.ink)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.badge, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: p.inkMuted),
              const SizedBox(width: 10),
              Expanded(child: Text(s.signInWaNote, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Dark text on WhatsApp's green, as its own site has it: white on it
        // is too faint to read.
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: const Color(0xFF111B21)),
          onPressed: busy ? null : () => _start('whatsapp'),
          icon: busy
              ? const SizedBox.square(
                  dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF111B21)))
              : const Icon(Icons.open_in_new_rounded),
          label: Text(s.signInWaOpen),
        ),
        TextButton(
          onPressed: busy ? null : () => setState(() => _whatsappSteps = false),
          child: Text(s.signInBack),
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.provider, required this.label, required this.busy, required this.onTap});

  final String provider;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.hairlineStrong)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // The G fills its square; the other two have air around them.
              SizedBox.square(
                dimension: 26,
                child: Center(child: BrandLogoMark(providerLogo(provider)!, size: provider == 'google' ? 22 : 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.ink)),
              ),
              if (busy) const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
      ),
    );
  }
}
