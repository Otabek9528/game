import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import 'jobs_posts.dart';
import 'jobs_source.dart';

/// What the job pages share: the group's server, the account.
class JobsKit {
  JobsKit(this.services);

  final AppServices services;

  JobsSource get source => services.jobs;
  bool get signedIn => services.account.signedIn;
  DateTime now() => services.clock();

  /// The name to sign posts with.
  String get name => services.account.user?.name ?? '';

  /// The Telegram name one signed in with, without "@": the contact the web
  /// page offers first.
  String? get telegramName {
    final user = services.account.user;
    final detail = user?.detail;
    if (user?.provider != 'telegram' || detail == null || !detail.startsWith('@') || detail.length < 2) return null;
    return detail.substring(1);
  }

  /// The account's header and id; the account is made when missing.
  Future<(Map<String, String>, int)> auth() async {
    try {
      await services.account.headers();
    } catch (_) {}
    final id = services.account.user?.id;
    if (id == null) throw const JobsException('offline');
    return (services.account.authHeaders, id);
  }

  String message(AppLocalizations s, JobsException e, String fallback) =>
      e.message ?? (e.code == 'offline' ? s.jbErrNetwork : fallback);
}

void showJobsSnack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

enum _Link { initial, loading, open, expired, error }

/// The job group, as the Mini App has it: what the group is, a one-time link
/// into it (15 seconds), and posting one's own job in it.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key, required this.services});

  final AppServices services;

  /// How long a link is offered.
  static const linkSeconds = 15;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late final _kit = JobsKit(widget.services);
  _Link _state = _Link.initial;
  String? _link;
  String? _error;
  int _left = JobsScreen.linkSeconds;
  Timer? _timer;
  int _posts = 0;
  final _joinKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_count());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// One's posts, for the shortcut: shown once there are some.
  Future<void> _count() async {
    if (!_kit.signedIn) return;
    try {
      final (auth, user) = await _kit.auth();
      final posts = await _kit.source.posts(auth, user);
      if (mounted) setState(() => _posts = posts.length);
    } on JobsException {
      // The shortcut waits.
    }
  }

  Future<void> _getLink() async {
    final s = AppLocalizations.of(context);
    _timer?.cancel();
    setState(() => _state = _Link.loading);
    try {
      final (auth, user) = await _kit.auth();
      final link = await _kit.source.invite(auth, user);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _link = link;
        _left = JobsScreen.linkSeconds;
        _state = _Link.open;
      });
      // The link and its button in sight: they only last seconds.
      unawaited(Future.delayed(const Duration(milliseconds: 240), () {
        final card = _joinKey.currentContext;
        if (card != null && card.mounted) {
          unawaited(Scrollable.ensureVisible(
            card,
            duration: const Duration(milliseconds: 250),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ));
        }
      }));
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _left--);
        if (_left <= 0) {
          t.cancel();
          HapticFeedback.heavyImpact();
          setState(() {
            _link = null;
            _state = _Link.expired;
          });
        }
      });
    } on JobsException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _error = _kit.message(s, e, s.jbLinkError);
        _state = _Link.error;
      });
    }
  }

  Future<void> _copy() async {
    final link = _link;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    HapticFeedback.lightImpact();
    if (mounted) showJobsSnack(context, AppLocalizations.of(context).jbCopied);
  }

  Future<void> _open({required bool mine}) async {
    HapticFeedback.lightImpact();
    if (!_kit.signedIn && !await askToSignIn(context, widget.services)) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => JobsPostsPage(kit: _kit, mine: mine)));
    unawaited(_count());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(backgroundColor: p.page, surfaceTintColor: Colors.transparent, title: Text(s.jbTitle)),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.card,
          border: Border(top: BorderSide(color: p.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _open(mine: false),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(s.jbPost, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                if (_posts > 0) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _open(mine: true),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.article_outlined, size: 20),
                        const SizedBox(width: 6),
                        JobsCount(_posts),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Hero(),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _JoinCard(
              key: _joinKey,
              state: _state,
              link: _link,
              left: _left,
              error: _error,
              onGet: _getLink,
              onCopy: _copy,
              onJoin: () => widget.services.openLink(Uri.parse(_link!)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small count in a pill.
class JobsCount extends StatelessWidget {
  const JobsCount(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle_rounded, size: 19, color: p.accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14.5, height: 1.4, color: p.ink))),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(16)),
                child: const Text('💼', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.jbTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
                    const SizedBox(height: 2),
                    Text(s.jbSubtitle, style: TextStyle(fontSize: 13.5, color: p.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('🤖 ${s.jbBotDoes}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
          point(s.jbPoint1),
          point(s.jbPoint2),
          point(s.jbPoint3),
        ],
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    super.key,
    required this.state,
    required this.link,
    required this.left,
    required this.error,
    required this.onGet,
    required this.onCopy,
    required this.onJoin,
  });

  final _Link state;
  final String? link;
  final int left;
  final String? error;
  final VoidCallback onGet;
  final VoidCallback onCopy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final big = FilledButton.styleFrom(minimumSize: const Size.fromHeight(52));
    Widget retry() => FilledButton.icon(onPressed: onGet, style: big, icon: const Icon(Icons.refresh_rounded), label: Text(s.jbRetry));
    Widget heading(IconData icon, Color colour, String title, String body) => Column(
      children: [
        Icon(icon, size: 40, color: colour),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
        const SizedBox(height: 4),
        Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
        const SizedBox(height: 16),
      ],
    );
    final child = switch (state) {
      _Link.initial => Column(
        children: [
          FilledButton.icon(
            onPressed: onGet,
            style: big,
            icon: const Icon(Icons.link_rounded),
            label: Text(s.jbGetLink, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 10),
          Text('🔒 ${s.jbLinkNote}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkMuted)),
        ],
      ),
      _Link.loading => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(s.jbLinkLoading, style: TextStyle(color: p.inkSoft)),
          ],
        ),
      ),
      _Link.open => Column(
        children: [
          Row(
            children: [
              _Countdown(left: left),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.jbYourLink, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.inkMuted)),
                    const SizedBox(height: 6),
                    Material(
                      color: p.page,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onCopy,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  link ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                                ),
                              ),
                              Icon(Icons.copy_rounded, size: 20, color: p.accent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onJoin,
            style: big,
            icon: const Icon(Icons.telegram),
            label: Text(s.jbJoin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 10),
          Text('⚠️ ${s.jbLinkWarning}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft)),
        ],
      ),
      _Link.expired => Column(
        children: [
          heading(Icons.timer_off_outlined, p.inkMuted, s.jbExpiredTitle, s.jbExpiredBody),
          retry(),
        ],
      ),
      _Link.error => Column(
        children: [
          heading(Icons.error_outline_rounded, Theme.of(context).colorScheme.error, s.jbErrorTitle, error ?? s.jbLinkError),
          retry(),
        ],
      ),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.hairline)),
      child: child,
    );
  }
}

/// The seconds left, in a ring that empties: amber under 10, red under 5.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final colour = left <= 5
        ? Theme.of(context).colorScheme.error
        : left <= 10
        ? const Color(0xFFE0A100)
        : p.accent;
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: left / JobsScreen.linkSeconds),
              duration: const Duration(milliseconds: 900),
              builder: (context, value, _) => CustomPaint(painter: _Ring(value, colour, p.hairline)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$left', style: TextStyle(fontSize: 28, height: 1, fontWeight: FontWeight.w800, color: colour)),
              const SizedBox(height: 2),
              Text(s.jbSecondsLeft, style: TextStyle(fontSize: 10.5, color: p.inkMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.value, this.colour, this.track);

  final double value;
  final Color colour;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(4), 0, math.pi * 2, false, paint..color = track);
    canvas.drawArc(rect.deflate(4), -math.pi / 2, math.pi * 2 * value.clamp(0, 1), false, paint..color = colour);
  }

  @override
  bool shouldRepaint(_Ring old) => old.value != value || old.colour != colour;
}
