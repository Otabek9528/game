import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'business_models.dart';
import 'business_source.dart';

/// How a logo meets its frame, read from its edge (as the web page does).
enum LogoKind {
  /// Transparent round its edge: it sits on the frame's own colour.
  plain,

  /// One solid colour to its edge: the frame takes that colour, so the
  /// logo's rectangle has nothing to meet.
  plate,

  /// Busy to its edges, a photograph: it fills the frame.
  photo,
}

class LogoFacts {
  const LogoFacts(this.kind, this.tint, [this.plate]);

  final LogoKind kind;

  /// The colour washed behind the business's card.
  final Color tint;

  /// A plate logo's own background.
  final Color? plate;
}

class LogoData {
  const LogoData(this.bytes, this.facts);

  final Uint8List bytes;
  final LogoFacts? facts;
}

/// Logos fetched once each and read once each, for the rows and the card.
class LogoCache {
  LogoCache(this._source);

  final BusinessSource _source;
  final _loads = <Uri, Future<LogoData?>>{};

  Future<LogoData?> load(Uri url) => _loads.putIfAbsent(url, () async {
        final bytes = await _source.logo(url);
        if (bytes == null) return null;
        try {
          return LogoData(bytes, await readLogo(bytes));
        } catch (_) {
          // Not an image: the monogram stands in.
          return null;
        }
      });
}

const _alphaClear = 32;
const _edgeUniform = 20.0;

/// The logo shrunk to 32×32 and read: how clear and how even its edge is,
/// and its average colour.
Future<LogoFacts?> readLogo(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 32, targetHeight: 32);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  frame.image.dispose();
  return data == null ? null : readPixels(data.buffer.asUint8List(), 32);
}

LogoFacts? readPixels(Uint8List data, int n) {
  final edge = <List<int>>[];
  var clear = 0, edgeCount = 0, opaque = 0;
  var sumR = 0, sumG = 0, sumB = 0;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final i = (y * n + x) * 4;
      final a = data[i + 3];
      if (x < 2 || y < 2 || x >= n - 2 || y >= n - 2) {
        edgeCount++;
        if (a < _alphaClear) {
          clear++;
        } else {
          edge.add([data[i], data[i + 1], data[i + 2]]);
        }
      }
      if (a >= _alphaClear) {
        sumR += data[i];
        sumG += data[i + 1];
        sumB += data[i + 2];
        opaque++;
      }
    }
  }
  if (opaque == 0) return null;
  final average = [sumR / opaque, sumG / opaque, sumB / opaque];
  if (clear / edgeCount > 0.45) return LogoFacts(LogoKind.plain, _soften(average));
  final mean = [for (var c = 0; c < 3; c++) edge.fold<double>(0, (s, p) => s + p[c]) / edge.length];
  final spread = [
    for (var c = 0; c < 3; c++) math.sqrt(edge.fold<double>(0, (s, p) => s + math.pow(p[c] - mean[c], 2)) / edge.length),
  ];
  if (spread.reduce(math.max) < _edgeUniform) {
    final plate = Color.fromARGB(255, mean[0].round(), mean[1].round(), mean[2].round());
    return LogoFacts(LogoKind.plate, plate, plate);
  }
  return LogoFacts(LogoKind.photo, _soften(average));
}

/// The average colour, calmed: never more than 40% saturated, never too
/// dark or too pale to wash a page with.
Color _soften(List<double> rgb) {
  final hsl = HSLColor.fromColor(Color.fromARGB(255, rgb[0].round(), rgb[1].round(), rgb[2].round()));
  return hsl.withSaturation(math.min(hsl.saturation, 0.40)).withLightness(hsl.lightness.clamp(0.45, 0.74)).toColor();
}

/// A colour of a business's own, from its name, so it never changes
/// between loads.
double hueOf(String name) {
  var h = 0;
  for (final unit in name.codeUnits) {
    h = (h * 31 + unit) % 360;
  }
  return h.toDouble();
}

/// The wash for a business with no logo.
Color nameTint(String name) => HSLColor.fromAHSL(1, hueOf(name), 0.38, 0.58).toColor();

String initials(String name) =>
    name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w.characters.first.toUpperCase()).join();

/// A business's logo in a rounded frame [size] across, as its edge asks; its
/// initials in its own colour when it has none, or it won't load.
class BizLogo extends StatelessWidget {
  const BizLogo({super.key, required this.business, required this.logos, this.size = 52, this.radius});

  final Business business;
  final LogoCache logos;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final url = business.logoUrl;
    final r = BorderRadius.circular(radius ?? size * 0.28);
    final monogram = _Monogram(name: business.name, size: size, radius: r);
    if (url == null) return monogram;
    return FutureBuilder<LogoData?>(
      future: logos.load(url),
      builder: (context, snapshot) {
        final logo = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: VegukinPalette.of(context).cardSelected, borderRadius: r),
          );
        }
        if (logo == null) return monogram;
        return LogoFrame(logo: logo, size: size, radius: r, fallback: monogram);
      },
    );
  }
}

/// A loaded logo, framed by its kind.
class LogoFrame extends StatelessWidget {
  const LogoFrame({super.key, required this.logo, required this.size, required this.radius, required this.fallback});

  final LogoData logo;
  final double size;
  final BorderRadius radius;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final kind = logo.facts?.kind ?? LogoKind.photo;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = Image.memory(
      logo.bytes,
      fit: kind == LogoKind.photo ? BoxFit.cover : BoxFit.contain,
      cacheWidth: (size * dpr).round(),
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      padding: kind == LogoKind.plain ? EdgeInsets.all(size * 0.08) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: switch (kind) {
          LogoKind.plate => logo.facts!.plate,
          LogoKind.plain => Colors.white,
          LogoKind.photo => p.cardSelected,
        },
        borderRadius: radius,
        border: kind == LogoKind.plate ? null : Border.all(color: p.hairline),
      ),
      child: SizedBox.expand(child: image),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.name, required this.size, required this.radius});

  final String name;
  final double size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final h = hueOf(name);
    Color hsl(double s, double l) => HSLColor.fromAHSL(1, h, s, l).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? hsl(0.20, 0.20) : hsl(0.30, 0.92),
        borderRadius: radius,
        border: Border.all(color: dark ? hsl(0.18, 0.27) : hsl(0.26, 0.85)),
      ),
      child: Text(
        initials(name),
        style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800, color: dark ? hsl(0.48, 0.70) : hsl(0.42, 0.34)),
      ),
    );
  }
}
