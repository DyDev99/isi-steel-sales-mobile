import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/animations/fade_slide_transition.dart';
import 'package:isi_steel_sales_mobile/core/animations/shimmer_loading.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';

class MyWorkGridSection extends StatelessWidget {
  const MyWorkGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachKeys.wrap(
      CoachKeys.myWork,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.pagePadding,
          vertical: context.rh(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SectionHeader('shell.my_work'.tr, letterSpacing: 1.6),

            // Row 1: Remove Expanded from top level Column
            FadeSlideIn(
              delay: FadeSlideIn.staggerDelay(1),
              child: CoachKeys.wrap(
                CoachKeys.myVisits,
                child: _MyWorkCard(
                  label: 'shell.my_visits'.tr,
                  icon: Icons.assignment_turned_in_outlined,
                  accent: const Color(0xFF10B981),
                  badgeText: 'shell.badge_today'.trParams({'count': 3}),
                  isActive: true,
                  onTap: () => sl<ShellTabController>().goTo(ShellTab.myVisits),
                ),
              ),
            ),

            SizedBox(height: context.rh(12)),

            // Row 2: Expanded is valid inside Row (horizontal sizing)
            Row(
              children: [
                Expanded(
                  child: FadeSlideIn(
                    delay: FadeSlideIn.staggerDelay(2),
                    child: CoachKeys.wrap(
                      CoachKeys.myCustomers,
                      child: _MyWorkCard(
                        label: 'shell.my_customers'.tr,
                        icon: Icons.people_alt_outlined,
                        accent: const Color(0xFFF97316),
                        isActive: false,
                        onTap: () =>
                            sl<ShellTabController>().goTo(ShellTab.customers),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.rw(12)),
                Expanded(
                  child: FadeSlideIn(
                    delay: FadeSlideIn.staggerDelay(3),
                    child: CoachKeys.wrap(
                      CoachKeys.orders,
                      child: _MyWorkCard(
                        label: 'shell.my_quotes_orders'.tr,
                        icon: Icons.description_outlined,
                        accent: const Color(0xFFF59E0B),
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

class _MyWorkCard extends StatefulWidget {
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
  State<_MyWorkCard> createState() => _MyWorkCardState();
}

class _MyWorkCardState extends State<_MyWorkCard> {
  bool _isPressed = false;

  // Traditional Gold Accent Palette
  static const Color _goldLight = Color(0xFFF3E5AB);
  static const Color _goldPrimary = Color(0xFFD4AF37);
  static const Color _goldDark = Color(0xFF996515);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final depthOffset = _isPressed ? 2.0 : 6.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isPressed ? 4.0 : 0.0, 0),
        child: Container(
          height: context.rh(120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            // 3D Extrusion Shadow + Traditional Ambient Glow
            boxShadow: [
              // Bottom Extrusion Shadow for 3D effect
              BoxShadow(
                color: widget.accent.withValues(alpha: isDark ? 0.35 : 0.25),
                offset: Offset(0, depthOffset),
                blurRadius: _isPressed ? 2 : 6,
              ),
              // Soft Base Depth Shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                offset: Offset(0, depthOffset + 2),
                blurRadius: _isPressed ? 4 : 12,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Traditional Outer Gold Frame & Card Base
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _goldLight.withValues(alpha: 0.8),
                      _goldPrimary,
                      _goldDark,
                    ],
                  ),
                ),
                padding: EdgeInsets.all(2.r), // Gold Rim Width
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    color: scheme.surface,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface,
                        Color.lerp(
                          scheme.surface,
                          widget.accent,
                          0.05,
                        )!,
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: Stack(
                      children: [
                        // Traditional Subtle Corner Ornament Accents
                        Positioned(
                          top: -12.r,
                          left: -12.r,
                          child:
                              _TraditionalCornerOrnament(color: widget.accent),
                        ),
                        Positioned(
                          bottom: -12.r,
                          right: -12.r,
                          child: Transform.rotate(
                            angle: 3.14159,
                            child: _TraditionalCornerOrnament(
                                color: widget.accent),
                          ),
                        ),

                        // Card Content
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 2. 3D Embossed Icon Medallion
                              Container(
                                width: context.rr(48),
                                height: context.rr(48),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.accent.withValues(alpha: 0.25),
                                      widget.accent.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: _goldPrimary.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          widget.accent.withValues(alpha: 0.2),
                                      offset: const Offset(0, 3),
                                      blurRadius: 6,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                          alpha: isDark ? 0.05 : 0.6),
                                      offset: const Offset(-2, -2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    widget.icon,
                                    color: widget.accent,
                                    size: context.rr(22),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.rh(10)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  widget.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.rsp(13.5),
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Badge with 3D Elevation
              if (widget.badgeText != null)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: _WorkBadge(text: widget.badgeText!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Traditional geometric motif corner decoration
class _TraditionalCornerOrnament extends StatelessWidget {
  const _TraditionalCornerOrnament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}

class _WorkBadge extends StatelessWidget {
  const _WorkBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
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
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
          ),
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: context.rsp(9),
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
    final color = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.8);

    // A section header has to outrank the card labels beneath it. On a phone
    // 14pt against 13.5pt labels is enough separation, but once the type scale
    // opens up on a tablet the labels reach ~23pt and an equal-sized header
    // stops reading as a heading at all. Widening the base on larger windows —
    // rather than raising it everywhere — keeps the phone baseline frozen.
    final double headerBase = context.responsive(compact: 14.0, medium: 16.0);

    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: context.rh(12)),
      child: Row(
        children: [
          Container(
            width: context.rw(4),
            height: context.rh(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.r),
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFF996515)],
              ),
            ),
          ),
          SizedBox(width: context.rw(8)),
          Text(
            text,
            style: TextStyle(
              fontSize: context.rsp(headerBase),
              fontWeight: FontWeight.w900,
              letterSpacing: letterSpacing,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MyWorkGridSkeleton extends StatelessWidget {
  const MyWorkGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePadding,
        vertical: context.rh(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader('shell.my_work'.tr, letterSpacing: 1.6),
          Row(children: [
            _skeletonCell(context),
            SizedBox(width: context.rw(12)),
            _skeletonCell(context)
          ]),
          SizedBox(height: context.rh(12)),
          Row(children: [
            _skeletonCell(context),
            SizedBox(width: context.rw(12)),
            _skeletonCell(context)
          ]),
        ],
      ),
    );
  }

  Widget _skeletonCell(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: context.rh(120),
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
                width: 48.r,
                height: 48.r,
                borderRadius: BorderRadius.circular(24.r),
              ),
              SizedBox(height: context.rh(12)),
              ShimmerBox(width: 72.w, height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}
