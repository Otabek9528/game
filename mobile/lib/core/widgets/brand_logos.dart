import 'package:flutter/widgets.dart';

/// The services the app hands people over to, by their own marks: sign-in
/// (WhatsApp, Telegram, Google) and directions (Naver, Kakao, Google).
enum BrandLogo { whatsapp, telegram, google, naver, kakao }

/// [logo] drawn [size] square from its official shape. WhatsApp, Telegram
/// and Naver are Simple Icons' paths (CC0, simpleicons.org); Google's G is the
/// four-colour mark from its sign-in buttons; Kakao's is the speech bubble
/// Kakao's own login buttons carry, on its yellow.
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark(this.logo, {super.key, this.size = 24});

  final BrandLogo logo;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LogoPainter(logo)),
  );
}

const _whatsapp =
    'M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z';

const _telegram =
    'M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z';

const _naver = 'M16.273 12.845 7.376 0H0v24h7.726V11.156L16.624 24H24V0h-7.727v12.845Z';

/// The bubble alone, from Simple Icons' KakaoTalk mark.
const _kakaoBubble =
    'M12 18.75c-.591 0-1.1697-.0413-1.7317-.1209-.5626.3965-3.813 2.6797-4.1198 2.7225 0 0-.1258.0489-.2328-.0141s-.0876-.2282-.0876-.2282c.0322-.2198.8426-3.0183.992-3.5333-2.7452-1.36-4.5701-3.7686-4.5701-6.5135C2.25 6.8168 6.6152 3.375 12 3.375s9.75 3.4418 9.75 7.6875c0 4.2457-4.3652 7.6875-9.75 7.6875z';

/// Google's G, 48 units square, a colour per stroke.
const _google = [
  (
    Color(0xFFEA4335),
    'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
  ),
  (
    Color(0xFF4285F4),
    'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
  ),
  (
    Color(0xFFFBBC05),
    'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
  ),
  (
    Color(0xFF34A853),
    'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z',
  ),
];

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.logo);

  final BrandLogo logo;

  static final _paths = <String, Path>{};
  static Path _path(String d) => _paths.putIfAbsent(d, () => svgPath(d));

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..isAntiAlias = true;
    canvas.save();
    switch (logo) {
      case BrandLogo.whatsapp:
        canvas.scale(size.width / 24);
        canvas.drawPath(_path(_whatsapp), fill..color = const Color(0xFF25D366));
      case BrandLogo.telegram:
        // The plane is a hole in the circle: white under it, on any page.
        canvas.scale(size.width / 24);
        canvas.drawCircle(const Offset(12, 12), 11.5, fill..color = const Color(0xFFFFFFFF));
        canvas.drawPath(_path(_telegram), fill..color = const Color(0xFF26A5E4));
      case BrandLogo.google:
        canvas.scale(size.width / 48);
        for (final (colour, d) in _google) {
          canvas.drawPath(_path(d), fill..color = colour);
        }
      case BrandLogo.naver:
        // Naver's white N on its green square.
        canvas.scale(size.width / 24);
        canvas.drawRRect(
          RRect.fromLTRBR(0, 0, 24, 24, const Radius.circular(7.5)),
          fill..color = const Color(0xFF03C75A),
        );
        canvas.translate(6.6, 6.6);
        canvas.scale(10.8 / 24);
        canvas.drawPath(_path(_naver), fill..color = const Color(0xFFFFFFFF));
      case BrandLogo.kakao:
        // Kakao's black bubble on its yellow square.
        canvas.scale(size.width / 24);
        canvas.drawRRect(
          RRect.fromLTRBR(0, 0, 24, 24, const Radius.circular(7.5)),
          fill..color = const Color(0xFFFEE500),
        );
        canvas.translate(3.2, 2.2);
        canvas.scale(17.6 / 24);
        canvas.drawPath(_path(_kakaoBubble), fill..color = const Color(0xFF191919));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.logo != logo;
}

/// An SVG path's `d` as a [Path]: moves, lines, cubic and quadratic curves
/// (smooth ones too), elliptical arcs, closes; absolute and relative.
@visibleForTesting
Path svgPath(String d) {
  final path = Path();
  final scan = _Scanner(d);
  var command = '';
  var current = Offset.zero;
  var start = Offset.zero;
  Offset? cubicControl, quadControl;
  while (!scan.atEnd) {
    if (scan.nextIsCommand) {
      command = scan.command();
    } else if (command == 'M') {
      command = 'L'; // Pairs after a move are lines.
    } else if (command == 'm') {
      command = 'l';
    } else if (command == '' || command == 'Z' || command == 'z') {
      break; // Numbers where none can be: stop rather than loop.
    }
    final relative = command == command.toLowerCase();
    Offset point() {
      final x = scan.number(), y = scan.number();
      return relative ? current + Offset(x, y) : Offset(x, y);
    }

    Offset? nextCubic, nextQuad;
    switch (command.toUpperCase()) {
      case 'M':
        current = start = point();
        path.moveTo(current.dx, current.dy);
      case 'L':
        current = point();
        path.lineTo(current.dx, current.dy);
      case 'H':
        final x = scan.number();
        current = Offset(relative ? current.dx + x : x, current.dy);
        path.lineTo(current.dx, current.dy);
      case 'V':
        final y = scan.number();
        current = Offset(current.dx, relative ? current.dy + y : y);
        path.lineTo(current.dx, current.dy);
      case 'C':
        final c1 = point(), c2 = point(), end = point();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        nextCubic = c2;
        current = end;
      case 'S':
        final c1 = cubicControl == null ? current : current * 2 - cubicControl;
        final c2 = point(), end = point();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        nextCubic = c2;
        current = end;
      case 'Q':
        final c = point(), end = point();
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        nextQuad = c;
        current = end;
      case 'T':
        final c = quadControl == null ? current : current * 2 - quadControl;
        final end = point();
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        nextQuad = c;
        current = end;
      case 'A':
        final rx = scan.number(), ry = scan.number(), rotation = scan.number();
        final large = scan.flag(), sweep = scan.flag();
        final end = point();
        path.arcToPoint(end, radius: Radius.elliptical(rx, ry), rotation: rotation, largeArc: large, clockwise: sweep);
        current = end;
      case 'Z':
        path.close();
        current = start;
    }
    cubicControl = nextCubic;
    quadControl = nextQuad;
  }
  return path;
}

/// Reads a path's numbers, which SVG lets run together ("-.3.5", "01-5"
/// for two arc flags and a number).
class _Scanner {
  _Scanner(this._s);

  final String _s;
  var _i = 0;

  static const _commands = 'MmLlHhVvCcSsQqTtAaZz';

  void _skip() {
    while (_i < _s.length && ' ,\n\r\t'.contains(_s[_i])) {
      _i++;
    }
  }

  bool get atEnd {
    _skip();
    return _i >= _s.length;
  }

  bool get nextIsCommand {
    _skip();
    return _i < _s.length && _commands.contains(_s[_i]);
  }

  String command() {
    _skip();
    return _s[_i++];
  }

  bool _digit(int i) => i < _s.length && _s.codeUnitAt(i) >= 48 && _s.codeUnitAt(i) <= 57;

  double number() {
    _skip();
    final from = _i;
    if (_i < _s.length && (_s[_i] == '-' || _s[_i] == '+')) _i++;
    while (_digit(_i)) {
      _i++;
    }
    if (_i < _s.length && _s[_i] == '.') {
      _i++;
      while (_digit(_i)) {
        _i++;
      }
    }
    if (_i < _s.length && (_s[_i] == 'e' || _s[_i] == 'E')) {
      _i++;
      if (_i < _s.length && (_s[_i] == '-' || _s[_i] == '+')) _i++;
      while (_digit(_i)) {
        _i++;
      }
    }
    return double.parse(_s.substring(from, _i));
  }

  /// An arc flag: one digit, which may touch what follows.
  bool flag() {
    _skip();
    return _s[_i++] == '1';
  }
}
