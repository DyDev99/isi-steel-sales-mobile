import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// "Today's Objectives" strip for the Route Information screen — the kinds of
/// work planned for the route (Visit, Stock Count, Quotation, Collection,
/// Follow-up).
///
/// **Placeholder:** objectives are not modeled per-route yet, so this shows the
/// standard field-visit objective set as guidance, not live counts. Wire to a
/// real per-route objective source when one exists.
class RouteInfoObjectives extends StatelessWidget {
  const RouteInfoObjectives({super.key});

  static const _items = <({IconData icon, String key})>[
    (icon: Icons.handshake_rounded, key: 'my_visits.route_info.obj_visit'),
    (icon: Icons.inventory_2_rounded, key: 'my_visits.route_info.obj_stock'),
    (
      icon: Icons.request_quote_rounded,
      key: 'my_visits.route_info.obj_quotation'
    ),
    (icon: Icons.payments_rounded, key: 'my_visits.route_info.obj_collection'),
    (icon: Icons.event_repeat_rounded, key: 'my_visits.route_info.obj_followup'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 92.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _items.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          final item = _items[i];
          return Container(
            width: 92.w,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(item.icon, size: 17.w, color: scheme.primary),
                ),
                Text(
                  item.key.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
