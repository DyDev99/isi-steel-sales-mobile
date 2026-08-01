import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/stop_dashboard_state.dart';

/// Animated summary strip for the Stop Dashboard: today's stops, completed,
/// remaining, nearest stop, total distance, estimated travel time. Numeric
/// values count up when they change. Pure display of [StopDashboardSummary].
class StopDashboardSummaryBar extends StatelessWidget {
  const StopDashboardSummaryBar({super.key, required this.summary});

  final StopDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final nearest = summary.nearestName;
    final nearestDist = summary.nearestDistanceMeters;
    final nearestSub = nearest == null
        ? '—'
        : (nearestDist == null
            ? nearest
            : '$nearest · ${_distanceLabel(nearestDist)}');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.brandNavy, colors.brandNavyDark],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                _CountStat(
                    value: summary.total,
                    label: 'my_visits.stop_dashboard.stat_stops'.tr),
                _Divider(),
                _CountStat(
                    value: summary.completed,
                    label: 'my_visits.stop_dashboard.stat_completed'.tr),
                _Divider(),
                _CountStat(
                    value: summary.remaining,
                    label: 'my_visits.stop_dashboard.stat_remaining'.tr),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _TextStat(
                    icon: Icons.near_me_rounded,
                    label: 'my_visits.stop_dashboard.stat_nearest'.tr,
                    value: nearestSub,
                    accent: scheme.onPrimary,
                  ),
                ),
                _Divider(),
                Expanded(
                  flex: 2,
                  child: _TextStat(
                    icon: Icons.route_rounded,
                    label: 'my_visits.stop_dashboard.stat_distance'.tr,
                    value: summary.totalDistanceKm < 0.1
                        ? '—'
                        : '${summary.totalDistanceKm.toStringAsFixed(1)} km',
                  ),
                ),
                _Divider(),
                Expanded(
                  flex: 2,
                  child: _TextStat(
                    icon: Icons.schedule_rounded,
                    label: 'my_visits.stop_dashboard.stat_travel'.tr,
                    value: summary.totalTravelMinutes <= 0
                        ? '—'
                        : '${summary.totalTravelMinutes} min',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _distanceLabel(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
  }
}

class _CountStat extends StatelessWidget {
  const _CountStat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              v.round().toString(),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(height: 2.h),
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _TextStat extends StatelessWidget {
  const _TextStat(
      {required this.icon,
      required this.label,
      required this.value,
      this.accent});
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12.w, color: Colors.white.withValues(alpha: 0.7)),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: accent ?? Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 26.h,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        color: Colors.white.withValues(alpha: 0.16),
      );
}
