import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/interactive.dart';

/// Home-tab 2×2 quick-action grid (Customers / My Visits / Sales Order /
/// Revenue). Extracted from `MainShell`; navigation is delegated to the
/// caller via callbacks so this stays a pure presentational widget.
class HomeActionGrid extends StatelessWidget {
  const HomeActionGrid({
    super.key,
    required this.onCustomersTap,
    required this.onVisitsTap,
    required this.onOrdersTap,
    required this.onRevenueTap,
  });

  final VoidCallback onCustomersTap;
  final VoidCallback onVisitsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onRevenueTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10.h,
      crossAxisSpacing: 10.w,
      childAspectRatio: 1.15,
      children: [
        _GridCard(
          icon: Icons.people_alt_rounded,
          iconColor: Vibe.brandNavy,
          iconBg: Vibe.brandNavy.withValues(alpha: 0.1),
          value: '150',
          label: 'customers.title'.tr,
          onTap: onCustomersTap,
        ),
        _GridCard(
          icon: Icons.location_on_rounded,
          iconColor: Colors.purple,
          iconBg: Colors.purple.withValues(alpha: 0.1),
          value: '12',
          label: 'my_visits.title'.tr,
          onTap: onVisitsTap,
        ),
        _GridCard(
          icon: Icons.receipt_long_rounded,
          iconColor: Colors.orange,
          iconBg: Colors.orange.withValues(alpha: 0.1),
          value: '45',
          label: 'orders.sales_order.title'.tr,
          onTap: onOrdersTap,
        ),
        _RevenueCard(
          achieved: '\$10k',
          target: '\$12.5k',
          onTap: onRevenueTap,
        ),
      ],
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DashboardActionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6.r)),
            child: Icon(icon, color: iconColor, size: 16.w),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.achieved, required this.target, required this.onTap});

  final String achieved;
  final String target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DashboardActionCard(
      onTap: onTap,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(Icons.attach_money_rounded, color: Colors.green, size: 16.w),
          ),
          SizedBox(height: 6.h),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: achieved,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Vibe.text),
                ),
                TextSpan(
                  text: ' ${'home.achieved'.tr}',
                  style: TextStyle(fontSize: 9.5.sp, color: Colors.grey.shade500),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: target,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.sp, color: Colors.grey.shade600),
                ),
                TextSpan(
                  text: ' ${'home.target'.tr}',
                  style: TextStyle(fontSize: 9.5.sp, color: Colors.grey.shade500),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Flat white action card with a soft resting shadow that lifts on hover
/// (desktop/web) and settles into a tight press shadow on tap — tactile on
/// touch, alive under a mouse. Shared by every Home action-grid card.
class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.onTap,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return InteractiveScale(
      onTap: onTap,
      hoverScale: 1.02,
      builder: (context, isHovered, isPressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isHovered ? Vibe.violet.withValues(alpha: 0.35) : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Vibe.text.withValues(alpha: isPressed ? 0.04 : (isHovered ? 0.12 : 0.08)),
              blurRadius: isPressed ? 6 : (isHovered ? 18 : 14),
              offset: Offset(0, isPressed ? 1 : (isHovered ? 6 : 4)),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
