import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';

class MyWorkGridSection extends StatelessWidget {
  const MyWorkGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Wrapping the entire section in the coach key so the spotlight targets it cleanly[cite: 11, 12]
    return CoachKeys.wrap(
      CoachKeys.myWork,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
              child: Text(
                'MY WORK',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: CoachKeys.wrap(
                    CoachKeys.myLeads,
                    child: _buildWorkCard(
                      context: context,
                      label: 'My Leads',
                      icon: Icons.layers_outlined,
                      iconColor: const Color(0xFF4C9AFF),
                      iconBgColor: const Color(0xFF4C9AFF).withValues(alpha: 0.15),
                      badgeText: '1 due',
                      isActive: false,
                      onTap: () => sl<ShellTabController>().goTo(ShellTab.leads),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CoachKeys.wrap(
                    CoachKeys.myVisits,
                    child: _buildWorkCard(
                      context: context,
                      label: 'My Visits',
                      icon: Icons.assignment_turned_in_outlined,
                      iconColor: const Color(0xFF36B37E),
                      iconBgColor: const Color(0xFF36B37E).withValues(alpha: 0.15),
                      badgeText: '3 today',
                      isActive: true,
                      onTap: () => sl<ShellTabController>().goTo(ShellTab.myVisits),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: CoachKeys.wrap(
                    CoachKeys.myCustomers,
                    child: _buildWorkCard(
                      context: context,
                      label: 'My Customers',
                      icon: Icons.people_alt_outlined,
                      iconColor: const Color(0xFFFF5C00),
                      iconBgColor: const Color(0xFFFF5C00).withValues(alpha: 0.15),
                      isActive: false,
                      onTap: () =>
                          sl<ShellTabController>().goTo(ShellTab.customers),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CoachKeys.wrap(
                    CoachKeys.orders,
                    child: _buildWorkCard(
                      context: context,
                      label: 'My Quotes & Orders',
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFFFFAB00),
                      iconBgColor: const Color(0xFFFFAB00).withValues(alpha: 0.15),
                      isActive: false,
                      onTap: () => sl<ShellTabController>().goTo(ShellTab.orders),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    String? badgeText,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 116.h,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.02),
              blurRadius: isActive ? 16 : 10,
              offset: Offset(0, isActive ? 6 : 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46.r,
                      height: 46.r,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 22.r,
                        ),
                      ),
                    ),
                    if (badgeText != null)
                      Positioned(
                        top: -6.h,
                        right: -32.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: scheme.onSecondary,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}