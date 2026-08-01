import 'package:flutter/material.dart';

/// The one motion spec every stage of the guided configurator uses.
///
/// Centralised so category → family → specification → products all feel like
/// the same object moving, rather than four screens that each animate slightly
/// differently. Material's standard "shared axis" reading: the outgoing stage
/// fades and slides out, the incoming one fades and slides in from the leading
/// edge, with the container resizing rather than jumping.
class FilterFlowTransition extends StatelessWidget {
  const FilterFlowTransition({
    super.key,
    required this.stageKey,
    required this.child,
    this.reverse = false,
  });

  /// Changing this is what triggers the transition. Use something that
  /// identifies the *stage*, not the data (e.g. the active step key), so a
  /// loading→loaded refresh doesn't replay the animation.
  final Object stageKey;

  /// True when moving backwards, so the slide direction inverts and the motion
  /// reads as retracing rather than progressing.
  final bool reverse;

  final Widget child;

  static const duration = Duration(milliseconds: 260);
  static const curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: curve,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: Offset(reverse ? -0.06 : 0.06, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(stageKey), child: child),
      ),
    );
  }
}

/// Staggered entrance for the options inside a stage — each chip/tile arrives
/// a beat after the one before it, which reads as the list assembling instead
/// of appearing. Capped so a long option list never delays the last item by
/// more than a moment.
class FilterFlowStaggeredItem extends StatelessWidget {
  const FilterFlowStaggeredItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  static const _step = Duration(milliseconds: 22);
  static const _maxDelay = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final delay = Duration(
      milliseconds: (index * _step.inMilliseconds)
          .clamp(0, _maxDelay.inMilliseconds)
          .toInt(),
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey('stagger-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: FilterFlowTransition.duration + delay,
      curve: Interval(
        delay.inMilliseconds /
            (FilterFlowTransition.duration + delay).inMilliseconds,
        1,
        curve: FilterFlowTransition.curve,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
