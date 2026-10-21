import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../qna/qna_parts.dart';
import 'hikorea_kit.dart';
import 'hikorea_models.dart';
import 'hikorea_parts.dart';
import 'hikorea_screen.dart';
import 'hikorea_source.dart';
import 'hikorea_text.dart';
import 'hikorea_watch.dart';

/// A counter's next three months, coloured by how booked each day is (as
/// the server last saw on HiKorea, every few minutes). A day opens its
/// appointment times, checked live; the button below sets a watch.
class HkCalendarScreen extends StatefulWidget {
  const HkCalendarScreen({super.key, required this.kit, required this.office, required this.desk});

  final HikoreaKit kit;
  final HkOffice office;
  final HkDesk desk;

  @override
  State<HkCalendarScreen> createState() => _HkCalendarScreenState();
}

class _HkCalendarScreenState extends State<HkCalendarScreen> {
  // The one the first page fetched shows at once; a fresh one follows.
  late HkCalendar? _calendar = widget.kit.calendarOf(widget.desk.seq);
  bool _failed = false;

  HikoreaKit get _kit => widget.kit;

  @override
  void initState() {
    super.initState();
    // After the first frame: the page under this one listens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _kit.remember(widget.desk));
    unawaited(_load());
  }

  Future<void> _load() async {
    final calendar = await _kit.loadCalendar(widget.desk.seq);
    if (!mounted) return;
    setState(() {
      _calendar = calendar ?? _calendar;
      _failed = _calendar == null;
    });
  }

  void _watch() {
    HapticFeedback.lightImpact();
    unawaited(showHkWatchSheet(context, kit: _kit, office: widget.office, desk: widget.desk));
  }

  void _openDay(DateTime day) {
    HapticFeedback.lightImpact();
    unawaited(showHkDaySheet(context, kit: _kit, office: widget.office, desk: widget.desk, day: day));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final calendar = _calendar;
    final today = _kit.today;
    final booth = boothName(widget.desk, _kit.language);
    final free = calendar?.openDays(today) ?? const <DateTime>[];
    final checked = calendar?.checkedAt;
    // The server reads every counter every 5 minutes; much older, or failing, and it says so.
    final stale = calendar != null &&
        (calendar.status == 'failing' ||
            (checked != null && _kit.services.clock().difference(checked) > const Duration(minutes: 30)));
    // This month, on to the month the window ends in, and the one after, to
    // show what isn't open yet: 3 to 4 of them.
    final windowEnd = calendar?.windowEnd;
    final end = windowEnd != null && windowEnd.isAfter(today) ? windowEnd : today;
    final months = ((end.year - today.year) * 12 + end.month - today.month + 2).clamp(3, 4);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: Text(officeName(widget.office.nameEn), maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          children: [
            HkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HkBadge('🎫', size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          booth.name.isEmpty ? s.hkCounterN(widget.desk.seq) : booth.name,
                          style: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w700, color: p.ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (booth.afternoon) HkPill(s.hkFromAfternoon, tone: HkTone.filling, icon: Icons.schedule_rounded),
                      if (checked != null)
                        HkPill(checkedAgo(s, checked, _kit.services.clock()),
                            tone: stale ? HkTone.low : HkTone.none, icon: Icons.sync_rounded),
                    ],
                  ),
                  if (stale) ...[
                    const SizedBox(height: 8),
                    Text(s.hkStale, style: TextStyle(fontSize: 13, height: 1.4, color: hkTone(context, HkTone.low).ink)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (calendar == null && _failed)
              QnaMessage(
                icon: Icons.wifi_off_rounded,
                title: s.hkLoadFailed,
                action: FilledButton.tonalIcon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(s.retry),
                ),
              )
            else if (calendar == null)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
            else if (calendar.dormant)
              _Dormant(kit: _kit, office: widget.office, desk: widget.desk, calendar: calendar)
            else ...[
              _Summary(kit: _kit, calendar: calendar, free: free, onDay: _openDay, onWatch: _watch),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(Icons.info_outline_rounded, size: 18, color: p.inkMuted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${s.hkHowBooking} ${s.hkCalendarHint}',
                          style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
                    ),
                  ],
                ),
              ),
              const _Legend(),
              for (var m = 0; m < months; m++)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _Month(
                    kit: _kit,
                    calendar: calendar,
                    month: DateTime(today.year, today.month + m),
                    onDay: _openDay,
                  ),
                ),
              if (calendar.days.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                  child: Text('🌙 ${s.hkNoDates}', style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: calendar?.dormant ?? false ? null : DecoratedBox(
        decoration: BoxDecoration(color: p.page, border: Border(top: BorderSide(color: p.hairline))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            // Free days: book them; none: watch for one.
            child: free.isEmpty
                ? FilledButton.icon(
                    onPressed: _watch,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(s.hkNotifyMe),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _kit.services.openLink(Uri.parse('https://www.hikorea.go.kr/')),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(s.hkBook, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _watch,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(s.hkWatchShort),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A counter HiKorea lists no day at, free or booked: retired, its bookings
/// under a new counter. Said plainly, with the ways on: the office's other
/// counters, and HiKorea itself. No calendar of closed days, no watch that
/// would never fire.
class _Dormant extends StatelessWidget {
  const _Dormant({required this.kit, required this.office, required this.desk, required this.calendar});

  final HikoreaKit kit;
  final HkOffice office;
  final HkDesk desk;
  final HkCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final tone = hkTone(context, HkTone.low);
    final since = calendar.listedUntil;
    // The office's other counters, unless every one of them is known to list nothing too.
    final others = office.desks.any((d) => d.seq != desk.seq && !(kit.calendarOf(d.seq)?.dormant ?? false));
    return HkCard(
      color: tone.background,
      edge: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_rounded, color: tone.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.hkDormantTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tone.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            since == null ? s.hkDormantBodyNoDate : s.hkDormantBody(dayMonth(since, kit.language)),
            style: TextStyle(fontSize: 14, height: 1.45, color: p.ink),
          ),
          const SizedBox(height: 14),
          if (others) ...[
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                  builder: (_) => HkCountersScreen(kit: kit, office: office),
                ));
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(s.hkOtherCounters),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => kit.services.openLink(Uri.parse('https://www.hikorea.go.kr/')),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(s.hkCheckOnHikorea),
          ),
        ],
      ),
    );
  }
}

/// The first day one can still get and how many there are; when there is
/// none, until when it is booked, and the way to a watch.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.kit,
    required this.calendar,
    required this.free,
    required this.onDay,
    required this.onWatch,
  });

  final HikoreaKit kit;
  final HkCalendar calendar;
  final List<DateTime> free;
  final ValueChanged<DateTime> onDay;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (calendar.days.isEmpty) return const SizedBox.shrink();
    final earliest = free.firstOrNull;
    final end = calendar.windowEnd;
    final tone = hkTone(context, earliest == null ? HkTone.filling : HkTone.open);
    final below = earliest == null
        ? (end == null ? s.hkAllFullBody : s.hkBookedUntil(dayMonth(end, kit.language)))
        : end == null
            ? null
            : s.hkFreeDays(free.length, dayMonth(end, kit.language));
    return HkCard(
      onTap: earliest == null ? onWatch : () => onDay(earliest),
      color: tone.background,
      edge: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Text(earliest == null ? '🌙' : '⚡', style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earliest == null ? s.hkAllFull : s.hkEarliest,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tone.ink),
                ),
                if (earliest != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${weekdayName(earliest, kit.language)}, ${dayMonth(earliest, kit.language)}',
                    style: TextStyle(fontSize: 19, height: 1.25, fontWeight: FontWeight.w800, color: tone.ink),
                  ),
                ],
                if (below != null) ...[
                  const SizedBox(height: 3),
                  Text(below, style: TextStyle(fontSize: 13.5, height: 1.35, color: tone.ink)),
                ],
              ],
            ),
          ),
          Icon(earliest == null ? Icons.notifications_active_outlined : Icons.chevron_right_rounded, color: tone.ink),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget item(HkTier tier, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: hkDayColours(context, tier).background,
                borderRadius: BorderRadius.circular(4),
                border: tier == HkTier.later ? Border.all(color: p.hairlineStrong) : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(fontSize: 12.5, color: p.inkSoft)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          item(HkTier.open, s.hkLegendOpen),
          item(HkTier.some, s.hkLegendSome),
          item(HkTier.full, s.hkLegendFull),
          item(HkTier.closed, s.hkLegendClosed),
          item(HkTier.later, s.hkLegendLater),
        ],
      ),
    );
  }
}

class _Month extends StatelessWidget {
  const _Month({required this.kit, required this.calendar, required this.month, required this.onDay});

  final HikoreaKit kit;
  final HkCalendar calendar;
  final DateTime month;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final today = kit.today;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    // Weeks gone by are left out: this month starts at this week.
    final skip = month.year == today.year && month.month == today.month ? (today.day - today.weekday + 1).clamp(1, days) - 1 : 0;
    final first = DateTime(month.year, month.month, skip + 1);
    final lead = first.weekday - 1;
    final cells = ((lead + days - skip) / 7).ceil() * 7;
    return HkCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              monthTitle(month, kit.language),
              style: TextStyle(fontFamily: Brand.displayFont, fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
            ),
          ),
          Row(
            children: [
              for (final d in weekdayLetters(kit.language))
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.inkMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, i) {
              final n = i - lead + 1 + skip;
              if (n < 1 + skip || n > days) return const SizedBox.shrink();
              final day = DateTime(month.year, month.month, n);
              return _Day(
                day: day,
                tier: calendar.tierOf(ymdOf(day)),
                past: day.isBefore(today),
                today: day == today,
                onTap: () => onDay(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.tier, required this.past, required this.today, required this.onTap});

  final DateTime day;
  final (HkTier, double) tier;
  final bool past;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final (kind, fill) = tier;
    final open = !past && kind != HkTier.closed && kind != HkTier.later;
    final colours = hkDayColours(context, kind);
    final background = past ? Colors.transparent : colours.background;
    final ink = past || kind == HkTier.later ? p.inkMuted.withValues(alpha: 0.6) : colours.ink;
    final edge = today
        ? BorderSide(color: p.accent, width: 2)
        : !past && kind == HkTier.later
            ? BorderSide(color: p.hairlineStrong)
            : BorderSide.none;
    return Semantics(
      button: open,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: edge,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open ? onTap : null,
          child: Stack(
            children: [
              Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(fontSize: 14, fontWeight: open ? FontWeight.w700 : FontWeight.w500, color: ink),
                ),
              ),
              if (open && (kind == HkTier.some || kind == HkTier.full))
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: Container(height: 3, color: colours.ink.withValues(alpha: 0.45)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A day's appointment times, checked on HiKorea now.
Future<void> showHkDaySheet(
  BuildContext context, {
  required HikoreaKit kit,
  required HkOffice office,
  required HkDesk desk,
  required DateTime day,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: VegukinPalette.of(context).page,
      builder: (_) => _DaySheet(kit: kit, office: office, desk: desk, day: day),
    );

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.kit, required this.office, required this.desk, required this.day});

  final HikoreaKit kit;
  final HkOffice office;
  final HkDesk desk;
  final DateTime day;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  HkDay? _day;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final day = await widget.kit.source.day(widget.desk.seq, ymdOf(widget.day));
      if (mounted) setState(() => _day = day);
    } on HkException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final kit = widget.kit;
    final day = _day;
    final error = _error;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              weekdayName(widget.day, kit.language).toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: p.accent),
            ),
            const SizedBox(height: 2),
            Text(
              dayMonthYear(widget.day, kit.language),
              style: TextStyle(fontFamily: Brand.displayFont, fontSize: 24, fontWeight: FontWeight.w700, color: p.ink),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: p.inkMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error == 'session_expired' ? s.hkSessionExpired : s.hkFetchFailed,
                      style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: Text(s.retry)),
            ] else if (day == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(s.hkChecking, style: TextStyle(fontSize: 14, color: p.inkSoft)),
                  ],
                ),
              )
            else
              _DayDetail(day: day),
            const SizedBox(height: 18),
            if (day != null && day.available > 0)
              FilledButton.icon(
                onPressed: () => kit.services.openLink(Uri.parse('https://www.hikorea.go.kr/')),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(s.hkBook),
              )
            else if (day != null)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  unawaited(showHkWatchSheet(context, kit: kit, office: widget.office, desk: widget.desk, day: widget.day));
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(s.hkNotifyMe),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day});

  final HkDay day;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final cap = day.capacity, open = day.available;
    final (headline, tone) = cap == 0
        ? (s.hkDayClosed, HkTone.none)
        : open <= 0
            ? (s.hkFullyBooked, HkTone.none)
            : open == 1
                ? (s.hkLastOne, HkTone.low)
                : (s.hkSlotsFree(open), open / cap < 0.2 ? HkTone.low : (open / cap < 0.5 ? HkTone.filling : HkTone.open));
    final morning = [for (final t in day.slots) if (t.morning) t];
    final afternoon = [for (final t in day.slots) if (!t.morning) t];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HkPill(headline, tone: tone),
        const SizedBox(height: 8),
        Text(open > 0 ? s.hkBookCue : s.hkFullCue, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
        if (cap > 0) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: day.taken / cap,
              minHeight: 8,
              backgroundColor: hkTone(context, HkTone.open).background,
              color: hkTone(context, open / cap < 0.2 ? HkTone.low : HkTone.filling).ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(s.hkBookedOf(day.taken, cap), style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
        ],
        for (final (title, slots) in [(s.hkMorning, morning), (s.hkAfternoon, afternoon)])
          if (slots.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final t in slots) _TimeChip(slot: t)]),
          ],
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.slot});

  final HkTimeSlot slot;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final full = slot.available <= 0;
    final colours = hkTone(context, full ? HkTone.none : (slot.available == slot.capacity ? HkTone.open : HkTone.filling));
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: colours.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(
            slot.time,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colours.ink,
              decoration: full ? TextDecoration.lineThrough : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(full ? s.hkSlotFull : s.hkLeft(slot.available), style: TextStyle(fontSize: 11.5, color: colours.ink)),
        ],
      ),
    );
  }
}
