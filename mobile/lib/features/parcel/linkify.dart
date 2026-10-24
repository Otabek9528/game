/// What a piece of a post's text is.
enum PieceKind { text, phone, telegram, link }

/// A piece of a post's text: plain, or something to tap and where it goes.
class TextPiece {
  const TextPiece(this.text, this.kind, [this.target]);

  final String text;
  final PieceKind kind;
  final Uri? target;

  @override
  String toString() => '${kind.name}:$text';
}

final _found = RegExp(
  // Links: https://… or a bare t.me/…
  r'(https?://\S+|(?<![\w.])t\.me/[\w/+]+)'
  // Telegram usernames, not the middle of an e-mail address.
  r'|((?<![\w.])@[A-Za-z][A-Za-z0-9_]{3,31})'
  // Phone numbers: digits with spaces, dashes or brackets between.
  r'|(\+?\d[\d \-()]{7,}\d)',
);

/// Couriers write their phone, their Telegram and links into the post; the
/// web page shows them as plain text. Here they can be tapped.
List<TextPiece> linkify(String text) {
  final pieces = <TextPiece>[];
  var at = 0;
  void plain(int end) {
    if (end > at) pieces.add(TextPiece(text.substring(at, end), PieceKind.text));
  }

  for (final m in _found.allMatches(text)) {
    if (m.start < at) continue;
    var found = m.group(0)!;
    final PieceKind kind;
    final Uri? target;
    if (m.group(1) != null) {
      // A sentence's full stop or a bracket after a link isn't part of it.
      found = found.replaceFirst(RegExp(r'[.,;:!?)\]»"]+$'), '');
      kind = PieceKind.link;
      target = Uri.tryParse(found.startsWith('http') ? found : 'https://$found');
    } else if (m.group(2) != null) {
      kind = PieceKind.telegram;
      target = Uri.parse('https://t.me/${found.substring(1)}');
    } else {
      final digits = found.replaceAll(RegExp(r'\D'), '');
      // Fewer digits: a price or a weight. More: not a phone.
      if (digits.length < 9 || digits.length > 15) continue;
      kind = PieceKind.phone;
      target = Uri(scheme: 'tel', path: '${found.startsWith('+') ? '+' : ''}$digits');
    }
    if (target == null) continue;
    plain(m.start);
    pieces.add(TextPiece(found, kind, target));
    at = m.start + found.length;
  }
  plain(text.length);
  return pieces;
}
