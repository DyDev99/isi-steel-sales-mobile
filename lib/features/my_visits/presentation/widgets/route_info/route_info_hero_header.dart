import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';

/// Large hero header for the Route Information screen: route name (shared [Hero]
/// from the dashboard card), territory, today's progress, a live clock, and the
/// estimated finish time. Includes a **placeholder** weather chip (weather is
/// not modeled yet — labelled as such).
///
/// Stateful only for the ticking clock; all other values are read from
/// [RoutePlan]. No business logic.
class RouteInfoHeroHeader extends StatefulWidget {
  const RouteInfoHeroHeader({super.key, required this.route});

  final RoutePlan route;

  @override
  State<RouteInfoHeroHeader> createState() => _RouteInfoHeroHeaderState();
}

class _RouteInfoHeroHeaderState extends State<RouteInfoHeroHeader> {
  late Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 1s tick for the live clock; cheap and scoped to this widget.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final route = widget.route;
    final progressPct = (route.progress * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 22.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.brandNavy, colors.brandNavyDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'route-name-${route.id}',
                      flightShuttleBuilder: (_, __, ___, ____, toCtx) =>
                          DefaultTextStyle(
                        style: DefaultTextStyle.of(toCtx).style,
                        child: toCtx.widget,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          route.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.place_rounded,
                            size: 13.w,
                            color: Colors.white.withValues(alpha: 0.8)),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            route.territory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _WeatherPlaceholderChip(),
            ],
          ),
          SizedBox(height: 18.h),

          // Progress + clock/finish row.
          Row(
            children: [
              _HeroStat(
                label: 'my_visits.route_info.hero_progress'.tr,
                value: '$progressPct%',
              ),
              _HeroDivider(),
              _HeroStat(
                label: 'my_visits.route_info.hero_now'.tr,
                value: DateFormat('h:mm a').format(_now),
              ),
              _HeroDivider(),
              _HeroStat(
                label: 'my_visits.route_info.hero_finish'.tr,
                value: DateFormat('h:mm a').format(route.plannedEnd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900)),
          SizedBox(height: 2.h),
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 26.h,
        margin: EdgeInsets.symmetric(horizontal: 12.w),
        color: Colors.white.withValues(alpha: 0.18),
      );
}

class _WeatherPlaceholderChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_cloudy_rounded,
              size: 14.w, color: Colors.white.withValues(alpha: 0.9)),
          SizedBox(width: 5.w),
          Text(
            'my_visits.route_info.weather_placeholder'.tr,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11.sp,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
