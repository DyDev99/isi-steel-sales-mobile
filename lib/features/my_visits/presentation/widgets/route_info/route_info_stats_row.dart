import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Quick-statistics strip for the Route Information screen. Pure display: all
/// five values are computed by the screen (from [RoutePlan] getters +
/// GeofenceService) and passed in, so this widget holds no logic.
class RouteInfoStatsRow extends StatelessWidget {
  const RouteInfoStatsRow({
    super.key,
    required this.total,
    required this.completed,
    required this.remaining,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final int total;
  final int completed;
  final int remaining;
  final double distanceKm;
  final int durationMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final cards = <Widget>[
      _StatCard(
        icon: Icons.storefront_rounded,
        color: scheme.primary,
        value: '$total',
        label: 'my_visits.route_info.stat_total'.tr,
      ),
      _StatCard(
        icon: Icons.check_circle_rounded,
        color: colors.success,
        value: '$completed',
        label: 'my_visits.route_info.stat_completed'.tr,
      ),
      _StatCard(
        icon: Icons.pending_actions_rounded,
        color: colors.warning,
        value: '$remaining',
        label: 'my_visits.route_info.stat_remaining'.tr,
      ),
      _StatCard(
        icon: Icons.route_rounded,
        color: colors.info,
        value: distanceKm < 0.1 ? '0' : distanceKm.toStringAsFixed(1),
        unit: 'km',
        label: 'my_visits.route_info.stat_distance'.tr,
      ),
      _StatCard(
        icon: Icons.schedule_rounded,
        color: colors.accentPurple,
        value: '$durationMinutes',
        unit: 'min',
        label: 'my_visits.route_info.stat_duration'.tr,
      ),
    ];

    // Horizontal scroller keeps five cards one-handed on narrow phones without
    // squeezing; on wide/tablet layouts they simply fill more of the row.
    return SizedBox(
      height: 88.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: cards.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.unit,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 96.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 18.w, color: color),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w900),
                ),
              ),
              if (unit != null) ...[
                SizedBox(width: 2.w),
                Text(unit!,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
