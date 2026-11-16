import 'package:flutter/material.dart';

import '../tokens.dart';

/// For tight chrome (a bar's title, a bottom bar, a chip, a calendar cell):
/// text inside grows with the phone's font setting only up to
/// [TextGrowth.tight]. Past that these places lose their words.
class TightText extends StatelessWidget {
  const TightText({super.key, required this.child, this.max = TextGrowth.tight});

  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(maxScaleFactor: max, child: child);
}

/// One line that gets smaller instead of being cut when it is a little too
/// long for its place: a page's title, a button's label, a phone number.
/// Never smaller than [floor] of the size it was designed at (so with the
/// phone's font set larger it may give back more of that growth); past that
/// it is cut as before.
class FitLine extends StatelessWidget {
  const FitLine(this.text, {super.key, this.style, this.alignment = AlignmentDirectional.centerStart, this.floor = 0.72});

  final String text;
  final TextStyle? style;
  final AlignmentGeometry alignment;
  final double floor;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(this.style);
    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final wide = painter.width;
        painter.dispose();
        final room = box.maxWidth;
        final size = style.fontSize;
        final grown = size == null ? 1.0 : scaler.scale(size) / size;
        final least = (floor / grown).clamp(0.0, 1.0);
        final shrink = !room.isFinite || wide <= room ? 1.0 : (room / wide).clamp(least, 1.0);
        return Align(
          alignment: alignment,
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            // A hair under the measured fit: rounding must not cut the last letter.
            style: shrink == 1 || size == null ? style : style.copyWith(fontSize: (size * shrink * 0.985)),
          ),
        );
      },
    );
  }
}
