import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/lead_pipeline_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/home/domain/dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_state.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/add_customer_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/metric_card.dart';

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
    return RefreshIndicator(
      color: Vibe.pink,
      backgroundColor: Vibe.bgSoft,
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        children: [
          // 1. Full-Width Lead Pipeline Section
          // This gives the chart room to display left/right status text seamlessly
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
          SizedBox(height: 12.h),
          
          // 2. Uniform 2x2 Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.4, // Optimized sizing ratio for clean grid alignment
            children: [
              MetricCard(
                label: 'home.quick_access.orders'.tr,
                value: '${summary.openOrders}',
                icon: Icons.receipt_long_rounded,
                accent: Vibe.mint,
                onTap: () => _goToOrders(context),
              ),
              MetricCard(
                label: 'home.quick_access.customers'.tr,
                value: '${summary.totalCustomers}',
                icon: Icons.people_alt_rounded,
                accent: Vibe.success,
                onTap: () => _goToCustomers(context),
              ),
              MetricCard(
                label: 'home.quick_access.routes'.tr,
                value: '${summary.totalRoutes}',
                icon: Icons.directions_rounded,
                accent: Vibe.amber,
                onTap: () => _goToRoutes(context),
              ),
              MetricCard(
                label: 'home.quick_access.revenue'.tr,
                value: '142', 
                icon: Icons.monetization_on_rounded, // Swapped to match financial context
                accent: Vibe.amber,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 3. Wide Quick Action Button
          // Spans full width at the bottom to balance out the grid perfectly
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
                        color: Vibe.pink.withOpacity(0.1),
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
            child: const Text('Try again', style: TextStyle(color: Vibe.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}