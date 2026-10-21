import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/account.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

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

/// Who the app is signed in as; signing in, out, and deleting the account.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final account = services.account;
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: Text(s.accountTitle),
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: account,
        builder: (context, _) {
          final user = account.user;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
            children: [
              if (user != null && user.signedIn)
                _Profile(user: user, services: services)
              else
                _Card(
                  child: SignInPanel(
                    services: services,
                    onSignedIn: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(s.signInDone), behavior: SnackBarBehavior.floating));
                    },
                  ),
                ),
              const SizedBox(height: 12),
              _PushRow(services: services),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
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

class _Profile extends StatelessWidget {
  const _Profile({required this.user, required this.services});

  final AppUser user;
  final AppServices services;

  // The card goes as soon as the account changes, so its messages go through
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
    final p = VegukinPalette.of(context);
    final name = user.name ?? user.detail ?? providerName(user.provider);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: p.accent.withValues(alpha: 0.12),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.accent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
                    if (user.detail != null && user.detail != name)
                      Text(user.detail!, style: TextStyle(fontSize: 14, color: p.inkSoft)),
                    const SizedBox(height: 2),
                    Text(s.signedInWith(providerName(user.provider)),
                        style: TextStyle(fontSize: 13, color: p.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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

/// Whether alerts reach this phone; a way to the settings when they can't.
class _PushRow extends StatelessWidget {
  const _PushRow({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final on = services.account.pushAllowed;
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(on ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              color: on ? p.accent : p.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(on ? s.accountPushOn : s.accountPushOff,
                    style: TextStyle(fontSize: 14, height: 1.4, color: p.ink)),
                if (!on)
                  TextButton(
                    onPressed: services.permissions.openAppSettings,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                    child: Text(s.openSettings),
                  ),
              ],
            ),
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
