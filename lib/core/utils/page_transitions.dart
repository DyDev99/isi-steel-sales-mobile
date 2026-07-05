import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';

/// Slide-left on forward navigation, slide-right on back — used across the
/// Routes field flow (Dispatch → Transit → Check-in → Stock) to anchor the
/// agent's spatial mental map of where they are in the route wizard.
///
/// The page is wrapped in [LocalizedBuilder] so every screen pushed this way
/// re-evaluates its `.tr` text live on a language switch, even though it sits
/// in its own Navigator overlay entry.
Route<T> slideLeftRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => LocalizedBuilder(builder: (_) => page),
    transitionsBuilder: (_, animation, __, child) {
      final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(slide), child: child);
    },
  );
}
