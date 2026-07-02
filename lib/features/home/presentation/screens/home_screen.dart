import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/home/domain/dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_state.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/activity_tile.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/metric_card.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/quick_actions.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/section_header.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/target_card.dart';

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
                _ => const Center(
                    child: CircularProgressIndicator(color: Vibe.pink)),
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Vibe.pink,
      backgroundColor: Vibe.bgSoft,
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        children: [
          HomeHeader(name: name),
          SizedBox(height: 22.h),
          QuickActions(actions: [
            QuickAction(Icons.person_add_alt_1_rounded, 'New lead', () {}),
            QuickAction(Icons.add_shopping_cart_rounded, 'New order', () {}),
            QuickAction(Icons.trending_up_rounded, 'Opportunity', () {}),
            QuickAction(Icons.qr_code_scanner_rounded, 'Scan', () {}),
          ]),
          SizedBox(height: 20.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14.w,
            mainAxisSpacing: 14.h,
            childAspectRatio: 1.35,
            children: [
              MetricCard(
                  label: 'New leads',
                  value: '${summary.newLeads}',
                  icon: Icons.person_add_alt_1_rounded,
                  accent: Vibe.violet),
              MetricCard(
                  label: 'Open orders',
                  value: '${summary.openOrders}',
                  icon: Icons.receipt_long_rounded,
                  accent: Vibe.mint),
              MetricCard(
                  label: 'Revenue MTD',
                  value: summary.revenueMtd,
                  icon: Icons.payments_rounded,
                  accent: Vibe.success),
              MetricCard(
                  label: 'Win rate',
                  value: '${(summary.winRate * 100).round()}%',
                  icon: Icons.emoji_events_rounded,
                  accent: Vibe.amber),
            ],
          ),
          SizedBox(height: 16.h),
          TargetCard(progress: summary.targetProgress),
          SizedBox(height: 22.h),
          const SectionHeader(title: 'Recent activity'),
          SizedBox(height: 4.h),
          ...summary.recent.map((a) => ActivityTile(item: a)),
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
            child: const Text('Try again',
                style: TextStyle(color: Vibe.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
