import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_dispatch_screen.dart';

/// Pushes [RouteDispatchScreen] for [routeId], wired with fresh
/// `ActiveRouteBloc`/`LocationTrackingCubit`/`VisitCubit` instances (the
/// single injection point where a real route id first flows into the
/// guided-visit chain). Shared by both the Dashboard's "open a route" tap
/// (`RouteDashboardScreen._openRoute`) and the app-launch resume flow
/// (`MainShell._checkForResumableRoute`), so there is one construction path
/// to keep in sync instead of two.
///
/// [syncCubit] is forwarded via `BlocProvider.value` when the caller already
/// has one in scope (the Dashboard does); otherwise a fresh instance is
/// constructed via DI, consistent with this feature's factory-everywhere
/// convention.
///
/// [resumeStopId] deep-links a "Continue Working" resume: when set, Dispatch
/// restores the checked-in stop and forwards straight into the Stock Count
/// screen (with Dispatch left beneath as the back target), so the rep lands on
/// the exact screen they stopped on rather than stop selection. It falls back
/// to the normal Dispatch list if the stop is missing/invalid or no longer
/// checked in — the single construction path stays shared for both entries.
Future<void> openRouteDispatch(BuildContext context, String routeId,
    {RouteSyncCubit? syncCubit, String? resumeStopId}) {
  return Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: RouteDispatchScreen.routeName),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: syncCubit ?? sl<RouteSyncCubit>()),
        BlocProvider(
            create: (_) =>
                sl<ActiveRouteBloc>()..add(ActiveRouteLoadRequested(routeId))),
        BlocProvider(create: (_) => sl<LocationTrackingCubit>()),
        BlocProvider(create: (_) => sl<VisitCubit>()),
      ],
      child: LocalizedBuilder(
          builder: (_) => RouteDispatchScreen(resumeStopId: resumeStopId)),
    ),
  ));
}
