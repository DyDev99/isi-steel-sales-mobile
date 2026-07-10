import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';

class MyWorkGridSection extends StatelessWidget {
  const MyWorkGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header: Bold, tracked out uppercase label
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
            child: Text(
              'MY WORK',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: const Color(0xFF7A869A), // Sophisticated slate gray
              ),
            ),
          ),

          // Grid Layout: Row 1
          Row(
            children: [
              Expanded(
                child: _buildWorkCard(
                  label: 'My Leads',
                  icon: Icons.layers_outlined,
                  iconColor: const Color(0xFF4C9AFF),
                  iconBgColor: const Color(0xFFE6F0FF),
                  badgeText: '1 due',
                  isActive: false,
                  onTap: () => sl<ShellTabController>().goTo(ShellTab.leads),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildWorkCard(
                  label: 'My Visits',
                  icon: Icons.assignment_turned_in_outlined,
                  iconColor: const Color(0xFF36B37E),
                  iconBgColor: const Color(0xFFE3FCEF),
                  badgeText: '3 today',
                  isActive:
                      true, // Highlights with the focused deep border seen in your image
                  onTap: () => sl<ShellTabController>().goTo(ShellTab.myVisits),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Grid Layout: Row 2
          Row(
            children: [
              Expanded(
                child: _buildWorkCard(
                  label: 'My Customers',
                  icon: Icons.people_alt_outlined,
                  iconColor: const Color(0xFFFF5C00),
                  iconBgColor: const Color(0xFFFFF0E6),
                  isActive: false,
                  onTap: () =>
                      sl<ShellTabController>().goTo(ShellTab.customers),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildWorkCard(
                  label: 'My Quotes & Orders',
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFFFFAB00),
                  iconBgColor: const Color(0xFFFFF7E6),
                  isActive: false,
                  onTap: () => sl<ShellTabController>().goTo(ShellTab.orders),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Core Bento Card Layout Builder
  Widget _buildWorkCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    String? badgeText,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 116.h, // Structured layout height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r), // Playful soft corners

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.05 : 0.02),
              blurRadius: isActive ? 16 : 10,
              offset: Offset(0, isActive ? 6 : 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Internal Main Content Frame
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Housing Area
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

                    // Floating Pill Badge implementation
                    if (badgeText != null)
                      Positioned(
                        top: -6.h,
                        right: -32.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(
                                0xFF0A3066), // Deep energetic navy block
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight:
                                  FontWeight.w900, // Thick high-impact font
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Card Labels
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800, // Heavy punchy style weight
                      color:
                          const Color(0xFF091E42), // Strong ink text contrast
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
