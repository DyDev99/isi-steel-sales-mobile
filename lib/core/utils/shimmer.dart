import 'package:flutter/material.dart';

/// Base + highlight greys for placeholder blocks. Tuned for the app's light
/// scaffold so skeletons read as "content loading", not as empty error blocks.
const Color kSkeletonBase = Color(0xFFE7E9EE);
const Color kSkeletonHighlight = Color(0xFFF5F6F8);

/// A dependency-free shimmer: sweeps a light gradient across whatever grey
/// [SkeletonBox]es it wraps, on a continuous loop. Wrap a whole skeleton card
/// once (not each box) so the sheen flows across the card as one motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value; // 0 → 1 sweep position
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [kSkeletonBase, kSkeletonHighlight, kSkeletonBase],
              stops: [
                (t - 0.3).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single masked grey rectangle. Give it the exact height/width/radius of the
/// real content line it stands in for, so switching from skeleton → data causes
/// no layout jump.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox(
      {super.key, this.width, required this.height, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kSkeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
