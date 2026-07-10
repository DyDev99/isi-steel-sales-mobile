import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/depot_selection_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/territory/territory_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/add_customer_bottom_sheet.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  /// Enters the order/quote flow at its canonical first step, reusing the same
  /// entry point (`TerritoryScreen`) the Orders tab uses for a new order.
  void _startNewOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: TerritoryScreen.routeName),
      builder: (_) => const TerritoryScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: const Color(0xFF7A869A), // Muted slate gray
              ),
            ),
          ),

          // Action Items Row
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFF4C9AFF), // Soft blue accent
                  bgColor: const Color(0xFFE6F0FF),
                  label: 'New quote',
                  onTap: () => _startNewOrder(context),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildActionCard(
                  icon: Icons
                      .bar_chart_rounded, // Swap for asset illustration if needed
                  iconColor: const Color(0xFF36B37E), // Soft green accent
                  bgColor: const Color(0xFFE3FCEF),
                  label: 'New lead',
                  onTap: () {
                    // Handle New Lead Tap
                    showAddCustomerSheet(context);
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFFFAB00),
                  bgColor: const Color(0xFFFFF7E6),
                  label: 'Depot stock',
                  // Guided workflow: choose a depot/shop first, then count its
                  // stock — never straight into the counting screen.
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(
                          name: DepotSelectionScreen.routeName),
                      builder: (_) => const DepotSelectionScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable card builder
  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Rounded Container
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22.r,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Card Label Text
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF091E42), // Clean dark typography
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
