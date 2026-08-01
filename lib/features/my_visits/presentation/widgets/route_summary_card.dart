import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';

/// Dashboard route-summary card — one per [RoutePlan]. Answers "which route
/// should I start?" with a glanceable summary only (name, territory, status,
/// progress, stop counts, live distance/ETA, priority), never per-stop detail.
///
/// Pure presentation: every value comes from [RoutePlan]'s own getters or from
/// [GeofenceService] against the passed [currentPosition] — no bloc, no I/O.
/// Tapping opens the Route Information screen (wired by the caller).
///
/// The route name is wrapped in a [Hero] (`route-name-<id>`) so it shares a
/// flight into the Route Information hero header.
class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.route,
    required this.onTap,
    this.currentPosition,
  });

  final RoutePlan route;
  final VoidCallback onTap;

  /// Live GPS fix, if tracking is active — used to show distance/ETA to the
  /// next unvisited stop. Null falls back to a "--" label.
  final LocationSample? currentPosition;

  /// First stop not yet visited — the route's live "next" target.
  RouteStop? get _nextStop {
    for (final s in route.stops) {
      if (s.status != VisitStatus.checkedOut &&
          s.status != VisitStatus.missed) {
        return s;
      }
    }
    return null;
  }

  double? get _distanceToNextMeters {
    final pos = currentPosition;
    final next = _nextStop;
    if (pos == null || next == null) return null;
    return GeofenceService.distanceMeters(
      pos.latitude,
      pos.longitude,
      next.customer.latitude,
      next.customer.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final status = _statusStyle(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(18.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: colors.border, width: 1.w),
              boxShadow: colors.cardShadow,
            ),
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row: route name + status pill.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'route-name-${route.id}',
                        flightShuttleBuilder: _titleShuttle,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            route.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _Pill(label: status.label, color: status.color),
                  ],
                ),
                SizedBox(height: 4.h),

                // Territory · date subline.
                Text(
                  '${route.territory} · ${DateFormat('EEE, MMM d').format(route.visitDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 12.sp),
                ),
                SizedBox(height: 12.h),

                // Progress bar + completed/total.
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: LinearProgressIndicator(
                          value: route.progress,
                          minHeight: 7.h,
                          backgroundColor: colors.surfaceStrong,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(scheme.primary),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '${route.completedStops}/${route.totalStops}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Metric chips: stops · remaining · distance/ETA · priority.
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _MetricChip(
                      icon: Icons.storefront_rounded,
                      label: 'my_visits.route_info.stops_count'
                          .trParams({'count': route.totalStops}),
                    ),
                    _MetricChip(
                      icon: Icons.pending_actions_rounded,
                      label: 'my_visits.route_info.remaining_count'.trParams(
                          {'count': route.totalStops - route.completedStops}),
                    ),
                    _MetricChip(
                      icon: Icons.navigation_rounded,
                      label: _distanceEtaLabel(),
                    ),
                    _PriorityChip(level: _priority()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _distanceEtaLabel() {
    final meters = _distanceToNextMeters;
    if (meters == null) return 'my_visits.route_info.distance_unknown'.tr;
    final km = meters / 1000;
    final distance =
        km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
    // Same 25 km/h blended field-average used by RouteDashboardCubit.
    final etaMin = ((km / 25) * 60).clamp(1, 999).round();
    return 'my_visits.route_info.distance_eta'
        .trParams({'distance': distance, 'eta': etaMin});
  }

  /// Placeholder priority heuristic until routes carry a real priority field:
  /// a route whose next stop's planned arrival is now/overdue reads as "high".
  _Priority _priority() {
    final next = _nextStop;
    if (next == null) return _Priority.normal;
    return next.plannedArrival.isBefore(DateTime.now())
        ? _Priority.high
        : _Priority.normal;
  }

  ({String label, Color color}) _statusStyle(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return switch (route.status) {
      RouteStatus.planned => (
          label: 'my_visits.route_info.status_planned'.tr,
          color: colors.textSecondary
        ),
      RouteStatus.published => (
          label: 'my_visits.route_info.status_published'.tr,
          color: colors.info
        ),
      RouteStatus.inProgress => (
          label: 'my_visits.route_info.status_in_progress'.tr,
          color: scheme.primary
        ),
      RouteStatus.completed => (
          label: 'my_visits.route_info.status_completed'.tr,
          color: colors.success
        ),
    };
  }

  /// Keeps the Hero title legible (not doubled/boxed) mid-flight.
  Widget _titleShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) =>
      DefaultTextStyle(
        style: DefaultTextStyle.of(toHeroContext).style,
        child: toHeroContext.widget,
      );
}

enum _Priority { high, normal }

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.level});
  final _Priority level;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (color, key) = switch (level) {
      _Priority.high => (colors.warning, 'my_visits.route_info.priority_high'),
      _Priority.normal => (
          colors.textSecondary,
          'my_visits.route_info.priority_normal'
        ),
    };
    return _MetricChip(
      icon: Icons.flag_rounded,
      label: key.tr,
      color: color,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = color ?? colors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.w, color: fg),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10.5.sp, fontWeight: FontWeight.w800),
      ),
    );
  }
}
