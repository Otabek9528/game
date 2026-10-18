import 'business_models.dart';

/// What a piece of an owner's description is.
enum PieceKind { text, link, phone, tag, address }

class DescPiece {
  const DescPiece(this.kind, this.text, [this.value]);

  final PieceKind kind;
  final String text;

  /// A link's full address; a phone's digits.
  final String? value;

  @override
  String toString() => '${kind.name}:$text';
}

/// One line of a description, as its owner wrote it, with what the page
/// adds: its "Label:" in weight, and what can be tapped.
class DescLine {
  const DescLine({this.label, required this.pieces, this.address});

  final String? label;
  final List<DescPiece> pieces;

  /// The address in the line, to copy or look up on a map.
  final String? address;
}

final _label = RegExp(r'^([^\s:/][^:/]{0,22}?)\s*[:：]\s+(?=\S)');
final _letter = RegExp(r'\p{L}', unicode: true);
final _addressLabel =
    RegExp(r'^(?:manzil|manzilimiz|adres|address|joylashuv|lokatsiya|location|주소)\b', caseSensitive: false);
final _leadingNonLetters = RegExp(r'^[^\p{L}]+', unicode: true);

/// A Korean street address: up to two place names, a city, county or
/// district, then a road ("…로" / "…길") and its number.
final _koreanAddress = RegExp(r'(?:[가-힣]{2,}\s+){0,2}[가-힣]+(?:시|군|구|읍|면)\s+[가-힣0-9\s\-]*?(?:로|길)\s*\d+(?:-\d+)?');

/// Mobiles and landlines with an area code, and the 15xx/16xx/18xx-xxxx
/// company numbers. Years ("1998-2024") start with 19 and stay text.
final _phone = RegExp(r'(?:\+82[\s-]?0?\d{1,2}|\b0\d{1,2})[\s-]?\d{3,4}[\s-]?\d{4}\b|\b1[568]\d{2}-\d{4}\b');
final _hashtag = RegExp(r'(^|\s)(#[\p{L}\p{N}_]{2,})', unicode: true);
final _trailing = RegExp(r'''[.,;:!?)\]"'”’]+$''');
final _wrapping = RegExp(r'''^[\s"'“”‘’«»(\[]+|[\s"'“”‘’«»)\],.;]+$''');

/// The description as blocks of lines: a blank line is a gap between
/// blocks, not an empty line of its own. Nothing is lifted out, reordered
/// or dropped.
List<List<DescLine>> parseDescription(String text) => [
      for (final chunk in text.replaceAll(RegExp(r'\r\n?'), '\n').split(RegExp(r'\n\s*\n')))
        if (chunk.split('\n').where((l) => l.trim().isNotEmpty).toList() case final lines when lines.isNotEmpty)
          [for (final line in lines) _line(line.trim())],
    ];

DescLine _line(String raw) {
  var rest = raw;
  final address = _findAddress(rest);
  String? label;
  final m = _label.firstMatch(rest);
  if (m != null && _letter.hasMatch(m[1]!) && !RegExp(r'^https?$', caseSensitive: false).hasMatch(m[1]!)) {
    label = rest.substring(0, m.end);
    rest = rest.substring(m.end);
  }
  return DescLine(label: label, pieces: _pieces(rest, address?.$1), address: address?.$2);
}

/// The address in a line: the whole value of a line labelled "Manzil: …",
/// or a Korean street address wherever it is. (What to mark, what to search.)
(String, String)? _findAddress(String line) {
  final m = _label.firstMatch(line);
  if (m != null && _addressLabel.hasMatch(m[1]!.replaceFirst(_leadingNonLetters, ''))) {
    final query = line.substring(m.end).replaceAll(_wrapping, '');
    if (query.length >= 4) return (query, query);
  }
  final k = _koreanAddress.firstMatch(line);
  if (k != null) return (k[0]!.trim(), k[0]!.trim());
  return null;
}

List<DescPiece> _pieces(String text, String? address) {
  final spans = <(int, int, PieceKind, String)>[];
  if (address != null) {
    final at = text.indexOf(address);
    if (at != -1) spans.add((at, at + address.length, PieceKind.address, address));
  }
  for (final m in urlPattern.allMatches(text)) {
    final value = m[0]!.replaceFirst(_trailing, '');
    if (value.isNotEmpty) spans.add((m.start, m.start + value.length, PieceKind.link, value));
  }
  for (final m in _phone.allMatches(text)) {
    spans.add((m.start, m.end, PieceKind.phone, m[0]!));
  }
  for (final m in _hashtag.allMatches(text)) {
    final start = m.start + m[1]!.length;
    spans.add((start, start + m[2]!.length, PieceKind.tag, m[2]!));
  }
  // Where two overlap, the one found first wins: an address over a number in
  // it, a link over a number in its path.
  final taken = <(int, int, PieceKind, String)>[];
  for (final s in spans) {
    if (!taken.any((o) => s.$1 < o.$2 && o.$1 < s.$2)) taken.add(s);
  }
  taken.sort((a, b) => a.$1 - b.$1);
  final pieces = <DescPiece>[];
  var last = 0;
  for (final (start, end, kind, value) in taken) {
    if (start > last) pieces.add(DescPiece(PieceKind.text, text.substring(last, start)));
    pieces.add(switch (kind) {
      PieceKind.link => DescPiece(kind, value, RegExp(r'^https?://', caseSensitive: false).hasMatch(value) ? value : 'https://$value'),
      PieceKind.phone => DescPiece(kind, value, value.replaceAll(RegExp(r'[^\d+]'), '')),
      _ => DescPiece(kind, value),
    });
    last = end;
  }
  if (last < text.length) pieces.add(DescPiece(PieceKind.text, text.substring(last)));
  return pieces;
}

/// The maps a link can be, named in the app's language.
enum MapHost { naver, kakao, google }

/// What a pasted link is, from its host: a brand's name, or a map; and which
/// kind of link it opens as. The map hosts are tested before the messenger
/// and search hosts they sit under.
({String? brand, MapHost? map, String kind}) hostOf(String url) {
  final host = (Uri.tryParse(url)?.host ?? '').toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  bool any(String pattern) => RegExp(pattern).hasMatch(host);
  if (any(r'(^|\.)play\.google\.com$')) return (brand: 'Google Play', map: null, kind: 'playstore');
  if (any(r'(^|\.)(apps|itunes)\.apple\.com$')) return (brand: 'App Store', map: null, kind: 'appstore');
  if (any(r'(^|\.)instagram\.com$')) return (brand: 'Instagram', map: null, kind: 'instagram');
  if (any(r'(^|\.)tiktok\.com$')) return (brand: 'TikTok', map: null, kind: 'tiktok');
  if (any(r'(^|\.)(t|telegram)\.me$')) return (brand: 'Telegram', map: null, kind: 'telegram');
  if (any(r'^map\.naver\.com$|(^|\.)naver\.me$')) return (brand: null, map: MapHost.naver, kind: 'website');
  if (any(r'^map\.kakao\.com$')) return (brand: null, map: MapHost.kakao, kind: 'website');
  if (any(r'^maps\.google\.|^maps\.app\.goo\.gl$|^goo\.gl$')) return (brand: null, map: MapHost.google, kind: 'website');
  if (any(r'(^|\.)kakao\.com$')) return (brand: 'KakaoTalk', map: null, kind: 'kakao');
  if (any(r'(^|\.)(youtube\.com|youtu\.be)$')) return (brand: 'YouTube', map: null, kind: 'youtube');
  if (any(r'(^|\.)(facebook|fb)\.com$|^fb\.me$')) return (brand: 'Facebook', map: null, kind: 'facebook');
  return (brand: host.isEmpty ? url : host, map: null, kind: 'website');
}

/// The two maps people in Korea navigate by, searched for [query].
Uri naverMap(String query) => Uri.parse('https://map.naver.com/p/search/${Uri.encodeComponent(query)}');
Uri kakaoMap(String query) => Uri.parse('https://map.kakao.com/link/search/${Uri.encodeComponent(query)}');
