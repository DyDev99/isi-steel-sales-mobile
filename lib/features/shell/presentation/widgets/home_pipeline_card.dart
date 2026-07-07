import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Home-tab pipeline snapshot card (Leads / Opportunities / Won).
///
/// Pure presentational widget extracted from `MainShell` — `const`, so it is
/// skipped on parent rebuilds that don't change it. The card is wrapped by
/// the caller in a `GestureDetector` that jumps to the Leads tab.
class HomePipelineCard extends StatelessWidget {
  const HomePipelineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PipelineItem(
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: Colors.orange,
                  iconBg: Colors.orange.withValues(alpha: 0.1),
                  value: '12',
                  label: 'leads.title'.tr,
                ),
              ),
              const _PipelineDivider(),
              Expanded(
                child: _PipelineItem(
                  icon: Icons.trending_up_rounded,
                  iconColor: Vibe.brandNavy,
                  iconBg: Vibe.brandNavy.withValues(alpha: 0.1),
                  value: '5',
                  label: 'leads.opportunities'.tr,
                ),
              ),
              const _PipelineDivider(),
              Expanded(
                child: _PipelineItem(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.green,
                  iconBg: Colors.green.withValues(alpha: 0.1),
                  value: '2',
                  label: 'leads.won_deals'.tr,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'leads.view_leads'.tr,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineItem extends StatelessWidget {
  const _PipelineItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16.w),
        ),
        SizedBox(height: 6.h),
        Text(value, style: TextStyle(color: Vibe.text, fontWeight: FontWeight.bold, fontSize: 16.sp)),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.sp),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PipelineDivider extends StatelessWidget {
  const _PipelineDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30.h,
      width: 1,
      color: Vibe.stroke,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }
}
