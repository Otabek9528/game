import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/prayer_models.dart';
import 'day_view.dart';

/// Tahajjud, Ishraq and Duha: when each can be prayed on the shown day,
/// whether that is now, and (tapped open) why, with the hadith.
class NaflCard extends StatefulWidget {
  const NaflCard({super.key, required this.day, required this.now, required this.offset});

  final PrayerDay day;
  final DateTime now;

  /// Days from today to [day]; statuses are live only for today.
  final int offset;

  @override
  State<NaflCard> createState() => _NaflCardState();
}

class _NaflCardState extends State<NaflCard> {
  final _open = <Nafl>{};

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final windows = naflWindows(widget.day);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 17, color: p.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.naflTitle,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final nafl in Nafl.values)
            _Item(
              nafl: nafl,
              window: windows[nafl],
              now: widget.now,
              offset: widget.offset,
              open: _open.contains(nafl),
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() => _open.contains(nafl) ? _open.remove(nafl) : _open.add(nafl));
              },
            ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.nafl,
    required this.window,
    required this.now,
    required this.offset,
    required this.open,
    required this.onToggle,
  });

  final Nafl nafl;
  final NaflWindow? window;
  final DateTime now;
  final int offset;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final (IconData icon, String name, String? text, String quote, String source) = switch (nafl) {
      Nafl.tahajjud => (Icons.nightlight_round, s.tahajjudName, s.tahajjudText, s.tahajjudQuote, s.tahajjudSource),
      Nafl.ishraq => (Icons.wb_twilight_rounded, s.ishraqName, null, s.ishraqQuote, s.ishraqSource),
      Nafl.duha => (Icons.wb_sunny_rounded, s.duhaName, s.duhaText, s.duhaQuote, s.duhaSource),
    };

    final w = window;
    String? status;
    _Tone tone = _Tone.upcoming;
    var progress = -1.0;
    if (w != null) {
      if (offset != 0) {
        status = switch (offset) {
          1 => s.dayTomorrow,
          -1 => s.dayYesterday,
          _ => s.statusOtherDay,
        };
        tone = offset < 0 ? _Tone.passed : _Tone.upcoming;
      } else {
        final st = naflStatus(w, now);
        (status, tone) = switch (st.status) {
          NaflStatus.active => (s.statusNow, _Tone.active),
          NaflStatus.upcoming => (s.statusUpcoming, _Tone.upcoming),
          NaflStatus.passed => (s.statusPassed, _Tone.passed),
        };
        if (st.status == NaflStatus.active) progress = st.progress;
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.hairline))),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 26, child: Icon(icon, size: 20, color: p.gold)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.ink),
                              ),
                            ),
                            if (status != null) _Status(text: status, tone: tone),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          w?.text ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            color: p.inkMuted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (progress >= 0) ...[
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              color: p.accent,
                              backgroundColor: p.hairline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, size: 20, color: p.inkMuted),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: !open
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(32, 8, 4, 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (text != null)
                              Text(text, style: TextStyle(fontSize: 13, height: 1.6, color: p.inkSoft)),
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.only(left: 11),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: p.gold, width: 2)),
                              ),
                              child: Text(
                                quote,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic,
                                  color: p.ink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(source, style: TextStyle(fontSize: 11.5, color: p.inkMuted)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Tone { active, upcoming, passed }

class _Status extends StatelessWidget {
  const _Status({required this.text, required this.tone});

  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final (Color fg, Color bg) = switch (tone) {
      _Tone.active => (Colors.white, p.action),
      _Tone.upcoming => (p.accent, p.cardSelected),
      _Tone.passed => (p.inkMuted, p.badge),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
