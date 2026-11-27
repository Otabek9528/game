import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'places_kit.dart';
import 'places_models.dart';
import 'places_parts.dart';

/// A prayer's name: "Bomdod", "Фаджр", "Fajr".
String prayerName(AppLocalizations s, String prayer) => switch (prayer) {
      'fajr' => s.ptFajr,
      'dhuhr' => s.ptDhuhr,
      'asr' => s.ptAsr,
      'maghrib' => s.ptMaghrib,
      'isha' => s.ptIsha,
      _ => s.ptJumuah,
    };

String eidName(AppLocalizations s, String kind) => kind == 'fitr' ? s.ptFitr : s.ptAdha;

/// "24 fevral 2027", "24 февраля 2027", "24 February 2027".
String timesDate(DateTime day, AppLanguage language) => DateFormat('d MMMM y', language.code).format(day);

int _minutes(String hhmm) => int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));

String _two(int n) => n.toString().padLeft(2, '0');

String _hhmm(int minutes) {
  final m = minutes.clamp(0, 23 * 60 + 59);
  return '${_two(m ~/ 60)}:${_two(m % 60)}';
}

/// The prayer marked "next": the first still ahead today in Korea (Juma in
/// Peshin's place on a Friday), or after Xufton the first of the morning.
String? nextPrayer(Map<String, String> daily, DateTime now) {
  final korea = now.toUtc().add(const Duration(hours: 9));
  final friday = korea.weekday == DateTime.friday;
  final order = [
    for (final p in MosqueSchedule.fivePrayers) p == 'dhuhr' && friday && daily.containsKey('jumuah') ? 'jumuah' : p,
  ].where(daily.containsKey).toList();
  final minutes = korea.hour * 60 + korea.minute;
  for (final p in order) {
    if (_minutes(daily[p]!) > minutes) return p;
  }
  return order.firstOrNull;
}

/// A date not changed for 60 days, in amber: the times may be old.
({Color ink, Color fill, Color dot}) _amber(BuildContext context) => Theme.of(context).brightness == Brightness.dark
    ? (ink: const Color(0xFFF2B766), fill: const Color(0x24D97706), dot: const Color(0xFFF59E0B))
    : (ink: const Color(0xFF8A4B00), fill: const Color(0xFFFFF7E6), dot: const Color(0xFFD97706));

/// "Last updated: 24 February 2027"; in amber, with a dot, when [stale].
class _Updated extends StatelessWidget {
  const _Updated({required this.day, required this.stale, required this.language, this.boxed = false});

  final DateTime? day;
  final bool stale;
  final AppLanguage language;

  /// On a tinted strip of its own (the daily times), or a plain line (an Eid).
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) return const SizedBox.shrink();
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final amber = _amber(context);
    final text = Text(
      s.ptUpdated(timesDate(day, language)),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: stale ? FontWeight.w700 : FontWeight.w400,
        color: stale ? amber.ink : p.inkMuted,
      ),
    );
    if (!stale) return text;
    final line = Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: amber.dot, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Flexible(child: text),
      ],
    );
    if (!boxed) return line;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: amber.fill, borderRadius: BorderRadius.circular(10)),
      child: line,
    );
  }
}

/// The mosque's own times on its page: the daily ones with the next one
/// marked, then the two Eids under a rule, each part with the day it was
/// last changed. A mosque without times still shows where they will be.
class MosqueTimesCard extends StatelessWidget {
  const MosqueTimesCard({
    super.key,
    required this.schedule,
    required this.language,
    required this.now,
    required this.onEditEid,
  });

  final MosqueSchedule schedule;
  final AppLanguage language;
  final DateTime now;
  final VoidCallback onEditEid;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final next = nextPrayer(schedule.daily, now);
    final shown = [for (final prayer in MosqueSchedule.prayers) if (schedule.daily[prayer] != null) prayer];
    return PlacesCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!schedule.hasDaily)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
              child: Text(s.ptEmpty, style: TextStyle(fontSize: 15, color: p.inkSoft)),
            )
          else ...[
            for (final (i, prayer) in shown.indexed)
              _TimeRow(
                name: prayerName(s, prayer),
                time: schedule.daily[prayer]!,
                next: prayer == next,
                juma: prayer == 'jumuah',
                rule: i < shown.length - 1 && prayer != next && shown[i + 1] != next && shown[i + 1] != 'jumuah',
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _Updated(day: schedule.dailyUpdated, stale: schedule.dailyStale, language: language, boxed: true),
            ),
          ],
          // Eid: the same card, set apart by a rule and its gold label.
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Divider(height: 1, color: p.goldSoft),
          ),
          Row(
            children: [
              const SizedBox(width: 6),
              Icon(Icons.nightlight_round, size: 16, color: p.goldInk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.ptEidTitle.toUpperCase(),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: p.goldInk),
                ),
              ),
              IconButton(
                onPressed: onEditEid,
                tooltip: schedule.hasEid ? s.ptEditEid : s.ptAddEid,
                color: p.accent,
                icon: Icon(schedule.hasEid ? Icons.edit_rounded : Icons.add_rounded, size: 20),
              ),
            ],
          ),
          for (final (i, kind) in MosqueSchedule.eidKinds.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 6, endIndent: 6, color: p.hairline),
            _EidRow(name: eidName(s, kind), times: schedule.eids[kind], language: language),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.name, required this.time, required this.next, required this.juma, required this.rule});

  final String name;
  final String time;
  final bool next;
  final bool juma;

  /// A hairline under it, to the next plain row.
  final bool rule;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final colour = next ? p.accent : p.ink;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      margin: EdgeInsets.only(top: juma ? 6 : (next ? 3 : 0), bottom: next ? 3 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: next ? p.cardSelected : (juma ? p.page : null),
        borderRadius: next || juma ? BorderRadius.circular(12) : null,
        border: rule ? Border(bottom: BorderSide(color: p.hairline)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(name,
                    style: TextStyle(fontSize: 16, fontWeight: juma || next ? FontWeight.w700 : FontWeight.w500, color: colour)),
                if (next)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: p.accent),
                    ),
                    child: Text(s.ptNext, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.accent)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: TextStyle(
              fontSize: 19,
              fontWeight: next ? FontWeight.w900 : FontWeight.w700,
              color: colour,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _EidRow extends StatelessWidget {
  const _EidRow({required this.name, required this.times, required this.language});

  final String name;
  final EidTimes? times;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final times = this.times;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The name at most a little over half the row (it wraps with large
          // text); the times take the rest, flush right.
          LayoutBuilder(
            builder: (context, box) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.55),
                  child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: p.ink)),
                ),
                const SizedBox(width: 12),
                Expanded(
                child: times == null
                    ? Text(s.ptNotAdded, textAlign: TextAlign.end, style: TextStyle(fontSize: 14, color: p.inkSoft))
                    // Three times; on a narrow screen they go on to a second line.
                    : Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 2,
                        children: [
                          for (final t in times.sessions)
                            Text(
                              t,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                ),
              ],
            ),
          ),
          if (times != null) ...[
            const SizedBox(height: 3),
            _Updated(day: times.updated, stale: times.stale, language: language),
          ],
        ],
      ),
    );
  }
}

/// Which part a sheet changes.
enum TimesPart { daily, eid }

/// Setting times: every prayer is a tile in a grid that never moves, and one
/// wheel under the grid sets the picked tile; its place is kept from the
/// start, so nothing shifts while times are set one after another, and an
/// empty tile (dashed, "—") stays in sight until it is filled. Pops with the
/// mosque's times as saved.
class TimesSheet extends StatefulWidget {
  const TimesSheet({super.key, required this.kit, required this.placeId, required this.schedule, required this.part});

  final PlacesKit kit;
  final int placeId;
  final MosqueSchedule schedule;
  final TimesPart part;

  @override
  State<TimesSheet> createState() => _TimesSheetState();
}

class _TimesSheetState extends State<TimesSheet> {
  /// Where the wheel starts for a prayer nobody has given a time yet.
  static const _starts = {
    'fajr': '05:30',
    'dhuhr': '13:00',
    'asr': '16:00',
    'maghrib': '18:00',
    'isha': '20:00',
    'jumuah': '13:00',
  };

  /// Keep in step with EID_SESSIONS_MAX on the server.
  static const _sessionsMax = 3;

  /// The wheel's height, and its heading's: the space kept for them.
  static const _wheelHeight = 160.0;
  static const _editorHeight = 48 + _wheelHeight + 8;

  late final Map<String, String?> _dailyStart = {
    for (final p in MosqueSchedule.prayers) p: widget.schedule.daily[p],
  };
  late final Map<String, String?> _daily = Map.of(_dailyStart);
  late final Map<String, List<String>> _eidStart = {
    for (final k in MosqueSchedule.eidKinds) k: [...?widget.schedule.eids[k]?.sessions],
  };
  late final Map<String, List<String>> _eid = {for (final e in _eidStart.entries) e.key: [...e.value]};

  /// The picked tile: a prayer ("fajr") or an Eid prayer ("fitr:1").
  String? _pick;

  /// Changes when a tile is picked again after a removal, so its wheel starts afresh.
  int _round = 0;
  bool _busy = false;
  String? _error;

  bool get _isDaily => widget.part == TimesPart.daily;

  String? _value(String key) {
    if (_isDaily) return _daily[key];
    final (kind, i) = _eidKey(key);
    final list = _eid[kind]!;
    return i < list.length ? list[i] : null;
  }

  (String, int) _eidKey(String key) {
    final parts = key.split(':');
    return (parts[0], int.parse(parts[1]));
  }

  void _set(String key, String value) {
    if (_isDaily) {
      _daily[key] = value;
    } else {
      final (kind, i) = _eidKey(key);
      _eid[kind]![i] = value;
    }
  }

  void _remove(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isDaily) {
        _daily[key] = null;
      } else {
        final (kind, i) = _eidKey(key);
        _eid[kind]!.removeAt(i);
      }
      _pick = null;
      _round++;
    });
  }

  void _choose(String key) {
    if (_pick == key) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_value(key) == null) _set(key, _starts[key] ?? '07:00');
      _pick = key;
      _error = null;
    });
  }

  void _addSession(String kind) {
    HapticFeedback.selectionClick();
    final list = _eid[kind]!;
    setState(() {
      list.add(list.isEmpty ? '07:00' : _hhmm(_minutes(list.last) + 60));
      _pick = '$kind:${list.length - 1}';
      _round++;
      _error = null;
    });
  }

  /// Only what changed goes to the server, so two people editing different
  /// prayers at once do not undo each other.
  Map<String, Object?> _changes() {
    if (_isDaily) {
      return {
        for (final p in MosqueSchedule.prayers)
          if (_daily[p] != _dailyStart[p]) p: _daily[p],
      };
    }
    List<String> clean(List<String> l) => l.toSet().toList()..sort();
    return {
      for (final k in MosqueSchedule.eidKinds)
        if (clean(_eid[k]!).join() != clean(_eidStart[k]!).join()) k: clean(_eid[k]!),
    };
  }

  Future<void> _save() async {
    final s = AppLocalizations.of(context);
    final changes = _changes();
    if (changes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = await widget.kit.auth();
      if (auth.isEmpty) throw const PlacesException('offline');
      final source = widget.kit.source;
      final saved = _isDaily
          ? await source.saveTimes(auth, widget.placeId, changes.cast<String, String?>())
          : await source.saveEid(auth, widget.placeId, changes.cast<String, List<String>>());
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, saved);
    } on PlacesException catch (e) {
      if (mounted) setState(() => _error = placesMessage(s, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    String fullName(String key) {
      if (_isDaily) return prayerName(s, key);
      final (kind, i) = _eidKey(key);
      return '${eidName(s, kind)}, ${s.ptSession(i + 1)}';
    }

    final picked = _pick;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(_isDaily ? Icons.schedule_rounded : Icons.nightlight_round, color: _isDaily ? p.accent : p.goldInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isDaily ? s.ptSheetTitle : s.ptEidTitle,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isDaily)
          _Grid(
            children: [
              for (final prayer in MosqueSchedule.prayers)
                _Tile(
                  key: ValueKey('times-tile:$prayer'),
                  name: prayerName(s, prayer),
                  fullName: prayerName(s, prayer),
                  time: _daily[prayer],
                  picked: picked == prayer,
                  onTap: () => _choose(prayer),
                ),
            ],
          )
        else
          for (final kind in MosqueSchedule.eidKinds) ...[
            Padding(
              padding: EdgeInsets.only(top: kind == 'fitr' ? 0 : 10, bottom: 6),
              child: Text(
                eidName(s, kind).toUpperCase(),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: p.goldInk),
              ),
            ),
            _Grid(
              children: [
                for (final (i, t) in _eid[kind]!.indexed)
                  _Tile(
                    key: ValueKey('times-tile:$kind:$i'),
                    name: s.ptSession(i + 1),
                    fullName: '${eidName(s, kind)}, ${s.ptSession(i + 1)}',
                    time: t,
                    picked: picked == '$kind:$i',
                    onTap: () => _choose('$kind:$i'),
                  ),
                if (_eid[kind]!.length < _sessionsMax)
                  _AddTile(
                    key: ValueKey('times-tile:$kind:add'),
                    label: s.ptAdd,
                    semantics: '${eidName(s, kind)}: ${s.ptAddSession}',
                    onTap: () => _addSession(kind),
                  ),
              ],
            ),
          ],
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Divider(height: 1, color: p.hairline),
        ),
        // The wheel's place, kept with or without a pick.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _editorHeight),
          child: picked == null || _value(picked) == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.ptPick, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.inkSoft)),
                        const SizedBox(height: 6),
                        Text(s.ptLive, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName(picked),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.accent),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _remove(picked),
                          tooltip: s.ptRemove(fullName(picked)),
                          color: p.inkMuted,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    _TimeWheel(
                      key: ValueKey('$picked#$_round'),
                      value: _value(picked)!,
                      height: _wheelHeight,
                      onChanged: (v) => setState(() => _set(picked, v)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
        ),
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.error)),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: Text(s.plCancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : Text(s.ptSave),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tiles three to a row, each row as tall as its tallest tile.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 3) {
      final row = children.sublist(i, (i + 3).clamp(0, children.length));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < 3; j++) ...[
              if (j > 0) const SizedBox(width: 8),
              Expanded(child: j < row.length ? row[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in rows.indexed) ...[if (i > 0) const SizedBox(height: 8), r],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.name, required this.fullName, required this.time, required this.picked, required this.onTap});

  final String name;

  /// For the screen reader: "Ramazon hayiti, 2-jamoat".
  final String fullName;
  final String? time;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final time = this.time;
    final empty = time == null;
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: picked,
      label: '$fullName, ${time ?? s.ptNotAdded}',
      excludeSemantics: true,
      child: CustomPaint(
        foregroundPainter: empty ? _DashedBorder(colour: p.inkMuted, radius: 14) : null,
        child: Material(
          color: picked ? p.cardSelected : (empty ? Colors.transparent : p.page),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: empty
                ? BorderSide.none
                : BorderSide(color: picked ? p.accent : p.hairline, width: picked ? 2 : 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: picked ? p.accent : p.inkSoft),
                    ),
                    Text(
                      time ?? '—',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: picked ? p.accent : (empty ? p.inkMuted : p.ink),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({super.key, required this.label, required this.semantics, required this.onTap});

  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: CustomPaint(
        foregroundPainter: _DashedBorder(colour: p.accent, radius: 14),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: p.accent),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.accent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed rounded edge: a tile not filled yet.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.colour, required this.radius});

  final Color colour;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.7));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.colour != colour || old.radius != radius;
}

/// Hours and minutes, each a wheel that goes round; the value is wherever
/// they come to rest.
class _TimeWheel extends StatefulWidget {
  const _TimeWheel({super.key, required this.value, required this.height, required this.onChanged});

  final String value;
  final double height;
  final ValueChanged<String> onChanged;

  @override
  State<_TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<_TimeWheel> {
  late int _hour = int.parse(widget.value.substring(0, 2));
  late int _minute = int.parse(widget.value.substring(3, 5));
  late final _hours = FixedExtentScrollController(initialItem: _hour);
  late final _minutes = FixedExtentScrollController(initialItem: _minute);

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Widget _wheel(String label, int count, FixedExtentScrollController controller, ValueChanged<int> onSelected) {
    final p = VegukinPalette.of(context);
    // The app's own font: the picker would otherwise ask for Apple's.
    final digits = Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: p.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return SizedBox(
      width: 84,
      child: Semantics(
        label: label,
        child: CupertinoPicker(
          scrollController: controller,
          itemExtent: 40,
          looping: true,
          // The selection band is drawn once, across both wheels.
          selectionOverlay: const SizedBox.shrink(),
          onSelectedItemChanged: (i) => onSelected(((i % count) + count) % count),
          children: [
            for (var i = 0; i < count; i++)
              Center(child: Text(_two(i), style: digits)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      height: widget.height,
      decoration: BoxDecoration(color: p.page, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            right: 12,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.cardSelected,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.accent.withValues(alpha: 0.35)),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _wheel(s.ptHour, 24, _hours, (h) {
                _hour = h;
                widget.onChanged('${_two(_hour)}:${_two(_minute)}');
              }),
              Text(':', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.accent)),
              _wheel(s.ptMinute, 60, _minutes, (m) {
                _minute = m;
                widget.onChanged('${_two(_hour)}:${_two(_minute)}');
              }),
            ],
          ),
        ],
      ),
    );
  }
}
