import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/home/domain/dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_state.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/add_customer_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/metric_card.dart';

/// Home dashboard tab. Thin: renders HomeCubit state, composes small widgets.
///
/// Every quick-access tile below that maps to an existing `MainShell` tab
/// (Leads, Orders, Routes) switches to that tab via `ShellTabController`
/// instead of pushing a new screen — this keeps a single source of truth
/// for each feature's state (filters, scroll position, loaded data)
/// instead of spinning up a second, independent Bloc/Cubit instance every
/// time you tap in from Home. Customers has no dedicated tab screen yet,
/// so it still opens the Add Customer sheet directly.
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

  void _goToCustomers(BuildContext context)=> sl<ShellTabController>().goTo(ShellTab.customers);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Vibe.pink,
      backgroundColor: Vibe.bgSoft,
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 28.h),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14.w,
            mainAxisSpacing: 14.h,
            childAspectRatio: 1.35,
            children: [
              MetricCard(
                  label: 'home.quick_access.leads'.tr,
                  value: '${summary.newLeads}',
                  icon: Icons.person_add_alt_1_rounded,
                  accent: Vibe.violet,
                  onTap: () => _goToLeads(context)),
              MetricCard(
                  label: 'home.quick_access.orders'.tr,
                  value: '${summary.openOrders}',
                  icon: Icons.receipt_long_rounded,
                  accent: Vibe.mint,
                  onTap: () => _goToOrders(context)),
              MetricCard(
                  label: 'home.quick_access.customers'.tr,
                  value: '${summary.totalCustomers}',
                  icon: Icons.people_alt_rounded,
                  accent: Vibe.success,
                  onTap: () => _goToCustomers(context)),
              MetricCard(
                  label: 'home.quick_access.routes'.tr,
                  value: '${summary.totalRoutes}',
                  icon: Icons.directions_rounded,
                  accent: Vibe.amber,
                  onTap: () => _goToRoutes(context)),
              // Revenue placeholder — left untouched per request.
              MetricCard(
                  label: 'home.quick_access.revenue'.tr,
                  value: '142', // Replace with dynamic data
                  icon: Icons.person_add_rounded,
                  accent: Vibe.amber),

              // Clean Action Button Card with Icon & Subtitle Layout
              GestureDetector(
                onTap: () => showAddCustomerSheet(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Vibe.bgSoft,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Vibe.stroke, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Vibe.pink.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            color: Vibe.pink,
                            size: 26.w,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'home.quick_access.add_customer'.tr,
                          style: TextStyle(
                            color: Vibe.text,
                            fontSize: 13.sp,
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