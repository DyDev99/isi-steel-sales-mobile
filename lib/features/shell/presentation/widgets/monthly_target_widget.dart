import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class MonthlyTargetCard extends StatefulWidget {
  const MonthlyTargetCard({
    super.key,
    required this.targetAmount,
    required this.achievedAmount,
    required this.monthName,
    this.onTap,
  });

  final double targetAmount;
  final String monthName;
  final double achievedAmount;
  final VoidCallback? onTap;

  @override
  State<MonthlyTargetCard> createState() => _MonthlyTargetCardState();
}

class _MonthlyTargetCardState extends State<MonthlyTargetCard> {
  bool _isPressed = false;

  // Traditional Gold Palette
  static const Color _goldLight = Color(0xFFF3E5AB);
  static const Color _goldPrimary = Color(0xFFD4AF37);
  static const Color _goldDark = Color(0xFF996515);

  double get _progress => widget.targetAmount > 0
      ? (widget.achievedAmount / widget.targetAmount).clamp(0.0, 1.0)
      : 0.0;

  int get _percentage => (_progress * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    final depthOffset = _isPressed ? 2.0 : 6.0;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isPressed ? 4.0 : 0.0, 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            // 3D Depth Shadows
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: isDark ? 0.30 : 0.18),
                offset: Offset(0, depthOffset),
                blurRadius: _isPressed ? 2 : 6,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                offset: Offset(0, depthOffset + 2),
                blurRadius: _isPressed ? 4 : 12,
              ),
            ],
          ),
          child: Container(
            // 1. Outer Gold Frame Gradient
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _goldLight.withValues(alpha: 0.85),
                  _goldPrimary,
                  _goldDark,
                ],
              ),
            ),
            padding: EdgeInsets.all(2.r), // Gold Border Trim Thickness
            child: Container(
              padding: EdgeInsets.all(context.rw(18)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                color: scheme.surface,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface,
                    Color.lerp(scheme.surface, scheme.primary, 0.04)!,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Stack(
                  children: [
                    // Traditional Corner Decorative Accents
                    Positioned(
                      top: -16.r,
                      left: -16.r,
                      child: _TraditionalCornerOrnament(color: scheme.primary),
                    ),
                    Positioned(
                      bottom: -16.r,
                      right: -16.r,
                      child: Transform.rotate(
                        angle: 3.14159,
                        child:
                            _TraditionalCornerOrnament(color: scheme.primary),
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Header: 3D Calendar Medallion + Title & 3D Percentage Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // 3D Embossed Icon Medallion
                                Container(
                                  width: 36.r,
                                  height: 36.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        scheme.primary.withValues(alpha: 0.22),
                                        scheme.primary.withValues(alpha: 0.06),
                                      ],
                                    ),
                                    border: Border.all(
                                      color:
                                          _goldPrimary.withValues(alpha: 0.7),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary
                                            .withValues(alpha: 0.2),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                            alpha: isDark ? 0.05 : 0.6),
                                        offset: const Offset(-1, -1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16.sp,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  'shell.monthly_target'
                                      .trParams({'month': widget.monthName}),
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontSize: context.rsp(14),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),

                            // 3D Percentage Chip with Gold/Success Gradient
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    appColors.success,
                                    Color.lerp(
                                      appColors.success,
                                      _goldDark,
                                      0.25,
                                    )!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: appColors.success
                                        .withValues(alpha: 0.35),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                '$_percentage%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.rsp(12),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: context.rh(16)),

                        // 2. Large Value Display with 3D Depth Style
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${widget.achievedAmount.toInt()}',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: context.rsp(24),
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.5 : 0.12),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '/ \$${widget.targetAmount.toInt()}',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                                fontSize: context.rsp(14),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: context.rh(14)),

                        // 3. Carved 3D Progress Track
                        Container(
                          height: context.rh(12),
                          decoration: BoxDecoration(
                            color: appColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: _goldPrimary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.4 : 0.08),
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _progress,
                                child: Container(
                                  height: context.rh(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        appColors.success
                                            .withValues(alpha: 0.85),
                                        appColors.success,
                                        Color.lerp(
                                          appColors.success,
                                          _goldDark,
                                          0.3,
                                        )!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: appColors.success
                                            .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
      width: 40.r,
      height: 40.r,
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
