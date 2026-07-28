import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_map.dart';

/// Small embedded map preview for the Route Information screen: current location
/// + the whole route, current stop highlighted. Tapping expands to a full-screen
/// map. Reuses the existing [RouteMap] (which owns marker/polyline/geofence
/// rendering and disposes its native controller correctly).
class RouteInfoMapPreview extends StatelessWidget {
  const RouteInfoMapPreview({
    super.key,
    required this.stops,
    required this.currentStopIndex,
    this.currentPosition,
  });

  final List<RouteStop> stops;
  final int currentStopIndex;
  final LocationSample? currentPosition;

  void _expand(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullScreenMap(
        stops: stops,
        currentStopIndex: currentStopIndex,
        currentPosition: currentPosition,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: SizedBox(
        height: 160.h,
        child: Stack(
          children: [
            // AbsorbPointer: the preview is a *summary* — pan/zoom belongs to the
            // expanded map, so the whole tile acts as one "expand" button.
            Positioned.fill(
              child: AbsorbPointer(
                child: RouteMap(
                  stops: stops,
                  currentStopIndex: currentStopIndex,
                  currentPosition: currentPosition,
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: () => _expand(context)),
              ),
            ),
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: colors.border),
                  boxShadow: colors.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_full_rounded,
                        size: 13.w, color: colors.textPrimary),
                    SizedBox(width: 5.w),
                    Text(
                      'my_visits.route_info.expand_map'.tr,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenMap extends StatelessWidget {
  const _FullScreenMap({
    required this.stops,
    required this.currentStopIndex,
    required this.currentPosition,
  });

  final List<RouteStop> stops;
  final int currentStopIndex;
  final LocationSample? currentPosition;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.card,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('my_visits.route_info.route_map'.tr,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800)),
      ),
      body: RouteMap(
        stops: stops,
        currentStopIndex: currentStopIndex,
        currentPosition: currentPosition,
      ),
    );
  }
}
