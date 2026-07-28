import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_information/route_information_screen.dart';

/// Pushes [RouteInformationScreen] for [routeId], wired with fresh
/// `ActiveRouteBloc`/`LocationTrackingCubit`/`VisitCubit` instances — the single
/// injection point where a real route id first flows into the guided-visit
/// chain in the new (Route Information → Check-In) flow.
///
/// Mirrors `openRouteDispatch` exactly (same bloc set, same `RouteSyncCubit`
/// forwarding, same `LocalizedBuilder` wrap) so both entry paths construct the
/// visit-chain the same way. The legacy `openRouteDispatch` is retained for the
/// "Continue Working" resume deep-link, which still lands on Dispatch/Stock.
Future<void> openRouteInformation(BuildContext context, String routeId,
    {RouteSyncCubit? syncCubit}) {
  return Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: RouteInformationScreen.routeName),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: syncCubit ?? sl<RouteSyncCubit>()),
        BlocProvider(
            create: (_) =>
                sl<ActiveRouteBloc>()..add(ActiveRouteLoadRequested(routeId))),
        BlocProvider(create: (_) => sl<LocationTrackingCubit>()),
        BlocProvider(create: (_) => sl<VisitCubit>()),
      ],
      child: LocalizedBuilder(builder: (_) => const RouteInformationScreen()),
    ),
  ));
}
