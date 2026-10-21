import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'hikorea_kit.dart';
import 'hikorea_models.dart';
import 'hikorea_parts.dart';
import 'hikorea_source.dart';
import 'hikorea_text.dart';
import 'hikorea_watches.dart';

/// Sets a watch on a counter's days: the server checks them every few
/// minutes and sends a notification when a slot opens. [day]: just that
/// day, from its sheet.
Future<void> showHkWatchSheet(
  BuildContext context, {
  required HikoreaKit kit,
  required HkOffice office,
  required HkDesk desk,
  DateTime? day,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: VegukinPalette.of(context).page,
      builder: (_) => _WatchSheet(kit: kit, office: office, desk: desk, day: day),
    );

/// The server takes up to 90 days after the first.
const _longest = 90;
const _presets = [7, 14, 30, 60, 90];

enum _Test { idle, sending, sent }

class _WatchSheet extends StatefulWidget {
  const _WatchSheet({required this.kit, required this.office, required this.desk, this.day});

  final HikoreaKit kit;
  final HkOffice office;
  final HkDesk desk;
  final DateTime? day;

  @override
  State<_WatchSheet> createState() => _WatchSheetState();
}

class _WatchSheetState extends State<_WatchSheet> {
  late DateTime _start;
  late DateTime _end;
  int? _preset;
  bool _busy = false;
  String? _error;
  bool _done = false;
  _Test _test = _Test.idle;
  bool _testFailed = false;

  HikoreaKit get _kit => widget.kit;

  @override
  void initState() {
    super.initState();
    if (widget.day case final day?) {
      _start = _end = day;
    } else {
      _pick(14);
    }
  }

  /// From tomorrow (today's appointments are gone), as the web page has it.
  void _pick(int days) {
    final today = _kit.today;
    _preset = days;
    _start = DateTime(today.year, today.month, today.day + 1);
    _end = DateTime(today.year, today.month, today.day + days);
    _error = null;
  }

  int get _days => _end.difference(_start).inDays + 1;
  bool get _tooLong => _end.difference(_start).inDays > _longest;

  Future<void> _pickDates() async {
    final today = _kit.today;
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      currentDate: today,
    );
    if (range == null || !mounted) return;
    setState(() {
      _preset = null;
      _start = DateUtils.dateOnly(range.start);
      _end = DateUtils.dateOnly(range.end);
      _error = null;
    });
  }

  Future<void> _create() async {
    final s = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _kit.source.watch(
        await _kit.auth(),
        desk: widget.desk.seq,
        start: ymdOf(_start),
        end: ymdOf(_end),
        lang: _kit.language.code,
      );
      HapticFeedback.mediumImpact();
      unawaited(_kit.refreshWatches());
      if (mounted) setState(() => _done = true);
    } on HkException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() => _error = switch (e.code) {
              'duplicate_watch' => s.hkDuplicate,
              'max_watches_reached' => s.hkMaxReached,
              'validation_failed' => s.hkTooLong,
              _ => s.hkCreateFailed,
            });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendTest() async {
    setState(() {
      _test = _Test.sending;
      _testFailed = false;
    });
    try {
      await _kit.source.test(await _kit.auth(), _kit.language.code);
      if (mounted) setState(() => _test = _Test.sent);
    } on HkException {
      if (mounted) {
        setState(() {
          _test = _Test.idle;
          _testFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(context).bottom),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: _done ? _doneView(context) : _form(context),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final language = _kit.language;
    final booth = boothName(widget.desk, language).name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.hkWatchTitle,
          style: TextStyle(fontFamily: Brand.displayFont, fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
        ),
        const SizedBox(height: 4),
        Text(
          [officeName(widget.office.nameEn), if (widget.office.desks.length > 1 && booth.isNotEmpty) booth].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: p.inkMuted),
        ),
        const SizedBox(height: 10),
        Text(s.hkWatchLede, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in _presets)
              ChoiceChip(
                label: Text(s.hkNextDays(days)),
                selected: _preset == days,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _pick(days));
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickDates,
          icon: const Icon(Icons.date_range_rounded),
          label: Text(s.hkPickDates),
        ),
        const SizedBox(height: 14),
        HkCard(
          color: hkTone(context, _tooLong ? HkTone.low : HkTone.open).background,
          edge: Colors.transparent,
          child: Row(
            children: [
              const Text('🔔', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _start == _end
                          ? dayMonthYear(_start, language)
                          : '${dayMonth(_start, language)} – ${dayMonthYear(_end, language)}',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                    ),
                    Text(
                      _tooLong ? s.hkTooLong : s.hkDays(_days),
                      style: TextStyle(fontSize: 13, color: hkTone(context, _tooLong ? HkTone.low : HkTone.open).ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 10),
          Text(error, style: TextStyle(fontSize: 13.5, color: hkTone(context, HkTone.low).ink)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || _tooLong ? null : _create,
          icon: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Icon(Icons.notifications_active_rounded),
          label: Text(s.hkStartWatching),
        ),
      ],
    );
  }

  Widget _doneView(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final services = _kit.services;
    final pushOff = !services.account.pushAllowed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_rounded, size: 56, color: p.accent),
        const SizedBox(height: 10),
        Text(
          s.hkDoneTitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: Brand.displayFont, fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
        ),
        const SizedBox(height: 6),
        Text(
          '${dayMonth(_start, _kit.language)} – ${dayMonthYear(_end, _kit.language)}\n${s.hkDoneBody}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft),
        ),
        if (pushOff) ...[
          const SizedBox(height: 14),
          HkCard(
            color: hkTone(context, HkTone.filling).background,
            edge: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Icon(Icons.notifications_off_outlined, color: hkTone(context, HkTone.filling).ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.hkPushOff,
                    style: TextStyle(fontSize: 13, height: 1.4, color: hkTone(context, HkTone.filling).ink),
                  ),
                ),
                TextButton(onPressed: services.permissions.openAppSettings, child: Text(s.notificationsTurnOn)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            openWatches(context, _kit);
          },
          child: Text(s.hkSeeWatches),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _test == _Test.idle ? _sendTest : null,
          icon: switch (_test) {
            _Test.sending => const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            _Test.sent => const Icon(Icons.check_rounded),
            _Test.idle => const Icon(Icons.send_rounded),
          },
          label: Text(_test == _Test.sent ? s.hkTestSent : s.hkSendTest),
        ),
        if (_testFailed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              s.hkTestFailed,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: hkTone(context, HkTone.low).ink),
            ),
          ),
      ],
    );
  }
}
