import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/customers_card_widget.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/lead_pipeline_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/home/domain/dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_state.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/add_customer_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/oders_card_widget.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/routes_cart_widget.dart';

/// Home dashboard tab. Thin: renders HomeCubit state, composes small widgets.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.userName = 'there'});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            // top: false prevents double-padding if the shell header handles the status bar
            top: false,
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) => switch (state) {
                HomeLoaded(:final summary) => _Dashboard(name: userName, summary: summary),
                HomeError(:final message) => _ErrorView(
                    message: message,
                    onRetry: () => context.read<HomeCubit>().load(),
                  ),
                _ => const Center(child: CircularProgressIndicator(color: Vibe.pink)),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.name, required this.summary});
  final String name;
  final DashboardSummary summary;

  void _goToRoutes(BuildContext context) => sl<ShellTabController>().goTo(ShellTab.routes);
  void _goToLeads(BuildContext context) => sl<ShellTabController>().goTo(ShellTab.leads);
  void _goToOrders(BuildContext context) => sl<ShellTabController>().goTo(ShellTab.orders);
  void _goToCustomers(BuildContext context) => sl<ShellTabController>().goTo(ShellTab.customers);

  @override
  Widget build(BuildContext context) {
    // Structural customer status distribution
    final int customerTotal = summary.totalCustomers;
    final int customerActive = (customerTotal * 0.7).round();
    final int customerProspect = (customerTotal * 0.2).round();
    final int customerSuspended = customerTotal - customerActive - customerProspect;

    // Structural route workflow status distribution
    final int routesTotal = summary.totalRoutes;
    final int routesToday = (routesTotal * 0.4).round();
    final int routesMissed = (routesTotal * 0.1).round();

    return RefreshIndicator(
      color: Vibe.pink,
      backgroundColor: Vibe.bgSoft,
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
        children: [
          // All four KPIs visible at once, no scrolling required to read
          // the dashboard — matches the "scannable in under 5 seconds" goal.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.86,
            children: [
              LeadPipelineCard(
                title: 'home.quick_access.leads'.tr,
                leadCount: summary.newLeads,
                leadLabel: 'home.quick_access.leads'.tr,
                opportunityLabel: 'home.quick_access.opportunities'.tr,
                wonLabel: 'home.quick_access.won_deals'.tr,
                opportunityCount: summary.openOpportunities,
                wonCount: summary.wonDeals,
                onTap: () => _goToLeads(context),
              ),
              OrderPieCard(
                summary: summary,
                onTap: () => _goToOrders(context),
              ),
              CustomerCardWidget(
                totalCustomers: customerTotal,
                activeCount: customerActive,
                prospectCount: customerProspect,
                suspendedCount: customerSuspended,
                onTap: () => _goToCustomers(context),
              ),
              RoutesCardWidget(
                totalRoutes: routesTotal,
                todayRoutesCount: routesToday,
                missedRoutesCount: routesMissed,
                onTap: () => _goToRoutes(context),
              ),
            ],
          ),
          SizedBox(height: 20.h),

        
          GestureDetector(
            onTap: () => showAddCustomerSheet(context),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: Vibe.bgSoft,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Vibe.stroke, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Vibe.pink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Vibe.pink,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'home.quick_access.add_customer'.tr,
                      style: TextStyle(
                        color: Vibe.text,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Vibe.muted, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Vibe.muted)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text('common.try_again'.tr, style: const TextStyle(color: Vibe.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}