import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/l10n/visit_labels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

class StopCard extends StatelessWidget {
  const StopCard({
    super.key,
    required this.stop,
    required this.selected,
    required this.onTap,
    this.onCartTap,
  });

  final RouteStop stop;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onCartTap;

  Color _statusBgColor(ColorScheme scheme, AppThemeColors colors) =>
      switch (stop.status) {
        VisitStatus.pending => colors.textSecondary.withValues(alpha: 0.1),
        VisitStatus.enRoute ||
        VisitStatus.arrived =>
          scheme.primary.withValues(alpha: 0.12),
        VisitStatus.checkedIn => colors.warning.withValues(alpha: 0.12),
        VisitStatus.checkedOut => colors.success.withValues(alpha: 0.12),
        VisitStatus.missed => scheme.error.withValues(alpha: 0.1),
      };

  Color _statusTextColor(ColorScheme scheme, AppThemeColors colors) =>
      switch (stop.status) {
        VisitStatus.pending => colors.textSecondary,
        VisitStatus.enRoute || VisitStatus.arrived => scheme.primary,
        VisitStatus.checkedIn => colors.warning,
        VisitStatus.checkedOut => colors.success,
        VisitStatus.missed => scheme.error,
      };

  /// Helper converts integer index into stylized string suffixes (e.g. 1st, 2nd, 3rd)
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final bool isDone = stop.status == VisitStatus.checkedOut;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(
                16.r), // Ultra smooth outer container corners
            border: Border.all(color: colors.border, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Light Blue Squircle Sequence Tag from image_0fcd7c.png
              Container(
                width: 42.w,
                height: 42.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : colors.surfaceStrong,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  localizedOrdinal(stop.sequence),
                  style: TextStyle(
                    color: selected ? scheme.onPrimary : scheme.primary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // 2. Structured Meta Labels Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '${stop.customer.address} · 16.0 km', // Pattern layout matching sample string exactly
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Shopping Cart Shortcut Capsule
              if (isDone && onCartTap != null) ...[
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCartTap!();
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: colors.success,
                          size: 14.w,
                        ),
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.success,
                          size: 10.w,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
              ],

              // 4. Clean Pill Status Badge from image_0fcd7c.png
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: _statusBgColor(scheme, colors),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  stop.status.localizedLabel,
                  style: TextStyle(
                    color: _statusTextColor(scheme, colors),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
