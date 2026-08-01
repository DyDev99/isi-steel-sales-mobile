import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/stop_information_screen.dart';

/// Opens StopInformationScreen safely with required BLoCs/Cubits injected.
Future<void> openStopInformation(
  BuildContext context, {
  required RouteStop stop,
  required int index,
  required int totalStops,
}) {
  // Resolve instances safely from context or Service Locator
  ActiveRouteBloc getActiveRouteBloc() {
    try {
      return context.read<ActiveRouteBloc>();
    } catch (_) {
      return sl<ActiveRouteBloc>();
    }
  }

  VisitCubit getVisitCubit() {
    try {
      return context.read<VisitCubit>();
    } catch (_) {
      return sl<VisitCubit>();
    }
  }

  LocationTrackingCubit getLocationTrackingCubit() {
    try {
      return context.read<LocationTrackingCubit>();
    } catch (_) {
      return sl<LocationTrackingCubit>();
    }
  }

  return Navigator.of(context).push(
    MaterialPageRoute(
      settings: const RouteSettings(name: StopInformationScreen.routeName),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getActiveRouteBloc()),
          BlocProvider.value(value: getVisitCubit()),
          BlocProvider.value(value: getLocationTrackingCubit()),
        ],
        child: StopInformationScreen(
          stop: stop,
          index: index,
          totalStops: totalStops,
        ),
      ),
    ),
  );
}
