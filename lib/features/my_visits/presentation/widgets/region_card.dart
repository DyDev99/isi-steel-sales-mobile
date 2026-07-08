import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

class RegionCard extends StatelessWidget {
  const RegionCard({
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
        VisitStatus.pending => Vibe.muted.withOpacity(0.1),
        VisitStatus.enRoute || VisitStatus.arrived => Vibe.violet.withOpacity(0.12),
        VisitStatus.checkedIn => Vibe.amber.withOpacity(0.12),
        VisitStatus.checkedOut => const Color(0xFFE6F7ED), // Match image_0fcd7c.png crisp green background
        VisitStatus.missed => Vibe.danger.withOpacity(0.1),
      };

  Color get _statusTextColor => switch (stop.status) {
        VisitStatus.pending => Vibe.muted,
        VisitStatus.enRoute || VisitStatus.arrived => Vibe.violet,
        VisitStatus.checkedIn => Vibe.amber,
        VisitStatus.checkedOut => const Color(0xFF2EA893), // Match image_0fcd7c.png Done text color
        VisitStatus.missed => Vibe.danger,
      };

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
            borderRadius: BorderRadius.circular(16.r), 
            border: Border.all(color: const Color(0xFFEAECEF), width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ordinal sequence container matching image_0fcd7c.png squircle shape
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
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF1E293B), 
                        fontSize: 13.5.sp, 
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '${stop.customer.address} · 16.0 km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF64748B), 
                        fontSize: 11.sp,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),

              // Action shortcut capsule right before the status pill
              if (isDone && onCartTap != null) ...[
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCartTap!();
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EA893).withOpacity(0.12),
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
                    fontFamily: 'Roboto',
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

/// Collapsible section header grouping stops by [regionName] (the
/// customer's territory) so the dashboard reflects region-level structure
/// instead of a flat list of individual stops.
class RegionGroupHeader extends StatelessWidget {
  const RegionGroupHeader({
    super.key,
    required this.regionName,
    required this.totalStops,
    required this.completedStops,
    required this.expanded,
    required this.onTap,
  });

  final String regionName;
  final int totalStops;
  final int completedStops;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF2FF),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: const Color(0xFF2F6FED), size: 18.w),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                regionName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1E293B),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            Text(
              '$completedStops/$totalStops',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF2F6FED),
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }
}