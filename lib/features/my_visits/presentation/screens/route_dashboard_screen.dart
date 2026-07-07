import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/seed_isi_tower_test_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/my_visits_history_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_dispatch_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/dashboard_summary_cards.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_skeletons.dart';

/// Entry screen for Route Management, pushed from `HomeScreen`'s "Start
/// Route" CTA. Lists today's routes (already scoped to the rep's territory
/// by the sync engine) with a dashboard summary on top.
class MyVisitsDashboardScreen extends StatefulWidget {
  const MyVisitsDashboardScreen({super.key});

  @override
  State<MyVisitsDashboardScreen> createState() => _MyVisitsDashboardScreenState();
}

class _MyVisitsDashboardScreenState extends State<MyVisitsDashboardScreen> {
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

  /// DEBUG ONLY — seeds a fixture route/stop at ISI Tower directly into the
  /// local DB (bypassing sync) so the transit/check-in geofence flow can be
  /// tested on-device. Safe to tap repeatedly: the underlying upserts use
  /// replace/ignore conflict handling, so it won't create duplicates.
  /// Remove this method and its call site before shipping.
  Future<void> _seedTestRoute(BuildContext context) async {
    await seedIsiTowerTestRoute(sl<RouteLocalDataSource>());
    if (!context.mounted) return;
    context.read<RouteDashboardCubit>().load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seeded test route: ISI Tower')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: 'seed-test-route',
              backgroundColor: Vibe.violet,
              tooltip: 'Seed ISI Tower test route',
              onPressed: () => _seedTestRoute(context),
              child: const Icon(Icons.bug_report_rounded, color: Colors.white),
            )
          : null,
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
                          _VisitHistoryEntryTile(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              settings: const RouteSettings(name: MyVisitsHistoryScreen.routeName),
                              builder: (_) => const MyVisitsHistoryScreen(),
                            )),
                          ),
                          SizedBox(height: 16.h),
                          Text('my_visits.flow.today'.tr,
                              style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
                          SizedBox(height: 10.h),
                        if (state.routes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                                child: Text('my_visits.flow.no_routes_today'.tr,
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

/// Entry point into the static-mock "My Visits" history flow — kept as a
/// simple tile here rather than replacing this screen's live dispatch list,
/// since the two are separate concerns (today's GPS-tracked routes vs. a
/// past-visits history view).
class _VisitHistoryEntryTile extends StatelessWidget {
  const _VisitHistoryEntryTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
                child: const Icon(Icons.history_rounded, color: Vibe.violet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('my_visits.history.view_history'.tr,
                        style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('my_visits.history.view_history_subtitle'.tr,
                        style: const TextStyle(color: Vibe.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Vibe.muted),
            ],
          ),
        ),
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