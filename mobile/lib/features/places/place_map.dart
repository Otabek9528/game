import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../l10n/app_localizations.dart';

/// Where a place is, at a glance: OpenStreetMap's tiles around it with a pin
/// in the middle. Twelve-odd small images, no map library; the attribution
/// OpenStreetMap asks for in the corner.
class PlaceMap extends StatelessWidget {
  const PlaceMap({super.key, required this.lat, required this.lon, required this.colour, required this.emoji});

  final double lat;
  final double lon;
  final Color colour;
  final String emoji;

  /// Zoom 17 tiles drawn at 160 px: about a street's width each, and sharp.
  static const zoom = 17;
  static const tileSize = 160.0;

  /// The place in tile units (x, y) at [zoom].
  static ({double x, double y}) tileOf(double lat, double lon) {
    final n = math.pow(2, zoom).toDouble();
    final rad = lat * math.pi / 180;
    return (
      x: (lon + 180) / 360 * n,
      y: (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final at = tileOf(lat, lon);
      // The place a little below the middle: the top bar's buttons float over the top.
      final left = at.x * tileSize - w / 2, top = at.y * tileSize - h * 0.56;
      final tiles = <Widget>[
        for (var ty = (top / tileSize).floor(); ty * tileSize < top + h; ty++)
          for (var tx = (left / tileSize).floor(); tx * tileSize < left + w; tx++)
            Positioned(
              left: tx * tileSize - left,
              top: ty * tileSize - top,
              width: tileSize,
              height: tileSize,
              child: Image.network(
                'https://tile.openstreetmap.org/$zoom/$tx/$ty.png',
                headers: const {'User-Agent': AppConfig.userAgent},
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
      ];
      final map = Stack(clipBehavior: Clip.hardEdge, children: tiles);
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: dark ? const Color(0xFF2B2E2C) : const Color(0xFFEDE9E1)),
          if (dark)
            ColorFiltered(
              // Darker and greyer at night, so the page around it isn't outshone.
              colorFilter: const ColorFilter.matrix([
                0.36, 0.06, 0.03, 0, 6,
                0.03, 0.40, 0.03, 0, 6,
                0.03, 0.06, 0.36, 0, 6,
                0, 0, 0, 1, 0,
              ]),
              child: map,
            )
          else
            map,
          Positioned(
            left: w / 2 - 22,
            top: h * 0.56 - 50,
            child: _Pin(colour: colour, emoji: emoji),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Text(
                  AppLocalizations.of(context).plMapAttribution,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF444444)),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// A teardrop in the kind's colour with its emoji, its point on the place.
class _Pin extends StatelessWidget {
  const _Pin({required this.colour, required this.emoji});

  final Color colour;
  final String emoji;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 44,
        height: 52,
        child: CustomPaint(
          painter: _PinPainter(colour),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
        ),
      );
}

class _PinPainter extends CustomPainter {
  const _PinPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final path = Path()
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..moveTo(r - r * 0.55, r + r * 0.75)
      ..lineTo(r, size.height)
      ..lineTo(r + r * 0.55, r + r * 0.75)
      ..close();
    canvas
      ..drawShadow(path, Colors.black, 4, false)
      ..drawPath(path, Paint()..color = Colors.white)
      ..drawCircle(c, r - 3, Paint()..color = colour.withValues(alpha: 0.18))
      ..drawCircle(c, r - 3, Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.colour != colour;
}
