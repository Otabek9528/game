import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../parcel/linkify.dart';

/// A stretch of a formatted message with one look.
@immutable
class RichRun {
  const RichRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.href,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  /// Where it links to; null for plain words.
  final String? href;

  @override
  bool operator ==(Object other) =>
      other is RichRun &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.strike == strike &&
      other.href == href;

  @override
  int get hashCode => Object.hash(text, bold, italic, underline, strike, href);

  @override
  String toString() =>
      'RichRun(${[if (bold) 'b', if (italic) 'i', if (underline) 'u', if (strike) 's', ?href].join(',')} "$text")';
}

/// A paragraph of the message, or a quote.
@immutable
class RichBlock {
  const RichBlock(this.runs, {this.quote = false});

  final List<RichRun> runs;
  final bool quote;

  String get text => runs.map((r) => r.text).join();
}

final _tag = RegExp(r'<(/?)(b|i|u|s|a|blockquote)(?:\s+href="([^"]*)")?\s*>');

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#x27;', "'")
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');

/// A campaign message as the server keeps it — Telegram's HTML: <b> <i> <u>
/// <s> <a href> <blockquote>, \n between lines, nothing else — as blocks of
/// runs. Anything else that looks like a tag is shown as written.
List<RichBlock> parseRichMessage(String html) {
  final blocks = <RichBlock>[];
  var runs = <RichRun>[];
  var bold = 0, italic = 0, underline = 0, strike = 0;
  var quote = false;
  String? href;

  void flush() {
    // The line break that ends a block belongs to the block, not the next one.
    final kept = [...runs];
    if (kept.isNotEmpty && kept.first.text.startsWith('\n')) {
      final f = kept.first;
      kept[0] = RichRun(
        f.text.substring(1),
        bold: f.bold,
        italic: f.italic,
        underline: f.underline,
        strike: f.strike,
        href: f.href,
      );
    }
    if (kept.isNotEmpty && kept.last.text.endsWith('\n')) {
      final l = kept.last;
      kept[kept.length - 1] = RichRun(
        l.text.substring(0, l.text.length - 1),
        bold: l.bold,
        italic: l.italic,
        underline: l.underline,
        strike: l.strike,
        href: l.href,
      );
    }
    kept.removeWhere((r) => r.text.isEmpty);
    if (kept.isNotEmpty) blocks.add(RichBlock(kept, quote: quote));
    runs = <RichRun>[];
  }

  void text(String raw) {
    if (raw.isEmpty) return;
    runs.add(
      RichRun(
        _unescape(raw),
        bold: bold > 0,
        italic: italic > 0,
        underline: underline > 0,
        strike: strike > 0,
        href: href,
      ),
    );
  }

  var at = 0;
  for (final m in _tag.allMatches(html)) {
    text(html.substring(at, m.start));
    at = m.end;
    final closing = m[1] == '/';
    final step = closing ? -1 : 1;
    switch (m[2]) {
      case 'b':
        bold = (bold + step).clamp(0, 99);
      case 'i':
        italic = (italic + step).clamp(0, 99);
      case 'u':
        underline = (underline + step).clamp(0, 99);
      case 's':
        strike = (strike + step).clamp(0, 99);
      case 'a':
        href = closing ? null : _unescape(m[3] ?? '');
        if (href != null && href.isEmpty) href = null;
      case 'blockquote':
        flush();
        quote = !closing;
    }
  }
  text(html.substring(at));
  flush();
  return blocks;
}

/// A campaign message, formatted: bold, italic, underline, strikethrough,
/// links and quotes. Addresses, Telegram names and phone numbers written in
/// the text can be tapped too, as in plain messages. Selectable.
class RichMessage extends StatefulWidget {
  const RichMessage(this.html, {super.key, required this.style, required this.onLink});

  final String html;
  final TextStyle style;
  final ValueChanged<Uri> onLink;

  @override
  State<RichMessage> createState() => _RichMessageState();
}

class _RichMessageState extends State<RichMessage> {
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
  }

  TapGestureRecognizer _tap(Uri uri) {
    final tap = TapGestureRecognizer()..onTap = () => widget.onLink(uri);
    _taps.add(tap);
    return tap;
  }

  List<InlineSpan> _spans(RichBlock block, TextStyle linkStyle) {
    final spans = <InlineSpan>[];
    for (final run in block.runs) {
      final style = TextStyle(
        fontWeight: run.bold ? FontWeight.w700 : null,
        fontStyle: run.italic ? FontStyle.italic : null,
        decoration: TextDecoration.combine([
          if (run.underline) TextDecoration.underline,
          if (run.strike) TextDecoration.lineThrough,
        ]),
      );
      final href = run.href;
      final uri = href == null ? null : Uri.tryParse(href);
      if (uri != null && uri.hasScheme) {
        spans.add(TextSpan(text: run.text, style: style.merge(linkStyle), recognizer: _tap(uri)));
        continue;
      }
      for (final piece in linkify(run.text)) {
        final target = piece.target;
        if (piece.kind != PieceKind.text && target != null) {
          final shown = piece.kind == PieceKind.link && piece.text.length > 50
              ? '${piece.text.substring(0, 47)}…'
              : piece.text;
          spans.add(TextSpan(text: shown, style: style.merge(linkStyle), recognizer: _tap(target)));
        } else {
          spans.add(TextSpan(text: piece.text, style: style));
        }
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final p = VegukinPalette.of(context);
    final link = TextStyle(color: p.accent, decoration: TextDecoration.underline);
    final blocks = parseRichMessage(widget.html);
    final children = <Widget>[];
    for (final block in blocks) {
      if (children.isNotEmpty) children.add(SizedBox(height: block.quote ? 10 : 6));
      final base = block.quote ? widget.style.copyWith(color: p.inkSoft) : widget.style;
      final text = SelectableText.rich(TextSpan(style: base, children: _spans(block, link)));
      children.add(
        block.quote
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.06),
                  border: Border(left: BorderSide(color: p.accent, width: 3)),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                ),
                child: text,
              )
            : text,
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
