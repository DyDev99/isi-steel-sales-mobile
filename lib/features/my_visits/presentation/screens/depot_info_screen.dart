import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/l10n/visit_labels.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_route_dispatch.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/resume_route_screen.dart';

/// Immutable context describing why/when a route is being resumed, collected by
/// [ResumeRouteScreen] and surfaced here as a banner so the rep sees it before
/// re-entering the guided flow.
class ResumeContext {
  const ResumeContext({required this.reason, required this.date});
  final String reason;
  final DateTime date;
}

/// Depot briefing shown the moment a rep selects a route — the interstitial
/// between the dashboard and the guided check-in flow. It never checks anyone
/// in itself: "Start Route" hands off to [openRouteDispatch] (Dispatch →
/// Transit → Check-in → Stock Count), exactly the existing chain.
///
/// [routes] is the set the resume picker can choose from (the day's routes);
/// it falls back to just [route] when empty.
class DepotInfoScreen extends StatelessWidget {
  const DepotInfoScreen({
    super.key,
    required this.route,
    this.routes = const [],
    this.syncCubit,
    this.resume,
  });

  static const routeName = 'depot-info';

  final RoutePlan route;
  final List<RoutePlan> routes;
  final RouteSyncCubit? syncCubit;
  final ResumeContext? resume;

  void _startRoute(BuildContext context) {
    openRouteDispatch(context, route.id, syncCubit: syncCubit);
  }

  void _openResume(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: ResumeRouteScreen.routeName),
      builder: (_) => ResumeRouteScreen(
        routes: routes.isEmpty ? [route] : routes,
        initialRoute: route,
        syncCubit: syncCubit,
      ),
    ));
  }

  String _statusLabel() => switch (route.status) {
        RouteStatus.planned => 'my_visits.depot_info.status_planned'.tr,
        RouteStatus.published => 'my_visits.depot_info.status_published'.tr,
        RouteStatus.inProgress => 'my_visits.depot_info.status_inprogress'.tr,
        RouteStatus.completed => 'my_visits.depot_info.status_completed'.tr,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('EEE, MMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'my_visits.depot_info.title'.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (resume != null) ...[
              _ResumingBanner(
                text: 'my_visits.depot_info.resuming'.trParams({
                  'reason': resume!.reason,
                  'date': DateFormat('MMM d').format(resume!.date),
                }),
              ),
              const SizedBox(height: 12),
            ],

            // Header card: depot / route identity + progress.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.warehouse_rounded,
                            color: scheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'my_visits.depot_info.briefing'.tr.toUpperCase(),
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              route.name,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(label: _statusLabel()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProgressBar(
                    progress: route.progress,
                    label: 'my_visits.depot_info.progress_value'.trParams({
                      'done': route.completedStops.toString(),
                      'total': route.totalStops.toString(),
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Info grid.
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.map_rounded,
                    label: 'my_visits.depot_info.territory'.tr,
                    value: route.territory,
                  ),
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'my_visits.depot_info.rep'.tr,
                    value: route.repName,
                  ),
                  _InfoRow(
                    icon: Icons.event_rounded,
                    label: 'my_visits.depot_info.date'.tr,
                    value: dateFmt.format(route.visitDate),
                  ),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'my_visits.depot_info.window'.tr,
                    value:
                        '${timeFmt.format(route.plannedStart)} – ${timeFmt.format(route.plannedEnd)}',
                  ),
                  _InfoRow(
                    icon: Icons.store_mall_directory_rounded,
                    label: 'my_visits.depot_info.stops'.tr,
                    value: route.totalStops.toString(),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Planned stops list.
            Text(
              'my_visits.depot_info.planned_stops'.tr.toUpperCase(),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            if (route.stops.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'my_visits.depot_info.no_stops'.tr,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...route.stops.map((stop) => _StopTile(stop: stop)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(
        onStart: () => _startRoute(context),
        onResume: () => _openResume(context),
      ),
    );
  }
}

class _ResumingBanner extends StatelessWidget {
  const _ResumingBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: colors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.label});
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colors.surfaceStrong,
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: colors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop});
  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceStrong,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              localizedOrdinal(stop.sequence),
              style: TextStyle(
                color: scheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (stop.customer.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    stop.customer.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            stop.status.localizedLabel,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onStart, required this.onResume});
  final VoidCallback onStart;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.history_rounded, size: 18),
                label: Text(
                  'my_visits.depot_info.resume_route'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  'my_visits.depot_info.start_route'.tr,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
