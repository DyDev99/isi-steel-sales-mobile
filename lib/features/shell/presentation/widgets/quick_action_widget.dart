import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_action.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/app_coach.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/depot_selection_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/territory/territory_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/add_customer_bottom_sheet.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  void _startNewOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: TerritoryScreen.routeName),
      builder: (_) => const TerritoryScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: CoachKeys.wrap(
                  CoachKeys.newQuote,
                  child: _buildActionCard(
                    context: context,
                    icon: Icons.assignment_outlined,
                    iconColor: const Color(0xFF4C9AFF),
                    bgColor: const Color(0xFF4C9AFF).withValues(alpha: 0.15),
                    label: 'New quote',
                    onTap: () => _startNewOrder(context),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CoachKeys.wrap(
                  CoachKeys.newLead,
                  child: _buildActionCard(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF36B37E),
                    bgColor: const Color(0xFF36B37E).withValues(alpha: 0.15),
                    label: 'New lead',
                    onTap: () {
                      // Report the real action so the coach's "New Lead" step
                      // advances (no-op when the coach isn't running).
                      AppCoach.notify(CoachAction.createLead);
                      showAddCustomerSheet(context);
                    },
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CoachKeys.wrap(
                  CoachKeys.depotStock,
                  child: _buildActionCard(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFFFFAB00),
                    bgColor: const Color(0xFFFFAB00).withValues(alpha: 0.15),
                    label: 'Depot stock',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(
                            name: DepotSelectionScreen.routeName),
                        builder: (_) => const DepotSelectionScreen(),
                      ),
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

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.appColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
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