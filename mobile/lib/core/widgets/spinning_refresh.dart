import 'package:flutter/material.dart';

/// The refresh arrow next to the city; it turns while a location fix runs.
class SpinningRefresh extends StatefulWidget {
  const SpinningRefresh({super.key, required this.spinning, required this.color, this.size = 15});

  final bool spinning;
  final Color color;
  final double size;

  @override
  State<SpinningRefresh> createState() => _SpinningRefreshState();
}

class _SpinningRefreshState extends State<SpinningRefresh> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(SpinningRefresh old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: Icon(Icons.refresh_rounded, size: widget.size, color: widget.color),
    );
  }
}
