import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.userName = 'Demo'});
  final String userName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: Stack(
        children: [
          // 1. The brand header background.
          Container(
            height: 280.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, colors.primaryHover],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                _buildTopBar(),
                SizedBox(height: 24.h),
                _buildSummaryCard(context),
                SizedBox(height: 24.h),
                _buildActionGrid(context),
                SizedBox(height: 24.h),
                _buildVisitsSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The top bar sits on the brand gradient, so its text/avatar stay white in
  // both themes by design.
  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'common.good_afternoon'.tr},',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 20.r,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                'DA',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem(
                context,
                icon: Icons.attach_money_rounded,
                iconColor: colors.success,
                iconBg: colors.success.withValues(alpha: 0.12),
                value: 'R 0.00',
                label: 'home.todays_sales'.tr,
              ),
              _buildVerticalDivider(context),
              _buildSummaryItem(
                context,
                icon: Icons.receipt_long_rounded,
                iconColor: scheme.primary,
                iconBg: scheme.primary.withValues(alpha: 0.12),
                value: '3',
                label: 'home.orders_today'.tr,
              ),
              _buildVerticalDivider(context),
              _buildSummaryItem(
                context,
                icon: Icons.location_on_rounded,
                iconColor: colors.accentPurple,
                iconBg: colors.accentPurple.withValues(alpha: 0.12),
                value: '0',
                label: 'home.check_ins'.tr,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'home.view_all_sales'.tr,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: 40.h,
      width: 1,
      color: context.appColors.border,
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16.w),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
                color: context.appColors.textSecondary, fontSize: 10.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.1,
      children: [
        _buildGridCard(
          context,
          icon: Icons.people_alt_rounded,
          accent: scheme.primary,
          value: '10',
          label: 'home.quick_access.customers'.tr,
        ),
        _buildGridCard(
          context,
          icon: Icons.inventory_2_rounded,
          accent: colors.success,
          value: '15',
          label: 'home.products'.tr,
        ),
        _buildGridCard(
          context,
          icon: Icons.assignment_late_rounded,
          accent: colors.warning,
          value: '3',
          label: 'home.quick_access.pending'.tr,
        ),
        _buildGridCard(
          context,
          icon: Icons.warning_rounded,
          accent: scheme.error,
          value: '4',
          label: 'home.low_stock'.tr,
        ),
      ],
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: accent, size: 20.w),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
                color: context.appColors.textSecondary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.todays_visits'.tr,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'common.see_all'.tr,
              style: TextStyle(
                color: scheme.primary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 40.h),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: colors.textHint,
                size: 32.w,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
