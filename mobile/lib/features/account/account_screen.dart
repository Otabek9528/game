import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/account.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../hikorea/hikorea_kit.dart';
import '../hikorea/hikorea_watches.dart';
import '../onboarding/language_screen.dart';
import 'inbox_screen.dart';

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
    builder: (context) => Padding(
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

/// The person's page: who the app is signed in as (with the photo the
/// sign-in brought), whether alerts reach this phone and a way to check,
/// what they have going (inbox, watches), the app's settings, and, last,
/// signing out and deleting the account.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with WidgetsBindingObserver {
  late final HikoreaKit _hikorea = HikoreaKit(widget.services);

  AccountController get _account => widget.services.account;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_hikorea.refreshWatches());
    unawaited(_account.refreshInbox());
    unawaited(_account.recheckPush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hikorea.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings: notifications may be on now.
    if (state == AppLifecycleState.resumed) unawaited(_account.recheckPush());
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
        listenable: Listenable.merge([_account, _hikorea, widget.services.locale, widget.services.theme]),
        builder: (context, _) {
          final user = _account.user;
          final signedIn = user != null && user.signedIn;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
            children: [
              _ProfileHeader(services: widget.services),
              _SectionTitle(s.accountNotifications),
              _NotificationsCard(services: widget.services),
              _SectionTitle(s.accountActivity),
              _RowsCard(children: [
                _NavRow(
                  icon: Icons.inbox_rounded,
                  title: s.inboxTitle,
                  value: _account.unread > 0
                      ? s.inboxUnread(_account.unread)
                      : _account.inbox.isEmpty
                          ? s.accountInboxNone
                          : s.accountInboxAll(_account.inbox.length),
                  highlight: _account.unread > 0,
                  onTap: () => openInbox(context, widget.services),
                ),
                _NavRow(
                  icon: Icons.event_available_rounded,
                  title: s.hkMyWatches,
                  value: switch (_hikorea.watches?.length) {
                    null => null,
                    0 => s.hkWatchesEmpty,
                    final n => s.accountActive(n),
                  },
                  onTap: () => openWatches(context, _hikorea),
                ),
              ]),
              _SectionTitle(s.accountApp),
              _RowsCard(children: [
                _NavRow(
                  icon: Icons.translate_rounded,
                  title: s.accountLanguage,
                  value: (widget.services.locale.language ?? AppLanguage.uz).nativeName,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => LanguageScreen(
                      services: widget.services,
                      initialLanguage: widget.services.locale.language ?? AppLanguage.uz,
                      isOnboarding: false,
                    ),
                  )),
                ),
                _SwitchRow(
                  icon: Icons.dark_mode_outlined,
                  title: s.accountDarkMode,
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (_) {
                    HapticFeedback.selectionClick();
                    unawaited(widget.services.theme.toggle(Theme.of(context).brightness));
                  },
                ),
              ]),
              if (signedIn) ...[
                _SectionTitle(s.accountManage),
                _Manage(user: user, services: widget.services),
              ],
            ],
          );
        },
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
    final mark = switch (user?.provider) {
      'telegram' => (const Color(0xFF229ED9), const Icon(Icons.telegram, color: Colors.white)),
      'whatsapp' => (const Color(0xFF25D366), const Icon(Icons.chat_rounded, color: Colors.white)),
      'google' => (Colors.white, const CustomPaint(painter: _GoogleMark())),
      _ => null,
    };
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
          if (badge && signedIn && mark != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                padding: EdgeInsets.all(size * 0.05),
                decoration: BoxDecoration(
                  color: mark.$1,
                  shape: BoxShape.circle,
                  border: Border.all(color: onDark ? p.hero.last : p.card, width: 2),
                ),
                child: FittedBox(child: SizedBox.square(dimension: 24, child: mark.$2)),
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

/// Whether alerts reach this phone, what they are about, and a test; when
/// they can't, the way to turn them on.
class _NotificationsCard extends StatefulWidget {
  const _NotificationsCard({required this.services});

  final AppServices services;

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

enum _Test { idle, sending, sent, failed }

class _NotificationsCardState extends State<_NotificationsCard> {
  _Test _test = _Test.idle;

  Future<void> _sendTest() async {
    HapticFeedback.selectionClick();
    setState(() => _test = _Test.sending);
    try {
      await widget.services.account.sendTestPush();
      if (mounted) setState(() => _test = _Test.sent);
    } on AccountException {
      if (mounted) setState(() => _test = _Test.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final account = widget.services.account;
    final on = account.pushAllowed;
    final telegram = account.user?.provider == 'telegram';
    final (stateBg, stateInk) = on
        ? (p.accent.withValues(alpha: 0.12), p.accent)
        : (const Color(0xFFF59E0B).withValues(alpha: 0.16), const Color(0xFFB45309));
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: stateBg, shape: BoxShape.circle),
                child: Icon(on ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: stateInk),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  on ? s.accountPushOn : s.accountPushOffTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.3, color: p.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(on ? s.accountWhatComes : s.accountPushOff, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          if (telegram) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.telegram, size: 17, color: Color(0xFF229ED9)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(s.accountTelegramToo, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (!on)
            FilledButton.icon(
              onPressed: widget.services.permissions.openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: Text(s.accountTurnOn),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: _test == _Test.sending ? null : _sendTest,
              icon: _test == _Test.sending
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(s.accountTestPush),
            ),
            if (_test == _Test.sent || _test == _Test.failed) ...[
              const SizedBox(height: 8),
              Text(
                _test == _Test.sent ? s.accountTestSent : s.accountTestFailed,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: _test == _Test.sent ? p.accent : const Color(0xFFB91C1C),
                ),
              ),
            ],
          ],
        ],
      ),
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

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.title, this.value, this.highlight = false, required this.onTap});

  final IconData icon;
  final String title;

  /// On the right: a count, the current choice; null while loading.
  final String? value;
  final bool highlight;
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
                child: highlight
                    ? DecoratedBox(
                        decoration: BoxDecoration(color: Brand.gold300, borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          child: Text(value,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF3D2C05))),
                        ),
                      )
                    : Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 14, color: p.inkMuted)),
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
    return language == AppLanguage.uz ? const ['telegram', 'whatsapp', 'google'] : const ['whatsapp', 'google', 'telegram'];
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
    if (link != null) {
      final app = providerName(_linkProvider);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Center(child: SizedBox.square(dimension: 34, child: CircularProgressIndicator(strokeWidth: 3))),
          const SizedBox(height: 16),
          Text(s.signInWaitingTitle(app),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(height: 6),
          Text(s.signInWaitingBody,
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
            onTap: _busy == null ? () => _start(provider) : null,
          ),
          const SizedBox(height: 10),
        ],
        if (_error != null)
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: Color(0xFFB91C1C))),
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
    final mark = switch (provider) {
      'whatsapp' => const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 26),
      'telegram' => const Icon(Icons.telegram, color: Color(0xFF229ED9), size: 26),
      _ => const SizedBox.square(dimension: 26, child: CustomPaint(painter: _GoogleMark())),
    };
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
              mark,
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

/// Google's four-colour G, as its sign-in buttons show it.
class _GoogleMark extends CustomPainter {
  const _GoogleMark();

  static const _blue = Color(0xFF4285F4);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: (size.width - stroke) / 2 - 1);
    double rad(double degrees) => degrees * math.pi / 180;
    Paint pen(Color colour) => Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    // Clockwise from three o'clock; the gap at the upper right is the G's mouth.
    canvas
      ..drawArc(rect, rad(0), rad(45), false, pen(_blue))
      ..drawArc(rect, rad(45), rad(90), false, pen(const Color(0xFF34A853)))
      ..drawArc(rect, rad(135), rad(80), false, pen(const Color(0xFFFBBC05)))
      ..drawArc(rect, rad(215), rad(105), false, pen(const Color(0xFFEA4335)))
      ..drawRect(
        Rect.fromLTRB(rect.center.dx, rect.center.dy - stroke / 2, rect.right + stroke / 2, rect.center.dy + stroke / 2),
        Paint()..color = _blue,
      );
  }

  @override
  bool shouldRepaint(_GoogleMark old) => false;
}
