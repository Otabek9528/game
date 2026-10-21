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

  Future<void> _refresh() => Future.wait([if (_kit.offices == null) _load(), _kit.refreshWatches()]);

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
          final shown = [for (final o in offices ?? const <HkOffice>[]) if (o.matches(_query)) o];
          final searching = _query.trim().isNotEmpty;
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
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 28 + MediaQuery.paddingOf(context).bottom),
                  sliver: SliverList.list(
                    children: [
                      if (!searching) ...[
                        _WatchingCard(kit: _kit),
                        _LastCounter(kit: _kit),
                        if ((_kit.watches?.isEmpty ?? true) && _kit.lastDesk == null) const _Steps(),
                        _AddressCard(kit: _kit),
                      ],
                      HkHeading(s.hkOffices, trailing: offices == null ? null : '${shown.length}'),
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
                            child: OfficeRow(office: office, onTap: () => openOffice(context, _kit, office)),
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

/// The watches running now, one tap from their list.
class _WatchingCard extends StatelessWidget {
  const _WatchingCard({required this.kit});

  final HikoreaKit kit;

  @override
  Widget build(BuildContext context) {
    final watches = kit.watches ?? const <HkWatch>[];
    if (watches.isEmpty) return const SizedBox.shrink();
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final next = watches.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HkCard(
        onTap: () => openWatches(context, kit),
        color: Color.alphaBlend(p.gold.withValues(alpha: 0.12), p.card),
        edge: p.gold.withValues(alpha: 0.45),
        child: Row(
          children: [
            const HkBadge('👁️'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.hkActiveWatches(watches.length),
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${officeName(next.officeNameEn)} · ${dayMonth(next.start, kit.language)} – ${dayMonth(next.end, kit.language)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.inkSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// The counter looked at last, so coming back is one tap.
class _LastCounter extends StatelessWidget {
  const _LastCounter({required this.kit});

  final HikoreaKit kit;

  @override
  Widget build(BuildContext context) {
    final seq = kit.lastDesk;
    final found = seq == null ? null : kit.deskOf(seq);
    if (found == null) return const SizedBox.shrink();
    final (office, desk) = found;
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final booth = boothName(desk, kit.language);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HkCard(
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
                    s.hkLastViewed.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: p.accent),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    officeName(office.nameEn),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                  if (office.desks.length > 1 && booth.name.isNotEmpty)
                    Text(
                      booth.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: p.inkSoft),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// How it works, for someone new to it.
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget step(int n, String text) => Expanded(
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: p.inkSoft),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HkCard(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [step(1, s.hkStep1), step(2, s.hkStep2), step(3, s.hkStep3)],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.kit});

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
      color: p.cardSelected,
      edge: p.accent.withValues(alpha: 0.25),
      child: Row(
        children: [
          const HkBadge('📍'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.hkAddressCardTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
                const SizedBox(height: 2),
                Text(s.hkAddressCardBody, style: TextStyle(fontSize: 13, color: p.inkSoft)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.accent),
        ],
      ),
    );
  }
}

/// An office in a list: its short code, names, and how many counters.
class OfficeRow extends StatelessWidget {
  const OfficeRow({super.key, required this.office, required this.onTap, this.subtitle});

  final HkOffice office;
  final VoidCallback onTap;

  /// Instead of the Korean name and counters.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final code = office.shortCode;
    final below = subtitle ??
        [if (office.nameKo case final ko? when ko.isNotEmpty) ko, s.hkCounters(office.desks.length)].join(' · ');
    return HkCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          code == null ? const HkBadge('🏢') : HkBadge(code, emoji: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(officeName(office.nameEn), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 2),
                Text(below, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.inkMuted),
        ],
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
