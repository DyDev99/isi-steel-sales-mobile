import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.userName = 'Demo'});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using the light gray background from the image
      backgroundColor: Vibe.canvas,
      body: Stack(
        children: [
          // 1. The Blue Header Background
          Container(
            height: 280.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Vibe.violet, Vibe.primaryHover],
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

                // 2. Overlapping Summary Card
                _buildSummaryCard(),
                SizedBox(height: 24.h),

                // 3. 2x2 Action Grid
                _buildActionGrid(),
                SizedBox(height: 24.h),

                // 4. Today's Visits Section
                _buildVisitsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                  'Good afternoon,',
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

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem(
                icon: Icons.attach_money_rounded,
                iconColor: Colors.green,
                iconBg: Colors.green.withValues(alpha: 0.1),
                value: 'R 0.00',
                label: "Today's Sales",
              ),
              _buildVerticalDivider(),
              _buildSummaryItem(
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.blue,
                iconBg: Colors.blue.withValues(alpha: 0.1),
                value: '3',
                label: "Orders Today",
              ),
              _buildVerticalDivider(),
              _buildSummaryItem(
                icon: Icons.location_on_rounded,
                iconColor: Colors.purple,
                iconBg: Colors.purple.withValues(alpha: 0.1),
                value: '0',
                label: "Check-ins",
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'View all sales >',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40.h,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.1,
      children: [
        _buildGridCard(
          icon: Icons.people_alt_rounded,
          iconColor: Colors.blue,
          iconBg: Colors.blue.withValues(alpha: 0.1),
          value: '10',
          label: 'Customers',
        ),
        _buildGridCard(
          icon: Icons.inventory_2_rounded,
          iconColor: Colors.green,
          iconBg: Colors.green.withValues(alpha: 0.1),
          value: '15',
          label: 'Products',
        ),
        _buildGridCard(
          icon: Icons.assignment_late_rounded,
          iconColor: Colors.orange,
          iconBg: Colors.orange.withValues(alpha: 0.1),
          value: '3',
          label: 'Pending',
        ),
        _buildGridCard(
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          iconBg: Colors.red.withValues(alpha: 0.1),
          value: '4',
          label: 'Low Stock',
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.w),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Visits",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "See All",
              style: TextStyle(
                color: Colors.blue,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: Colors.grey.shade400,
                size: 32.w,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
