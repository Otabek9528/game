import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/account.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../home/feature_catalog.dart';

void openInbox(BuildContext context, AppServices services) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InboxScreen(services: services)));
}

/// Every alert pushed to this person, newest first, as the server keeps it:
/// also those that came while notifications were off on this phone, or were
/// swiped away. Tapping one opens its page, as the notification would.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  AccountController get _account => widget.services.account;

  /// New when the page opened: marked as such until it closes.
  late final int _seenBefore = _account.inboxSeen;
  bool _loading = true;
  bool _failed = false;
  bool _loadingMore = false;
  final _expanded = <int>{};

  @override
  void initState() {
    super.initState();
    // Open: what is shown is seen, also what arrives meanwhile. After the
    // first frame, so the home screen's badge isn't changed mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _account.addListener(_account.markInboxSeen);
      _account.markInboxSeen();
    });
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _account.removeListener(_account.markInboxSeen);
    super.dispose();
  }

  Future<void> _refresh() async {
    final loaded = await _account.refreshInbox();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = !loaded;
    });
  }

  Future<void> _loadMore() async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingMore = true);
    try {
      await _account.loadMoreInbox();
    } on AccountException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.inboxFailed), behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _loadingMore = false);
  }

  void _tap(InboxItem item, Feature? target) {
    if (target == null) {
      setState(() => _expanded.contains(item.id) ? _expanded.remove(item.id) : _expanded.add(item.id));
      return;
    }
    HapticFeedback.lightImpact();
    widget.services.openFeature(context, target, widget.services);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: Text(s.inboxTitle),
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: _account,
        builder: (context, _) {
          final items = _account.inbox;
          if (items.isEmpty && _loading) return const Center(child: CircularProgressIndicator());
          return RefreshIndicator(
            onRefresh: _refresh,
            color: p.accent,
            child: items.isEmpty
                ? _Empty(failed: _failed, onRetry: () {
                    setState(() => _loading = true);
                    unawaited(_refresh());
                  })
                : _list(context, items),
          );
        },
      ),
    );
  }

  Widget _list(BuildContext context, List<InboxItem> items) {
    final services = widget.services;
    final language = services.locale.language ?? AppLanguage.uz;
    final today = DateUtils.dateOnly(services.clock());
    final rows = <Object>[];
    DateTime? day;
    for (final item in items) {
      final itemDay = DateUtils.dateOnly(item.at);
      if (itemDay != day) rows.add(day = itemDay);
      rows.add(item);
    }
    final pushOff = !_account.pushAllowed;
    final more = _account.inboxMore;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
      itemCount: (pushOff ? 1 : 0) + rows.length + (more ? 1 : 0),
      itemBuilder: (context, i) {
        if (pushOff) {
          if (i == 0) return _PushOff(services: services);
          i--;
        }
        if (i == rows.length) return _More(loading: _loadingMore, onTap: _loadMore);
        final row = rows[i];
        if (row is DateTime) return _DayHeader(day: row, today: today, language: language);
        final item = row as InboxItem;
        final target = featureForPush(item.data);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _Item(
            item: item,
            target: target,
            language: language,
            isNew: item.id > _seenBefore,
            expanded: _expanded.contains(item.id),
            onTap: () => _tap(item, target),
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today, required this.language});

  final DateTime day;
  final DateTime today;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final uz = language == AppLanguage.uz;
    final text = switch (today.difference(day).inDays) {
      0 => s.dayToday,
      1 => s.dayYesterday,
      _ when day.year == today.year => DateFormat(uz ? 'd-MMMM' : 'd MMMM', language.code).format(day),
      _ => DateFormat(uz ? 'd-MMMM, y' : 'd MMMM y', language.code).format(day),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: p.inkMuted),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.target,
    required this.language,
    required this.isNew,
    required this.expanded,
    required this.onTap,
  });

  final InboxItem item;

  /// The page a tap opens; none: a tap shows the whole text.
  final Feature? target;
  final AppLanguage language;
  final bool isNew;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final target = this.target;
    return Material(
      color: isNew ? p.cardSelected : p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.badge, shape: BoxShape.circle),
                child: Text(target?.emoji ?? '🔔', style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNew)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 6),
                            child: Semantics(
                              label: s.newBadge,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3, color: p.ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            DateFormat.Hm(language.code).format(item.at),
                            style: TextStyle(fontSize: 12, color: p.inkMuted),
                          ),
                        ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: expanded ? null : 5,
                        overflow: expanded ? null : TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft),
                      ),
                    ],
                    if (target != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${target.label(s)}  ›',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.accent),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notifications are off on this phone: alerts still come here.
class _PushOff extends StatelessWidget {
  const _PushOff({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_outlined, color: p.inkMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(s.inboxPushOff, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
          ),
          TextButton(onPressed: services.permissions.openAppSettings, child: Text(s.notificationsTurnOn)),
        ],
      ),
    );
  }
}

class _More extends StatelessWidget {
  const _More({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Center(
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            : TextButton(onPressed: onTap, child: Text(s.inboxEarlier)),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    // Scrollable, so pulling down refreshes here too.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(color: p.badge, shape: BoxShape.circle),
                  child: Icon(
                    failed ? Icons.cloud_off_rounded : Icons.notifications_none_rounded,
                    size: 36,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  failed ? s.inboxFailed : s.inboxEmptyTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
                ),
                if (!failed) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.inboxEmptyBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft),
                  ),
                ],
                if (failed) ...[
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(s.retry)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
