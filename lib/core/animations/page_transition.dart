import 'package:flutter/material.dart';

import 'app_animations.dart';

/// Reusable page routes with Material-motion-style transitions.
///
/// A drop-in replacement for `MaterialPageRoute` that keeps the same
/// `settings` plumbing (route names, arguments) the app already relies on:
///
/// ```dart
/// Navigator.of(context).push(
///   AppPageRoute.fadeThrough(
///     page: const DepotSelectionScreen(),
///     settings: const RouteSettings(name: DepotSelectionScreen.routeName),
///   ),
/// );
/// ```
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute._({
    required Widget page,
    required RouteTransitionsBuilder transition,
    super.settings,
    Duration duration = AppDurations.page,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: transition,
        );

  /// Cross-fade with a gentle scale — good for "replace content" navigation.
  factory AppPageRoute.fadeThrough({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppDurations.page,
  }) {
    return AppPageRoute<T>._(
      page: page,
      settings: settings,
      duration: duration,
      transition: (context, animation, secondary, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: AppCurves.emphasized);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Shared-axis vertical: the incoming screen slides up and fades while the
  /// outgoing one eases away. Good for drill-downs.
  factory AppPageRoute.sharedAxisVertical({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppDurations.page,
  }) {
    return AppPageRoute<T>._(
      page: page,
      settings: settings,
      duration: duration,
      transition: (context, animation, secondary, child) {
        final inCurve =
            CurvedAnimation(parent: animation, curve: AppCurves.emphasized);
        final outCurve =
            CurvedAnimation(parent: secondary, curve: AppCurves.emphasized);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(inCurve),
          child: FadeTransition(
            opacity: inCurve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0, -0.04),
              ).animate(outCurve),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
