import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../parcel/linkify.dart';
import 'qna_models.dart';

/// A question in a list: its topic and views, the question, who answered.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, required this.onTap, this.saved = false});

  final QnaQuestion question;
  final VoidCallback onTap;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final views = question.views;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: TopicChip(question.topic))),
                  if (saved) ...[
                    Icon(Icons.bookmark_rounded, size: 17, color: p.gold),
                    const SizedBox(width: 8),
                  ],
                  if (views != null && views > 0) ...[
                    Icon(Icons.visibility_outlined, size: 15, color: p.inkMuted),
                    const SizedBox(width: 4),
                    Text(compactCount(views), style: TextStyle(fontSize: 12, color: p.inkMuted)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                question.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.5, height: 1.38, fontWeight: FontWeight.w700, color: p.ink),
              ),
              if (question.answerSource case final source?) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 15, color: p.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A question's topic, as the archive names it ("Other" when it doesn't).
class TopicChip extends StatelessWidget {
  const TopicChip(this.topic, {super.key});

  final String? topic;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        topic ?? AppLocalizations.of(context).qnaOther,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.accent),
      ),
    );
  }
}

/// A small gold label over a part of the page: "SAVOL", "JAVOB".
class SectionMark extends StatelessWidget {
  const SectionMark(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: VegukinPalette.of(context).gold),
      );
}

/// A hairline with a small star in the middle, between question and answer.
class StarDivider extends StatelessWidget {
  const StarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: p.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CustomPaint(size: const Size.square(16), painter: _Star(p.gold)),
        ),
        Expanded(child: Divider(color: p.hairline)),
      ],
    );
  }
}

class _Star extends CustomPainter {
  const _Star(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawPath(khatamPath(size.center(Offset.zero), size.width), Paint()..color = color);

  @override
  bool shouldRepaint(_Star old) => old.color != color;
}

/// Selectable text whose links can be tapped, shown shortened as on the web
/// page. Links glued to the word before them are set apart first.
class LinkedText extends StatefulWidget {
  const LinkedText(this.text, {super.key, required this.style, required this.onLink});

  final String text;
  final TextStyle style;
  final ValueChanged<Uri> onLink;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final tap in _taps) {
      tap.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
    final link = TextStyle(color: VegukinPalette.of(context).accent, decoration: TextDecoration.underline);
    final text = widget.text.replaceAllMapped(RegExp(r'(\S)(https?://)'), (m) => '${m[1]} ${m[2]}');
    final spans = <InlineSpan>[];
    for (final piece in linkify(text)) {
      // Links and Telegram names; numbers stay text (years, hadith numbers).
      if (piece.kind == PieceKind.link || piece.kind == PieceKind.telegram) {
        final tap = TapGestureRecognizer()..onTap = () => widget.onLink(piece.target!);
        _taps.add(tap);
        spans.add(TextSpan(
          text: piece.text.length > 50 ? '${piece.text.substring(0, 47)}…' : piece.text,
          style: link,
          recognizer: tap,
        ));
      } else {
        spans.add(TextSpan(text: piece.text));
      }
    }
    return SelectableText.rich(TextSpan(style: widget.style, children: spans));
  }
}

/// A message in the middle of a list: an icon, a title, a line, an action.
class QnaMessage extends StatelessWidget {
  const QnaMessage({super.key, required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: p.cardSelected, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: p.inkMuted),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
          if (body case final body?) ...[
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          ],
          if (action case final action?) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }
}
