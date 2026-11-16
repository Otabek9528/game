import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
/// it is cut with "…" as before.
///
/// Works anywhere a [Text] does, inside rows that measure their children
/// first included.
class FitLine extends StatelessWidget {
  const FitLine(this.text, {super.key, this.style, this.alignment = AlignmentDirectional.centerStart, this.floor = 0.72});

  final String text;
  final TextStyle? style;
  final AlignmentGeometry alignment;
  final double floor;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(this.style);
    final size = style.fontSize ?? 14;
    final grown = MediaQuery.textScalerOf(context).scale(size) / size;
    return _Fit(
      least: (floor / grown).clamp(0.05, 1.0),
      alignment: alignment.resolve(Directionality.of(context)),
      child: Text(text, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}

class _Fit extends SingleChildRenderObjectWidget {
  const _Fit({required this.least, required this.alignment, super.child});

  final double least;
  final Alignment alignment;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFit(least, alignment);

  @override
  void updateRenderObject(BuildContext context, _RenderFit renderObject) => renderObject
    ..least = least
    ..alignment = alignment;
}

/// Lays its child out up to 1/[least] of the width there is, then scales it
/// down to fit: a line up to that much too long is whole, a longer one is cut.
class _RenderFit extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  _RenderFit(this._least, this._alignment);

  double _least;
  set least(double value) {
    if (_least == value) return;
    _least = value;
    markNeedsLayout();
  }

  Alignment _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  double _scale = 1;
  Offset _at = Offset.zero;

  // Asked how wide it would like to be: as wide as its words.
  @override
  double computeMinIntrinsicWidth(double height) => child?.getMaxIntrinsicWidth(double.infinity) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) => child?.getMaxIntrinsicWidth(double.infinity) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) => child?.getMaxIntrinsicHeight(double.infinity) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) => child?.getMaxIntrinsicHeight(double.infinity) ?? 0;

  BoxConstraints _forChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: constraints.maxWidth.isFinite ? constraints.maxWidth / _least : double.infinity);

  double _scaleFor(BoxConstraints constraints, Size childSize) =>
      constraints.maxWidth.isFinite && childSize.width > constraints.maxWidth ? constraints.maxWidth / childSize.width : 1;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final childSize = child.getDryLayout(_forChild(constraints));
    return constraints.constrain(childSize * _scaleFor(constraints, childSize));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_forChild(constraints), parentUsesSize: true);
    _scale = _scaleFor(constraints, child.size);
    final fitted = child.size * _scale;
    size = constraints.constrain(fitted);
    _at = _alignment.alongOffset(size - fitted as Offset);
  }

  Matrix4 get _transform => Matrix4.translationValues(_at.dx, _at.dy, 0)..multiply(Matrix4.diagonal3Values(_scale, _scale, 1));

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      layer = null;
      context.paintChild(child, offset + _at);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer! as TransformLayer : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_transform);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }
}
