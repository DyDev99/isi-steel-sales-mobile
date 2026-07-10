import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
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

  Color get _statusBgColor => switch (stop.status) {
        VisitStatus.pending => Vibe.muted.withValues(alpha: 0.1),
        VisitStatus.enRoute ||
        VisitStatus.arrived =>
          Vibe.violet.withValues(alpha: 0.12),
        VisitStatus.checkedIn => Vibe.amber.withValues(alpha: 0.12),
        VisitStatus.checkedOut => const Color(
            0xFFE6F7ED), // Exact crisp green background from image_0fcd7c.png
        VisitStatus.missed => Vibe.danger.withValues(alpha: 0.1),
      };

  Color get _statusTextColor => switch (stop.status) {
        VisitStatus.pending => Vibe.muted,
        VisitStatus.enRoute || VisitStatus.arrived => Vibe.violet,
        VisitStatus.checkedIn => Vibe.amber,
        VisitStatus.checkedOut =>
          const Color(0xFF2EA893), // Done text tone matching image_0fcd7c.png
        VisitStatus.missed => Vibe.danger,
      };

  /// Helper converts integer index into stylized string suffixes (e.g. 1st, 2nd, 3rd)
  String _getOrdinal(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }
    return switch (number % 10) {
      1 => '${number}st',
      2 => '${number}nd',
      3 => '${number}rd',
      _ => '${number}th',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = stop.status == VisitStatus.checkedOut;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
                16.r), // Ultra smooth outer container corners
            border: Border.all(color: const Color(0xFFEAECEF), width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
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
                  color: selected ? Vibe.violet : const Color(0xFFEDF2FF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getOrdinal(stop.sequence),
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF2F6FED),
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
                        color: const Color(
                            0xFF1E293B), // High-contrast sleek slate header
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
                        color: const Color(0xFF64748B),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. High-Vibe GenZ Shopping Cart Shortcut Capsule
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
                      color: const Color(0xFF2EA893).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: const Color(0xFF2EA893),
                          size: 14.w,
                        ),
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: const Color(0xFF2EA893),
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
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  stop.status.label,
                  style: TextStyle(
                    color: _statusTextColor,
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
