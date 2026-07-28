import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Quick actions available on the Route Information screen for the next stop's
/// customer.
///
/// Call / Navigate are not yet wired (no `url_launcher` dependency) — the screen
/// surfaces a "coming soon" placeholder for those, per the agreed placeholder
/// approach. View Customer / Notes / History are hooks the screen fulfils.
enum RouteInfoAction { call, navigate, viewCustomer, notes, history }

class RouteInfoQuickActions extends StatelessWidget {
  const RouteInfoQuickActions({super.key, required this.onAction});

  final ValueChanged<RouteInfoAction> onAction;

  static const _items = <({IconData icon, String key, RouteInfoAction action})>[
    (
      icon: Icons.call_rounded,
      key: 'my_visits.route_info.action_call',
      action: RouteInfoAction.call
    ),
    (
      icon: Icons.directions_rounded,
      key: 'my_visits.route_info.action_navigate',
      action: RouteInfoAction.navigate
    ),
    (
      icon: Icons.person_rounded,
      key: 'my_visits.route_info.action_customer',
      action: RouteInfoAction.viewCustomer
    ),
    (
      icon: Icons.sticky_note_2_rounded,
      key: 'my_visits.route_info.action_notes',
      action: RouteInfoAction.notes
    ),
    (
      icon: Icons.history_rounded,
      key: 'my_visits.route_info.action_history',
      action: RouteInfoAction.history
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in _items)
          Expanded(
            child: _ActionButton(
              icon: item.icon,
              label: item.key.tr,
              onTap: () => onAction(item.action),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
        child: Column(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: colors.border),
              ),
              child: Icon(icon, size: 20.w, color: scheme.primary),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
