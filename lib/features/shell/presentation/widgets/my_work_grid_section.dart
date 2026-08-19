import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/shared/animations/work_icons.dart';
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

  /// Height of the whole block: two stacked cards plus the gap between them.
  ///
  /// Derived rather than hardcoded so the single-card height stays the one
  /// number to change, and the right-hand card can never drift out of step
  /// with the pair it sits beside.
  static double _cardHeight(BuildContext context) => context.rh(120);
  static double _leftColumnHeight(BuildContext context) =>
      _cardHeight(context) * 2 + context.rh(12);

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

            // Two columns: the two secondary destinations stack on the left,
            // and My Visits takes the full height on the right.
            //
            // The asymmetry is the point. My Visits is where a rep spends the
            // day and the only card carrying a live count, so it gets the
            // larger, taller surface; Customers and Orders are places you go
            // between visits. A three-equal-card grid would give the day's
            // main task the same weight as its supporting ones.
            SizedBox(
              height: _leftColumnHeight(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left: Customers over Quotes & Orders ────────────────
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: FadeSlideIn(
                            delay: FadeSlideIn.staggerDelay(1),
                            child: CoachKeys.wrap(
                              CoachKeys.myCustomers,
                              child: _MyWorkCard(
                                label: 'shell.my_customers'.tr,
                                icon: Icons.people_alt_outlined,
                                kind: WorkIconKind.customers,
                                accent: const Color(0xFFEC3F72),
                                isActive: false,
                                onTap: () => sl<ShellTabController>()
                                    .goTo(ShellTab.customers),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: context.rh(12)),
                        Expanded(
                          child: FadeSlideIn(
                            delay: FadeSlideIn.staggerDelay(2),
                            child: CoachKeys.wrap(
                              CoachKeys.orders,
                              child: _MyWorkCard(
                                label: 'shell.my_quotes_orders'.tr,
                                icon: Icons.description_outlined,
                                kind: WorkIconKind.quotesOrders,
                                accent: const Color(0xFFF5A623),
                                isActive: false,
                                onTap: () => sl<ShellTabController>()
                                    .goTo(ShellTab.orders),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: context.rw(12)),

                  // ── Right: My Visits, full height ───────────────────────
                  Expanded(
                    child: FadeSlideIn(
                      delay: FadeSlideIn.staggerDelay(3),
                      child: CoachKeys.wrap(
                        CoachKeys.myVisits,
                        child: _MyWorkCard(
                          label: 'shell.my_visits'.tr,
                          icon: Icons.assignment_turned_in_outlined,
                          kind: WorkIconKind.visits,
                          // Sampled from the artwork so the tile's drop-glow
                          // matches the illustration it sits under. An accent
                          // that disagrees with the art reads as a halo bug.
                          accent: const Color(0xFF22C3D6),
                          tileHeight: context.rr(96),
                          badgeText: 'shell.badge_today'.trParams({'count': 3}),
                          isActive: true,
                          onTap: () =>
                              sl<ShellTabController>().goTo(ShellTab.myVisits),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
    required this.kind,
    this.tileHeight,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isActive;

  /// Which drawn, animated illustration this card shows.
  final WorkIconKind kind;

  /// Tile height override. The full-height card gets a larger tile so its
  /// extra room is filled by the artwork rather than left as dead space above
  /// and below a tile sized for a card half as tall.
  final double? tileHeight;

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
          // No fixed height: the card now fills whatever its column gives it,
          // which is what lets the right-hand card stand two rows tall while
          // the left pair stay one each.
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
                              // 2. Vivid icon tile
                              WorkIcon(
                                kind: widget.kind,
                                accent: widget.accent,
                                size: widget.tileHeight ?? context.rr(66),
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
