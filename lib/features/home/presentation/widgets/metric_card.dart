import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

// metric_card.dart
@override
Widget build(BuildContext context) {
  return GlassCard(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min, // Fix: Tell column to only use necessary space
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
              Container(
          width: 36.w,
          height: 36.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: accent, size: 20.sp),
        ),
        SizedBox(width: 20.w),
        Flexible( // Fix: Prevents text from forcing an overflow
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Vibe.text, fontSize: 22.sp, fontWeight: FontWeight.w900),
          ),
        ),
          ],
        ),
        SizedBox(height: 20.h),
        Flexible( // Fix: Prevents text from forcing an overflow
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Vibe.muted, fontSize: 12.5.sp),
          ),
        ),
      ],
    ),
  );
}
}
