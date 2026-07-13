import 'package:flutter/material.dart';

/// A small pulsing tap-pointer that draws the eye to the spotlighted target.
///
/// Respects reduced-motion: when [animate] is false it renders a static dot, so
/// it stays accessible and costs nothing on low-end devices.
class PointerAnimation extends StatefulWidget {
  const PointerAnimation({super.key, required this.color, this.animate = true});

  final Color color;
  final bool animate;

  @override
  State<PointerAnimation> createState() => _PointerAnimationState();
}

class _PointerAnimationState extends State<PointerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 22.0;
    if (!widget.animate) {
      return _Dot(color: widget.color, size: size);
    }
    return SizedBox(
      width: size * 2,
      height: size * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.5,
                child: Transform.scale(
                  scale: 0.6 + t * 1.4,
                  child: _Dot(color: widget.color, size: size),
                ),
              ),
              child!,
            ],
          );
        },
        child: _Dot(color: widget.color, size: size * 0.7),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
