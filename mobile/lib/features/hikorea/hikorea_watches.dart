import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../qna/qna_parts.dart';
import 'hikorea_calendar.dart';
import 'hikorea_kit.dart';
import 'hikorea_models.dart';
import 'hikorea_parts.dart';
import 'hikorea_source.dart';
import 'hikorea_text.dart';

void openWatches(BuildContext context, HikoreaKit kit) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HkWatchesScreen(kit: kit)));
}

/// The watches running for this person, and the ones that have ended.
class HkWatchesScreen extends StatefulWidget {
  const HkWatchesScreen({super.key, required this.kit});

  final HikoreaKit kit;

  @override
  State<HkWatchesScreen> createState() => _HkWatchesScreenState();
}

class _HkWatchesScreenState extends State<HkWatchesScreen> {
  List<HkWatch>? _all;
  bool _failed = false;
  final _stopping = <int>{};

  HikoreaKit get _kit => widget.kit;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    if (_kit.offices == null) unawaited(_kit.loadOffices().then((_) {}, onError: (Object _) {}));
  }

  Future<void> _load() async {
    try {
      final all = await _kit.source.watches(await _kit.auth(), past: true);
      if (mounted) {
        setState(() {
          _all = all;
          _failed = false;
        });
      }
    } on HkException {
      if (mounted) setState(() => _failed = _all == null);
    }
  }

  Future<void> _stop(HkWatch watch) async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.hkStopTitle),
        content: Text(_describe(watch)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.hkStop)),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _stopping.add(watch.id));
    try {
      await _kit.source.stop(await _kit.auth(), watch.id);
      HapticFeedback.mediumImpact();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.hkStopped), behavior: SnackBarBehavior.floating));
      await Future.wait([_load(), _kit.refreshWatches()]);
    } on HkException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.hkStopFailed), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _stopping.remove(watch.id));
    }
  }

  String _describe(HkWatch watch) {
    final language = _kit.language;
    final booth = watchBooth(watch, language);
    return [
      officeName(watch.officeNameEn),
      if (booth.isNotEmpty) booth,
      '${dayMonth(watch.start, language)} – ${dayMonthYear(watch.end, language)}',
    ].join('\n');
  }

  Future<void> _openCalendar(HkWatch watch) async {
    if (_kit.offices == null) {
      try {
        await _kit.loadOffices();
      } on HkException {
        return;
      }
    }
    final found = _kit.deskOf(watch.deskSeq);
    if (found == null || !mounted) return;
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => HkCalendarScreen(kit: _kit, office: found.$1, desk: found.$2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final all = _all;
    final active = [for (final w in all ?? const <HkWatch>[]) if (w.active) w];
    final past = [for (final w in all ?? const <HkWatch>[]) if (!w.active) w];
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(title: Text(s.hkMyWatches), backgroundColor: p.page, surfaceTintColor: Colors.transparent),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            if (all == null && _failed)
              QnaMessage(
                icon: Icons.wifi_off_rounded,
                title: s.hkLoadFailed,
                action: FilledButton.tonalIcon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(s.retry),
                ),
              )
            else if (all == null)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
            else ...[
              if (active.isEmpty)
                QnaMessage(
                  icon: Icons.visibility_outlined,
                  title: s.hkWatchesEmpty,
                  body: s.hkWatchesEmptyBody,
                  action: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst || _isHikoreaHome(route)),
                    child: Text(s.hkPickOffice),
                  ),
                ),
              for (final watch in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WatchCard(
                    kit: _kit,
                    watch: watch,
                    stopping: _stopping.contains(watch.id),
                    onCalendar: () => _openCalendar(watch),
                    onStop: () => _stop(watch),
                  ),
                ),
              if (past.isNotEmpty) ...[
                HkHeading(s.hkPastWatches),
                for (final watch in past.take(20))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WatchCard(kit: _kit, watch: watch, onCalendar: () => _openCalendar(watch)),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static bool _isHikoreaHome(Route<dynamic> route) => route.settings.name == hikoreaRouteName;
}

/// The HiKorea section's first page, for "back to the offices".
const hikoreaRouteName = 'hikorea';

class _WatchCard extends StatelessWidget {
  const _WatchCard({
    required this.kit,
    required this.watch,
    required this.onCalendar,
    this.onStop,
    this.stopping = false,
  });

  final HikoreaKit kit;
  final HkWatch watch;
  final VoidCallback onCalendar;
  final VoidCallback? onStop;
  final bool stopping;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final language = kit.language;
    final booth = watchBooth(watch, language);
    final days = watch.end.difference(watch.start).inDays + 1;
    return Opacity(
      opacity: watch.active ? 1 : 0.7,
      child: HkCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    officeName(watch.officeNameEn),
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(right: 6), child: HkStatus(watch.status)),
              ],
            ),
            if (booth.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(booth, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: p.inkSoft)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.date_range_rounded, size: 18, color: p.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${dayMonth(watch.start, language)} – ${dayMonthYear(watch.end, language)} · ${s.hkDays(days)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onCalendar,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(s.hkCalendar),
                ),
                if (onStop != null)
                  TextButton.icon(
                    onPressed: stopping ? null : onStop,
                    style: TextButton.styleFrom(foregroundColor: hkTone(context, HkTone.low).ink),
                    icon: stopping
                        ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text(s.hkStop),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
