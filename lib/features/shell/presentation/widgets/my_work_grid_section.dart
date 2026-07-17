import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/animations/animated_card.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/animations/fade_slide_transition.dart';
import 'package:isi_steel_sales_mobile/core/animations/shimmer_loading.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';

class MyWorkGridSection extends StatelessWidget {
  const MyWorkGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    // The section spotlight targets this whole block cleanly.
    return CoachKeys.wrap(
      CoachKeys.myWork,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SectionHeader('MY WORK', letterSpacing: 1.6),

            // Row 1
            Row(
              children: [
                Expanded(
                  child: FadeSlideIn(
                    delay: FadeSlideIn.staggerDelay(0),
                    child: CoachKeys.wrap(
                      CoachKeys.myLeads,
                      child: _MyWorkCard(
                        label: 'My Leads',
                        icon: Icons.layers_outlined,
                        accent: const Color(0xFF4C9AFF),
                        badgeText: '1 due',
                        isActive: false,
                        onTap: () =>
                            sl<ShellTabController>().goTo(ShellTab.leads),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FadeSlideIn(
                    delay: FadeSlideIn.staggerDelay(1),
                    child: CoachKeys.wrap(
                      CoachKeys.myVisits,
                      child: _MyWorkCard(
                        label: 'My Visits',
                        icon: Icons.assignment_turned_in_outlined,
                        accent: const Color(0xFF36B37E),
                        badgeText: '3 today',
                        isActive: true,
                        onTap: () =>
                            sl<ShellTabController>().goTo(ShellTab.myVisits),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Row 2
            Row(
              children: [
                Expanded(
                  child: FadeSlideIn(
                    delay: FadeSlideIn.staggerDelay(2),
                    child: CoachKeys.wrap(
                      CoachKeys.myCustomers,
                      child: _MyWorkCard(
                        label: 'My Customers',
                        icon: Icons.people_alt_outlined,
                        accent: const Color(0xFFFF5C00),
                        isActive: false,
                        onTap: () =>
                            sl<ShellTabController>().goTo(ShellTab.customers),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FadeSlideIn(
                    delay: FadeSlideIn.staggerDelay(3),
                    child: CoachKeys.wrap(
                      CoachKeys.orders,
                      child: _MyWorkCard(
                        label: 'My Quotes & Orders',
                        icon: Icons.description_outlined,
                        accent: const Color(0xFFFFAB00),
                        isActive: false,
                        onTap: () =>
                            sl<ShellTabController>().goTo(ShellTab.orders),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyWorkCard extends StatelessWidget {
  const _MyWorkCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.badgeText,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedCard(
      onTap: onTap,
      semanticLabel: badgeText == null ? label : '$label, $badgeText',
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      splashColor: accent.withValues(alpha: 0.12),
      highlightColor: accent.withValues(alpha: 0.05),
      restShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
          blurRadius: isActive ? 16 : 10,
          offset: Offset(0, isActive ? 6 : 4),
        ),
      ],
      builder: (context, pressed, hovered) {
        return SizedBox(
          height: 116.h,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subtle, professional icon feedback: a small bounce +
                    // a slight rotate on press. No playful overshoot.
                    AnimatedScale(
                      scale: pressed ? 0.94 : 1.0,
                      duration: AppDurations.pressUp,
                      curve: AppCurves.bounce,
                      child: AnimatedRotation(
                        turns: pressed ? -0.015 : 0.0,
                        duration: AppDurations.pressUp,
                        curve: AppCurves.standard,
                        child: Container(
                          width: 46.r,
                          height: 46.r,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(icon, color: accent, size: 22.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Badge now lives safely inside the card's top-right corner
              // (the old version offset it -32.w and clipped on small phones),
              // and animates when its value changes.
              if (badgeText != null)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: _WorkBadge(text: badgeText!),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkBadge extends StatelessWidget {
  const _WorkBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: AppDurations.medium,
      switchInCurve: AppCurves.emphasized,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey<String>(text),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: scheme.secondary,
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: scheme.onSecondary,
            fontSize: 9.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.letterSpacing = 1.6});

  final String text;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: letterSpacing,
          color: color,
        ),
      ),
    );
  }
}

/// Drop-in skeleton that mirrors the grid's footprint 1:1 so there is no
/// layout jump when [HomeCubit] finishes loading. Wire it up with a selector,
/// e.g.:
///
/// ```dart
/// BlocBuilder<HomeCubit, HomeState>(
///   builder: (context, state) => state.isLoading
///       ? const MyWorkGridSkeleton()
///       : const MyWorkGridSection(),
/// )
/// ```
class MyWorkGridSkeleton extends StatelessWidget {
  const MyWorkGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionHeader('MY WORK', letterSpacing: 1.6),
          Row(children: [_skeletonCell(context), SizedBox(width: 12.w), _skeletonCell(context)]),
          SizedBox(height: 12.h),
          Row(children: [_skeletonCell(context), SizedBox(width: 12.w), _skeletonCell(context)]),
        ],
      ),
    );
  }

  Widget _skeletonCell(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 116.h,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20.r),
        ),
        alignment: Alignment.center,
        child: Shimmer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerBox(
                width: 46.r,
                height: 46.r,
                borderRadius: BorderRadius.circular(14.r),
              ),
              SizedBox(height: 12.h),
              ShimmerBox(width: 72.w, height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}