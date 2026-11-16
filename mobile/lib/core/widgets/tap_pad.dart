import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../tokens.dart';

/// Gives a small control (a chip, a round icon button, a link in a row) the
/// touch area a finger needs without making it look bigger: the control is
/// centred in at least [min], and a touch on the empty part around it lands on
/// the control. What Material's own buttons do; for the app's hand-made ones.
/// A screen reader sees one target, as large as the area.
class TapPad extends StatelessWidget {
  const TapPad({super.key, required this.child, this.min = const Size(tapTarget, tapTarget)});

  final Widget child;
  final Size min;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: _Pad(min: min, child: child),
      );
}

class _Pad extends SingleChildRenderObjectWidget {
  const _Pad({required this.min, super.child});

  final Size min;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPad(min);

  @override
  void updateRenderObject(BuildContext context, _RenderPad renderObject) => renderObject.min = min;
}

class _RenderPad extends RenderShiftedBox {
  _RenderPad(this._min) : super(null);

  Size _min;
  set min(Size value) {
    if (_min == value) return;
    _min = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      child == null ? 0 : math.max(child!.getMinIntrinsicWidth(height), _min.width);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child == null ? 0 : math.max(child!.getMaxIntrinsicWidth(height), _min.width);

  @override
  double computeMinIntrinsicHeight(double width) =>
      child == null ? 0 : math.max(child!.getMinIntrinsicHeight(width), _min.height);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child == null ? 0 : math.max(child!.getMaxIntrinsicHeight(width), _min.height);

  Size _sizeFor(BoxConstraints constraints, Size childSize) =>
      constraints.constrain(Size(math.max(childSize.width, _min.width), math.max(childSize.height, _min.height)));

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child == null ? Size.zero : _sizeFor(constraints, child!.getDryLayout(constraints.loosen()));

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(size - child.size as Offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    // Around the control, inside the area: as if its middle had been touched.
    if (child == null || !size.contains(position)) return false;
    final center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child.hitTest(result, position: center),
    );
  }
}
