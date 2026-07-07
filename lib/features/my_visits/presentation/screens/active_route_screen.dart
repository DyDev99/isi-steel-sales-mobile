import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_map.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stop_card.dart';

/// A route's live workday view: map (top) + stop list (bottom) + the
/// Start Day / End Day controls. Pushed from `RouteDashboardScreen` with
/// `ActiveRouteBloc`/`LocationTrackingCubit`/`VisitCubit` already provided.
class ActiveRouteScreen extends StatefulWidget {
  const ActiveRouteScreen({super.key});

  @override
  State<ActiveRouteScreen> createState() => _ActiveRouteScreenState();
}

class _ActiveRouteScreenState extends State<ActiveRouteScreen> {
  Future<void> _startDay(BuildContext context) async {
    final bloc = context.read<ActiveRouteBloc>();
    final state = bloc.state;
    if (state is! ActiveRouteReady) return;
    final started = await context.read<LocationTrackingCubit>().start(state.route.id, background: true);
    if (!context.mounted) return;
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to start your route.')),
      );
      return;
    }
    bloc.add(const StartDayRequested());
  }

  Future<void> _endDay(BuildContext context) async {
    await context.read<LocationTrackingCubit>().stop();
    if (context.mounted) context.read<ActiveRouteBloc>().add(const EndDayRequested());
  }

  void _openStop(BuildContext context, int index) {
    context.read<ActiveRouteBloc>().add(StopSelected(index));
    final activeRouteBloc = context.read<ActiveRouteBloc>();
    final visitCubit = context.read<VisitCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: activeRouteBloc),
          BlocProvider.value(value: visitCubit),
        ],
        child: const StopDetailScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationTrackingCubit, LocationTrackingState>(
      listener: (context, locationState) {
        final position = locationState.current;
        final activeState = context.read<ActiveRouteBloc>().state;
        if (position == null || activeState is! ActiveRouteReady) return;
        final geofence = evaluateStopGeofence(
          stops: activeState.route.stops,
          currentStopIndex: activeState.currentStopIndex,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (geofence == null) return;
        context.read<ActiveRouteBloc>().add(GeofenceStatusChanged(
              insideGeofence: geofence.insideGeofence,
              distanceMeters: geofence.distanceMeters,
              accuracyMeters: position.accuracyMeters,
              isMocked: position.isMocked,
              latitude: position.latitude,
              longitude: position.longitude,
            ));
      },
      child: Scaffold(
        backgroundColor: Vibe.bg,
        appBar: AppBar(
          backgroundColor: Vibe.bg,
          iconTheme: const IconThemeData(color: Vibe.text),
          title: const Text('Active Route', style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        body: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
          builder: (context, state) => switch (state) {
            ActiveRouteReady() => _ReadyBody(
                state: state,
                onStartDay: () => _startDay(context),
                onEndDay: () => _endDay(context),
                onOpenStop: (i) => _openStop(context, i),
              ),
            ActiveRouteCompleted(:final route) => _CompletedBody(route: route.stops),
            ActiveRouteError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
            _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
          },
        ),
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state, required this.onStartDay, required this.onEndDay, required this.onOpenStop});
  final ActiveRouteReady state;
  final VoidCallback onStartDay;
  final VoidCallback onEndDay;
  final ValueChanged<int> onOpenStop;

  bool get _allDone => state.route.stops.isNotEmpty &&
      state.route.stops.every((s) => s.status == VisitStatus.checkedOut || s.status == VisitStatus.missed);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
            builder: (context, locationState) => RouteMap(
              stops: state.route.stops,
              currentStopIndex: state.currentStopIndex,
              currentPosition: locationState.current,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !state.dayStarted ? onStartDay : (_allDone ? onEndDay : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: !state.dayStarted || _allDone ? Vibe.violet : Vibe.stroke,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(!state.dayStarted ? 'Start Day' : (_allDone ? 'End Day' : 'Route in progress…')),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              for (var i = 0; i < state.route.stops.length; i++)
                StopCard(
                  stop: state.route.stops[i],
                  selected: i == state.currentStopIndex,
                  onTap: () => onOpenStop(i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletedBody extends StatelessWidget {
  const _CompletedBody({required this.route});
  final List<RouteStop> route;

  @override
  Widget build(BuildContext context) {
    final completed = route.where((s) => s.status == VisitStatus.checkedOut).length;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration_rounded, color: Vibe.success, size: 48),
          const SizedBox(height: 12),
          Text('Route complete — $completed/${route.length} stops visited',
              style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to routes', style: TextStyle(color: Vibe.violet)),
          ),
        ],
      ),
    );
  }
}
