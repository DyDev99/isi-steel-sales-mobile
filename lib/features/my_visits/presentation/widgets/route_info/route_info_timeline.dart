import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/l10n/visit_labels.dart';

/// Professional vertical route timeline for the Route Information screen.
///
/// Renders every [RouteStop] with a status rail, live distance and planned ETA.
/// The next-eligible stop ([nextIndex]) is highlighted; completed/missed stops
/// are muted. Tapping the highlighted stop (or its "Start Visit" affordance)
/// invokes [onStartStop] with that index. Rows fade/slide in with a short
/// staggered reveal on first build.
class RouteInfoTimeline extends StatefulWidget {
  const RouteInfoTimeline({
    super.key,
    required this.stops,
    required this.nextIndex,
    required this.onStartStop,
    this.onSkipStop,
    this.onCreateForStop,
    this.skipReasons = const {},
    this.currentPosition,
  });

  final List<RouteStop> stops;
  final int nextIndex;
  final ValueChanged<int> onStartStop;

  /// Invoked with a stop index when the rep chooses to skip it. When null, the
  /// per-stop skip affordance is hidden.
  final ValueChanged<int>? onSkipStop;

  /// Invoked for a **completed** stop when the rep wants to create commerce for
  /// its customer: `asOrder == false` → quotation, `true` → sales order. When
  /// null, the basket affordance is hidden.
  final void Function(int index, bool asOrder)? onCreateForStop;

  /// Reason text keyed by stop id, shown under skipped (missed) stops.
  final Map<String, String> skipReasons;
  final LocationSample? currentPosition;

  @override
  State<RouteInfoTimeline> createState() => _RouteInfoTimelineState();
}

class _RouteInfoTimelineState extends State<RouteInfoTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  double? _distanceTo(RouteStop stop) {
    final pos = widget.currentPosition;
    if (pos == null) return null;
    return GeofenceService.distanceMeters(
        pos.latitude, pos.longitude, stop.customer.latitude, stop.customer.longitude);
  }

  /// A stop can be skipped until it has been completed or already missed.
  bool _isSkippable(RouteStop stop) =>
      stop.status != VisitStatus.checkedOut &&
      stop.status != VisitStatus.missed;

  bool _isDone(RouteStop stop) => stop.status == VisitStatus.checkedOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.stops.length; i++)
          _RevealItem(
            controller: _reveal,
            index: i,
            child: _TimelineRow(
              stop: widget.stops[i],
              isFirst: i == 0,
              isLast: i == widget.stops.length - 1,
              isNext: i == widget.nextIndex,
              distanceMeters: _distanceTo(widget.stops[i]),
              onTap: i == widget.nextIndex
                  ? () => widget.onStartStop(i)
                  : null,
              onSkip: (widget.onSkipStop != null && _isSkippable(widget.stops[i]))
                  ? () => widget.onSkipStop!(i)
                  : null,
              skipReason: widget.skipReasons[widget.stops[i].id],
              onQuotation:
                  (widget.onCreateForStop != null && _isDone(widget.stops[i]))
                      ? () => widget.onCreateForStop!(i, false)
                      : null,
              onOrder:
                  (widget.onCreateForStop != null && _isDone(widget.stops[i]))
                      ? () => widget.onCreateForStop!(i, true)
                      : null,
            ),
          ),
      ],
    );
  }
}

/// Staggered fade + slide for a single row, spread across the first several
/// items so long routes still finish revealing quickly.
class _RevealItem extends StatelessWidget {
  const _RevealItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 12),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.isNext,
    required this.distanceMeters,
    required this.onTap,
    required this.onSkip,
    required this.skipReason,
    required this.onQuotation,
    required this.onOrder,
  });

  final RouteStop stop;
  final bool isFirst;
  final bool isLast;
  final bool isNext;
  final double? distanceMeters;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final String? skipReason;
  final VoidCallback? onQuotation;
  final VoidCallback? onOrder;

  bool get _isDone => stop.status == VisitStatus.checkedOut;
  bool get _isMissed => stop.status == VisitStatus.missed;

  Color _railColor(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    if (isNext) return scheme.primary;
    if (_isDone) return colors.success;
    if (_isMissed) return scheme.error;
    return colors.border;
  }

  String get _distanceLabel {
    if (distanceMeters == null) return 'my_visits.route_info.distance_unknown'.tr;
    final km = distanceMeters! / 1000;
    return km < 0.1
        ? '${distanceMeters!.round()} m'
        : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final railColor = _railColor(context);
    final muted = _isDone || _isMissed;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left rail: connector + status node.
          SizedBox(
            width: 28.w,
            child: Column(
              children: [
                Container(
                    width: 2.w,
                    height: 6.h,
                    color: isFirst ? Colors.transparent : colors.border),
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: muted ? railColor : colors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: railColor, width: 2.w),
                  ),
                  child: _isDone
                      ? Icon(Icons.check, size: 9.w, color: colors.card)
                      : null,
                ),
                Expanded(
                  child: Container(
                      width: 2.w,
                      color: isLast ? Colors.transparent : colors.border),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Stop card.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Opacity(
                opacity: muted ? 0.6 : 1,
                child: Material(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14.r),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: isNext
                            ? scheme.primary.withValues(alpha: 0.06)
                            : colors.card,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isNext ? scheme.primary : colors.border,
                          width: isNext ? 1.5.w : 1.w,
                        ),
                      ),
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stop.customer.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (isNext)
                                _NextBadge()
                              else
                                Text(
                                  stop.status.localizedLabel,
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                              if (onOrder != null || onQuotation != null) ...[
                                SizedBox(width: 8.w),
                                _BasketButton(
                                    onTap: onQuotation,),
                              ],
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            stop.customer.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 11.5.sp),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              _MiniInfo(
                                  icon: Icons.navigation_rounded,
                                  text: _distanceLabel),
                              SizedBox(width: 12.w),
                              _MiniInfo(
                                icon: Icons.schedule_rounded,
                                text: DateFormat('h:mm a')
                                    .format(stop.plannedArrival),
                              ),
                            ],
                          ),
                          if (isNext) ...[
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Icon(Icons.play_circle_fill_rounded,
                                    size: 15.w, color: scheme.primary),
                                SizedBox(width: 5.w),
                                Text(
                                  'my_visits.route_info.tap_to_start'.tr,
                                  style: TextStyle(
                                      color: scheme.primary,
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                          if (_isMissed && skipReason != null) ...[
                            SizedBox(height: 8.h),
                            _SkippedReason(reason: skipReason!),
                          ],
                          if (onSkip != null) ...[
                            SizedBox(height: 8.h),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _SkipButton(onTap: onSkip!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'my_visits.flow.pill_next'.tr,
        style: TextStyle(
            color: scheme.onPrimary,
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// Basket pop-up shown on completed stops — a quick jump to create a quotation
/// or a sales order for that stop's customer. `false` = quotation, `true` =
/// order (matches [RouteInfoTimeline.onCreateForStop]).
/// Simple basket icon button that directly triggers quotation creation on tap.
class _BasketButton extends StatelessWidget {
  const _BasketButton({required this.onTap});

  // 1. Add the '?' to make it nullable
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // 2. InkWell natively handles null
        borderRadius: BorderRadius.circular(20.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            Icons.shopping_basket_rounded,
            size: 16.w,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
/// Low-emphasis "Skip stop" affordance shown on stops not yet resolved.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.skip_next_rounded, size: 15.w, color: scheme.error),
            SizedBox(width: 4.w),
            Text(
              'my_visits.route_info.skip_stop'.tr,
              style: TextStyle(
                  color: scheme.error,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the reason a stop was skipped, under a missed stop.
class _SkippedReason extends StatelessWidget {
  const _SkippedReason({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 13.w, color: scheme.error),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              'my_visits.route_info.skipped_with_reason'
                  .trParams({'reason': reason}),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.w, color: colors.iconMuted),
        SizedBox(width: 4.w),
        Text(text,
            style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
