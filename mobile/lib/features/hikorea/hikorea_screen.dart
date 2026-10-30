import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../qna/qna_parts.dart';
import 'hikorea_address.dart';
import 'hikorea_calendar.dart';
import 'hikorea_kit.dart';
import 'hikorea_models.dart';
import 'hikorea_parts.dart';
import 'hikorea_source.dart';
import 'hikorea_text.dart';
import 'hikorea_watches.dart';

/// HiKorea appointments: find the immigration office and counter, see how
/// booked its next months are, check a day live, and set a watch that sends
/// a notification when a slot opens. Booking itself is on hikorea.go.kr.
class HikoreaScreen extends StatefulWidget {
  const HikoreaScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HikoreaScreen> createState() => _HikoreaScreenState();
}

class _HikoreaScreenState extends State<HikoreaScreen> {
  late final HikoreaKit _kit = HikoreaKit(widget.services);
  final _search = TextEditingController();
  String _query = '';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    unawaited(_kit.loadAllCalendars());
    unawaited(_kit.refreshWatches());
  }

  @override
  void dispose() {
    _search.dispose();
    _kit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      await _kit.loadOffices();
    } on HkException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _refresh() {
    _kit.retryFailed();
    return Future.wait([
      if (_kit.offices == null) _load(),
      _kit.loadAllCalendars(again: true),
      _kit.refreshWatches(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      body: ListenableBuilder(
        listenable: _kit,
        builder: (context, _) {
          final offices = _kit.offices;
          final shown = [for (final o in offices ?? const <HkOffice>[]) if (o.matches(_query)) o]
            ..sort((a, b) => officeParts(a.nameEn).place.toLowerCase().compareTo(officeParts(b.nameEn).place.toLowerCase()));
          final searching = _query.trim().isNotEmpty;
          final watches = _kit.watches ?? const <HkWatch>[];
          final last = _kit.lastDesk == null ? null : _kit.deskOf(_kit.lastDesk!);
          // Someone new: no watch, no counter looked at yet.
          final newcomer = watches.isEmpty && last == null;
          return RefreshIndicator(
            onRefresh: _refresh,
            edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: p.hero.first,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
                  titleTextStyle: const TextStyle(
                    fontFamily: Brand.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  title: Text(s.featureHikorea),
                  actions: [
                    _WatchesButton(kit: _kit),
                    const SizedBox(width: 4),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _Hero(
                    controller: _search,
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(14, 4, 14, 28 + MediaQuery.paddingOf(context).bottom),
                  sliver: SliverList.list(
                    children: [
                      if (!searching) ...[
                        // What is theirs first: the watches, and how they stand now.
                        if (watches.isNotEmpty) ...[
                          HkHeading(s.hkYourWatches,
                              action: watches.length > 2 ? s.hkSeeAll(watches.length) : null,
                              onAction: () => openWatches(context, _kit)),
                          for (final watch in watches.take(2))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _WatchTile(kit: _kit, watch: watch),
                            ),
                        ],
                        if (last case (final office, final desk)) ...[
                          HkHeading(s.hkLastViewed),
                          _CounterTile(kit: _kit, office: office, desk: desk),
                        ],
                        // Then, for someone new, where to start; for the others, a quiet way back to it.
                        // (Offline, the message saying so comes first.)
                        if (newcomer && offices != null) ...[
                          const SizedBox(height: 14),
                          _StartCard(kit: _kit),
                          const _HowItWorks(),
                        ] else if (!newcomer) ...[
                          const SizedBox(height: 10),
                          _AddressRow(kit: _kit),
                        ],
                      ],
                      HkHeading(searching ? s.hkOffices : s.hkAllOffices,
                          trailing: offices == null ? null : '${shown.length}'),
                      if (shown.isNotEmpty) const _LeafLegend(),
                      if (offices == null && _failed)
                        QnaMessage(
                          icon: Icons.wifi_off_rounded,
                          title: s.hkLoadFailed,
                          action: FilledButton.tonalIcon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(s.retry),
                          ),
                        )
                      else if (offices == null)
                        for (var i = 0; i < 6; i++) const _SkeletonRow()
                      else if (shown.isEmpty)
                        QnaMessage(icon: Icons.search_off_rounded, title: s.hkNoMatch)
                      else
                        for (final office in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OfficeRow(kit: _kit, office: office, onTap: () => openOffice(context, _kit, office)),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// An office: straight to its calendar when it has one counter, else to
/// the counters.
void openOffice(BuildContext context, HikoreaKit kit, HkOffice office) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => office.desks.length == 1
        ? HkCalendarScreen(kit: kit, office: office, desk: office.desks.single)
        : HkCountersScreen(kit: kit, office: office),
  ));
}

class _Hero extends StatelessWidget {
  const _Hero({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    const radius = BorderRadius.vertical(bottom: Radius.circular(26));
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.hero.first, p.hero.last],
        ),
        borderRadius: radius,
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.hkLede, style: const TextStyle(fontSize: 15, height: 1.45, color: Colors.white)),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF292524)),
                    decoration: InputDecoration(
                      hintText: s.hkSearchHint,
                      hintStyle: const TextStyle(color: Color(0xFF78716C)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Brand.emerald700),
                      suffixIcon: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => controller.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                                onPressed: () {
                                  controller.clear();
                                  onChanged('');
                                },
                                tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF78716C)),
                              ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// My watches, with how many are active.
class _WatchesButton extends StatelessWidget {
  const _WatchesButton({required this.kit});

  final HikoreaKit kit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final count = kit.watches?.length ?? 0;
    return IconButton(
      onPressed: () => openWatches(context, kit),
      tooltip: s.hkMyWatches,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: Brand.gold300,
        textColor: const Color(0xFF3D2C05),
        child: const Icon(Icons.notifications_active_outlined),
      ),
    );
  }
}

/// The calendar of a counter, kept fresh while the tile shows; [builder]
/// gets null until it is in.
class _Live extends StatefulWidget {
  const _Live({required this.kit, required this.desk, required this.builder});

  final HikoreaKit kit;
  final int desk;
  final Widget Function(BuildContext context, HkCalendar? calendar) builder;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.kit.loadCalendar(widget.desk));
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.kit.calendarOf(widget.desk));
}

/// How a counter stands, in a line: a pill, or a quiet wait while it loads.
class _StandLine extends StatelessWidget {
  const _StandLine({required this.text, required this.tone});

  final String? text;
  final HkTone tone;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(width: 90, height: 3, child: LinearProgressIndicator()),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: HkPill(text, tone: tone, icon: switch (tone) {
        HkTone.open => Icons.event_available_rounded,
        HkTone.low => Icons.event_busy_rounded,
        _ => Icons.hourglass_top_rounded,
      }),
    );
  }
}

/// A watch: whose counter, which days, and whether any of them is free now.
class _WatchTile extends StatelessWidget {
  const _WatchTile({required this.kit, required this.watch});

  final HikoreaKit kit;
  final HkWatch watch;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final found = kit.deskOf(watch.deskSeq);
    final booth = watchBooth(watch, kit.language);
    return HkCard(
      onTap: found == null
          ? () => openWatches(context, kit)
          : () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => HkCalendarScreen(kit: kit, office: found.$1, desk: found.$2),
              ));
            },
      color: Color.alphaBlend(p.gold.withValues(alpha: 0.10), p.card),
      edge: p.gold.withValues(alpha: 0.4),
      child: Row(
        children: [
          const HkBadge('🔔'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  officeParts(watch.officeNameEn).place,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                ),
                Text(
                  '${dayMonth(watch.start, kit.language)} – ${dayMonth(watch.end, kit.language)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                ),
                if (booth.isNotEmpty && (found == null || found.$1.desks.length > 1))
                  Text(booth, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: p.inkSoft)),
                const SizedBox(height: 8),
                _Live(
                  kit: kit,
                  desk: watch.deskSeq,
                  builder: (context, calendar) {
                    if (calendar == null) return const _StandLine(text: null, tone: HkTone.none);
                    if (calendar.dormant) return _StandLine(text: s.hkNoDaysShort, tone: HkTone.low);
                    final today = kit.today;
                    final free = calendar.openDays(watch.start.isAfter(today) ? watch.start : today, until: watch.end);
                    return free.isEmpty
                        ? _StandLine(text: s.hkWatchFull, tone: HkTone.none)
                        : _StandLine(text: s.hkWatchFree(free.length), tone: HkTone.open);
                  },
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.inkMuted),
        ],
      ),
    );
  }
}

/// The counter looked at last, with its earliest free day, so coming back
/// is one tap and often none.
class _CounterTile extends StatelessWidget {
  const _CounterTile({required this.kit, required this.office, required this.desk});

  final HikoreaKit kit;
  final HkOffice office;
  final HkDesk desk;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final booth = boothName(desk, kit.language);
    return HkCard(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => HkCalendarScreen(kit: kit, office: office, desk: desk),
        ));
      },
      child: Row(
        children: [
          const HkBadge('🗓️'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  officeParts(office.nameEn).place,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                ),
                if (office.desks.length > 1 && booth.name.isNotEmpty)
                  Text(
                    booth.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.inkSoft),
                  ),
                const SizedBox(height: 8),
                _Live(
                  kit: kit,
                  desk: desk.seq,
                  builder: (context, calendar) {
                    if (calendar == null) return const _StandLine(text: null, tone: HkTone.none);
                    return _CounterStand(kit: kit, calendar: calendar);
                  },
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.inkMuted),
        ],
      ),
    );
  }
}

/// A counter's state in a pill: its earliest free day, all booked, or no
/// days on HiKorea at all.
class _CounterStand extends StatelessWidget {
  const _CounterStand({required this.kit, required this.calendar});

  final HikoreaKit kit;
  final HkCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (calendar.dormant) return _StandLine(text: s.hkNoDaysShort, tone: HkTone.low);
    final earliest = calendar.earliestOpen(kit.today);
    return earliest == null
        ? _StandLine(text: s.hkAllFullShort, tone: HkTone.none)
        : _StandLine(
            text: s.hkEarliestShort('${weekdayName(earliest, kit.language)}, ${dayMonth(earliest, kit.language)}'),
            tone: HkTone.open,
          );
  }
}

/// Where someone new starts: their office depends on their address.
class _StartCard extends StatelessWidget {
  const _StartCard({required this.kit});

  final HikoreaKit kit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return HkCard(
      color: p.cardSelected,
      edge: p.accent.withValues(alpha: 0.25),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.hkStartTitle,
                  style: TextStyle(fontFamily: Brand.displayFont, fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.hkStartBody, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HkAddressScreen(kit: kit)));
            },
            icon: const Icon(Icons.home_work_outlined),
            label: Text(s.hkAddressTitle),
          ),
          const SizedBox(height: 6),
          Text(s.hkStartOr, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.inkMuted)),
        ],
      ),
    );
  }
}

/// How it works, for someone new: find, see, book (or watch).
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget step(int n, String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                child: Text('$n', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
                    Text(body, style: TextStyle(fontSize: 13, height: 1.35, color: p.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.hkHowTitle.toUpperCase(),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: p.inkMuted)),
          step(1, s.hkStep1, s.hkStep1Body),
          step(2, s.hkStep2, s.hkStep2Body),
          step(3, s.hkStep3, s.hkStep3Body),
        ],
      ),
    );
  }
}

/// The address finder, for those who already know their way.
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.kit});

  final HikoreaKit kit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return HkCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HkAddressScreen(kit: kit)));
      },
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Icon(Icons.home_work_outlined, color: p.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(s.hkAddressCardTitle, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
          ),
          const SizedBox(width: 8),
          Text(s.hkAddressTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.accent)),
          Icon(Icons.chevron_right_rounded, color: p.accent),
        ],
      ),
    );
  }
}

/// An office in a list: how soon it has a free day, its place (every name
/// ends alike), what it is, how many counters, and its Korean name as
/// letters and signs have it.
class OfficeRow extends StatelessWidget {
  const OfficeRow({super.key, required this.kit, required this.office, required this.onTap, this.subtitle});

  final HikoreaKit kit;
  final HkOffice office;
  final VoidCallback onTap;

  /// Instead of the Korean name.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final parts = officeParts(office.nameEn);
    final kind = parts.branch
        ? (parts.of == null ? s.hkOfficeBranch : s.hkOfficeBranchOf(parts.of!))
        : s.hkOfficeMain;
    final below = subtitle ?? office.nameKo;
    return HkCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          _OfficeLeaf(kit: kit, office: office),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parts.place, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 1),
                Text(
                  [kind, if (office.desks.isNotEmpty) s.hkCounters(office.desks.length)].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.inkSoft),
                ),
                if (below != null && below.isNotEmpty)
                  Text(below, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.inkMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.inkMuted),
        ],
      ),
    );
  }
}

/// What the leaves in the office list say.
class _LeafLegend extends StatelessWidget {
  const _LeafLegend();

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded, size: 15, color: p.inkMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(AppLocalizations.of(context).hkLeafLegend,
                style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
          ),
        ],
      ),
    );
  }
}

/// A calendar leaf with an office's earliest free day: green within two
/// weeks, amber later, red when every day is booked; a bell when one of
/// this person's watches is there.
class _OfficeLeaf extends StatelessWidget {
  const _OfficeLeaf({required this.kit, required this.office});

  final HikoreaKit kit;
  final HkOffice office;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: kit, builder: _leaf);

  Widget _leaf(BuildContext context, Widget? _) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    for (final desk in office.desks) {
      kit.prefetch(desk.seq);
    }
    final (:kind, :day) = kit.outlookOf(office);
    final soon = day != null && day.difference(kit.today).inDays <= 14;
    final colours = hkTone(context, switch (kind) {
      HkOutlook.free => soon ? HkTone.open : HkTone.filling,
      HkOutlook.full => HkTone.low,
      _ => HkTone.none,
    });
    final strong = kind == HkOutlook.free || kind == HkOutlook.full;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (String? band, Widget? body, String label) = switch (kind) {
      HkOutlook.free => (
          monthShort(day!, kit.language),
          Text('${day.day}', style: TextStyle(fontSize: 20, height: 1, fontWeight: FontWeight.w800, color: colours.ink)),
          s.hkEarliestShort('${weekdayName(day, kit.language)}, ${dayMonth(day, kit.language)}'),
        ),
      HkOutlook.full => (s.hkLeafFull.toUpperCase(), Icon(Icons.event_busy_rounded, size: 20, color: colours.ink), s.hkAllFullShort),
      HkOutlook.retired => (null, Text('—', style: TextStyle(fontSize: 18, color: colours.ink)), s.hkNoDaysShort),
      HkOutlook.unknown => (null, Icon(Icons.cloud_off_rounded, size: 18, color: colours.ink), s.hkLoadFailed),
      HkOutlook.loading => (null, null, ''),
    };
    final watching = kit.watching(office);
    return Semantics(
      label: [if (label.isNotEmpty) label, if (watching) s.hkWatchingHere].join('. '),
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: colours.background, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: strong ? colours.ink : p.hairline,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: band == null
                        ? null
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              band,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: dark ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                  ),
                  Expanded(child: Center(child: body)),
                ],
              ),
            ),
            if (watching)
              PositionedDirectional(
                bottom: -5,
                end: -5,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(color: p.gold, shape: BoxShape.circle, border: Border.all(color: p.card, width: 2)),
                  child: const Icon(Icons.notifications_rounded, size: 11, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 68,
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.hairline)),
      ),
    );
  }
}

/// An office's counters, when it has more than one: they do the same work
/// but differ in place, floor or opening time.
class HkCountersScreen extends StatelessWidget {
  const HkCountersScreen({super.key, required this.kit, required this.office});

  final HikoreaKit kit;
  final HkOffice office;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: Text(officeName(office.nameEn)),
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          if (office.nameKo case final ko? when ko.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(ko, style: TextStyle(fontSize: 13, color: p.inkMuted)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              s.hkCountersTitle,
              style: TextStyle(fontFamily: Brand.displayFont, fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
            child: Text(s.hkCountersLede, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          ),
          for (final desk in office.desks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DeskCard(kit: kit, office: office, desk: desk),
            ),
        ],
      ),
    );
  }
}

class _DeskCard extends StatefulWidget {
  const _DeskCard({required this.kit, required this.office, required this.desk});

  final HikoreaKit kit;
  final HkOffice office;
  final HkDesk desk;

  @override
  State<_DeskCard> createState() => _DeskCardState();
}

class _DeskCardState extends State<_DeskCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final kit = widget.kit;
    final booth = boothName(widget.desk, kit.language);
    final details = inLanguage(widget.desk.details, kit.language.code).trim();
    return HkCard(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => HkCalendarScreen(kit: kit, office: widget.office, desk: widget.desk),
        ));
      },
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
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
          const SizedBox(height: 10),
          // Which counter takes bookings, and how soon: before the description.
          ListenableBuilder(
            listenable: kit,
            builder: (context, _) => _Live(
              kit: kit,
              desk: widget.desk.seq,
              builder: (context, calendar) => calendar == null
                  ? const _StandLine(text: null, tone: HkTone.none)
                  : _CounterStand(kit: kit, calendar: calendar),
            ),
          ),
          if (booth.afternoon) ...[
            const SizedBox(height: 8),
            HkPill(s.hkFromAfternoon, tone: HkTone.filling, icon: Icons.schedule_rounded),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              maxLines: _open ? null : 3,
              overflow: _open ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, height: 1.45, color: p.inkSoft),
            ),
            if (!_open && details.length > 140)
              TextButton(
                onPressed: () => setState(() => _open = true),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                child: Text(s.hkMore),
              ),
          ],
        ],
      ),
    );
  }
}
