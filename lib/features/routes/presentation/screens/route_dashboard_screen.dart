import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/screens/route_dispatch_screen.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/dashboard_summary_cards.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/route_skeletons.dart';

/// Entry screen for Route Management, pushed from `HomeScreen`'s "Start
/// Route" CTA. Lists today's routes (already scoped to the rep's territory
/// by the sync engine) with a dashboard summary on top.
class RouteDashboardScreen extends StatefulWidget {
  const RouteDashboardScreen({super.key});

  @override
  State<RouteDashboardScreen> createState() => _RouteDashboardScreenState();
}

class _RouteDashboardScreenState extends State<RouteDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RouteSyncCubit>().syncIfNeeded();
  }

  Future<void> _openRoute(BuildContext context, RoutePlan route) async {
    final syncCubit = context.read<RouteSyncCubit>();
    final dashboardCubit = context.read<RouteDashboardCubit>();
    await Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: RouteDispatchScreen.routeName),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: syncCubit),
          BlocProvider(create: (_) => sl<ActiveRouteBloc>()..add(ActiveRouteLoadRequested(route.id))),
          BlocProvider(create: (_) => sl<LocationTrackingCubit>()),
          BlocProvider(create: (_) => sl<VisitCubit>()),
        ],
        child: LocalizedBuilder(builder: (_) => const RouteDispatchScreen()),
      ),
    ));
    if (!mounted) return;
    dashboardCubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            // When the background sync finishes writing routes, re-attach the
            // dashboard stream so the new data appears immediately (the sync
            // writes to the DB directly, bypassing the repo's live broadcast).
            child: BlocListener<RouteSyncCubit, RouteSyncState>(
              listenWhen: (prev, curr) => curr is RouteSyncSucceeded,
              listener: (context, _) => context.read<RouteDashboardCubit>().load(),
              child: BlocBuilder<RouteDashboardCubit, RouteDashboardState>(
                builder: (context, state) => switch (state) {
                  RouteDashboardLoaded() => RefreshIndicator(
                      color: Vibe.violet,
                      backgroundColor: Vibe.bgSoft,
                      onRefresh: () async {
                        await context.read<RouteSyncCubit>().refresh();
                        if (context.mounted) await context.read<RouteDashboardCubit>().load();
                      },
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                        children: [
                          DashboardSummaryCards(summary: state.summary),
                          SizedBox(height: 16.h),
                          Text('routes.flow.today'.tr,
                              style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
                          SizedBox(height: 10.h),
                        if (state.routes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                                child: Text('routes.flow.no_routes_today'.tr,
                                    style: const TextStyle(color: Vibe.muted))),
                          )
                        else
                          for (final route in state.routes) _RouteTile(route: route, onTap: () => _openRoute(context, route)),
                      ],
                    ),
                  ),
                  RouteDashboardError(:final message) =>
                    Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
                  // ConnectionState.waiting equivalent → dimensionally-accurate
                  // skeletons instead of a blank spinner.
                  _ => const RouteDashboardSkeleton(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.route, required this.onTap});
  final RoutePlan route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Vibe.stroke)),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Vibe.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.route_rounded, color: Vibe.violet),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.name, style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('${route.totalStops} stops · ${route.completedStops} completed',
                          style: const TextStyle(color: Vibe.muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Vibe.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
