import 'dart:async';
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/check_in_record.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/check_out_record.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/fraud_policy.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/services/fraud_detection_service.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/check_in.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/check_out.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/get_route.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/record_fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/routes_params.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/update_route_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/update_stop_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_state.dart';

const _policy = FraudPolicy();

/// The full-workday state machine: Start Day -> Navigate -> Arrive ->
/// Geofence Validation -> Check In -> Visit -> Check Out -> Next Stop ->
/// End Day. Mirrors `PipelineBloc`'s optimistic-update / single-current-
/// state shape from `lib/features/lead`.
class ActiveRouteBloc extends Bloc<ActiveRouteEvent, ActiveRouteState> {
  ActiveRouteBloc({
    required GetRoute getRoute,
    required UpdateRouteStatus updateRouteStatus,
    required UpdateStopStatus updateStopStatus,
    required CheckIn checkIn,
    required CheckOut checkOut,
    required RecordFraudFlag recordFraudFlag,
    required FraudDetectionService fraudDetectionService,
  })  : _getRoute = getRoute,
        _updateRouteStatus = updateRouteStatus,
        _updateStopStatus = updateStopStatus,
        _checkIn = checkIn,
        _checkOut = checkOut,
        _recordFraudFlag = recordFraudFlag,
        _fraudDetectionService = fraudDetectionService,
        super(const ActiveRouteLoading()) {
    on<ActiveRouteLoadRequested>(_onLoad);
    on<StartDayRequested>(_onStartDay, transformer: droppable());
    on<StopSelected>(_onStopSelected);
    on<GeofenceStatusChanged>(_onGeofenceChanged);
    on<CheckInRequested>(_onCheckIn, transformer: droppable());
    on<CheckOutRequested>(_onCheckOut, transformer: droppable());
    on<NextStopRequested>(_onNextStop, transformer: droppable());
    on<EndDayRequested>(_onEndDay, transformer: droppable());
  }

  final GetRoute _getRoute;
  final UpdateRouteStatus _updateRouteStatus;
  final UpdateStopStatus _updateStopStatus;
  final CheckIn _checkIn;
  final CheckOut _checkOut;
  final RecordFraudFlag _recordFraudFlag;
  final FraudDetectionService _fraudDetectionService;

  Future<void> _onLoad(ActiveRouteLoadRequested event, Emitter<ActiveRouteState> emit) async {
    emit(const ActiveRouteLoading());
    final result = await _getRoute(RouteIdParams(event.routeId));
    result.when(
      success: (route) => emit(ActiveRouteReady(route: route, dayStarted: false, currentStopIndex: -1)),
      failure: (f) => emit(ActiveRouteError(f.message)),
    );
  }

  Future<void> _onStartDay(StartDayRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady) return;
    await _updateRouteStatus(UpdateRouteStatusParams(current.route.id, RouteStatus.inProgress));
    emit(current.copyWith(
      route: current.route.copyWith(status: RouteStatus.inProgress),
      dayStarted: true,
      currentStopIndex: current.route.stops.isEmpty ? -1 : 0,
    ));
  }

  void _onStopSelected(StopSelected event, Emitter<ActiveRouteState> emit) {
    final current = state;
    if (current is! ActiveRouteReady) return;
    emit(current.copyWith(
      currentStopIndex: event.index,
      insideGeofence: false,
      blockedCheckInReason: () => null,
      checkInWarnings: const [],
    ));
  }

  void _onGeofenceChanged(GeofenceStatusChanged event, Emitter<ActiveRouteState> emit) {
    final current = state;
    if (current is! ActiveRouteReady || !current.dayStarted || !current.hasCurrentStop) return;
    emit(current.copyWith(
      insideGeofence: event.insideGeofence,
      distanceMeters: event.distanceMeters,
      accuracyMeters: event.accuracyMeters,
      isMocked: event.isMocked,
    ));
  }

  Future<void> _onCheckIn(CheckInRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady || !current.hasCurrentStop) return;
    final stop = current.route.stops[current.currentStopIndex];

    final vpnDetected = await _fraudDetectionService.detectVpnHeuristic();
    final validation = _fraudDetectionService.validateCheckIn(
      insideGeofence: current.insideGeofence,
      accuracyMeters: current.accuracyMeters,
      isMocked: current.isMocked,
      vpnDetected: vpnDetected,
      policy: _policy,
    );

    for (final warning in validation.warnings) {
      unawaited(_recordFraudFlag(FraudFlag(
        id: _newId(),
        routeId: current.route.id,
        stopId: stop.id,
        type: current.isMocked ? FraudFlagType.mockLocation : FraudFlagType.vpnDetected,
        detail: warning,
        timestamp: DateTime.now(),
        blocked: false,
      )));
    }

    if (!validation.allowed) {
      emit(current.copyWith(
        blockedCheckInReason: () => validation.blockedReasons.join(' '),
        checkInWarnings: validation.warnings,
      ));
      return;
    }

    final now = DateTime.now();
    final record = CheckInRecord(
      id: _newId(),
      stopId: stop.id,
      timestamp: now,
      latitude: stop.customer.latitude,
      longitude: stop.customer.longitude,
      accuracyMeters: current.accuracyMeters,
      distanceFromCustomerMeters: current.distanceMeters,
      isMocked: current.isMocked,
    );
    await _checkIn(record);
    await _updateStopStatus(UpdateStopStatusParams(stopId: stop.id, status: VisitStatus.checkedIn, actualArrival: now));

    emit(current.copyWith(
      route: current.route.copyWith(stops: _replaceStop(current.route.stops, stop.id,
          (s) => s.copyWith(status: VisitStatus.checkedIn, actualArrival: now))),
      blockedCheckInReason: () => null,
      checkInWarnings: validation.warnings,
    ));
  }

  Future<void> _onCheckOut(CheckOutRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady || !current.hasCurrentStop) return;
    final stop = current.route.stops[current.currentStopIndex];
    if (stop.status != VisitStatus.checkedIn) return;

    final now = DateTime.now();
    final duration = stop.actualArrival == null ? 0 : now.difference(stop.actualArrival!).inMinutes;
    final record = CheckOutRecord(
      id: _newId(),
      stopId: stop.id,
      timestamp: now,
      latitude: stop.customer.latitude,
      longitude: stop.customer.longitude,
      durationMinutes: duration,
      visitSummary: event.visitSummary,
    );
    await _checkOut(record);
    await _updateStopStatus(
      UpdateStopStatusParams(stopId: stop.id, status: VisitStatus.checkedOut, actualDeparture: now),
    );

    emit(current.copyWith(
      route: current.route.copyWith(stops: _replaceStop(current.route.stops, stop.id,
          (s) => s.copyWith(status: VisitStatus.checkedOut, actualDeparture: now))),
    ));
  }

  Future<void> _onNextStop(NextStopRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady || !current.hasCurrentStop) return;
    final stop = current.route.stops[current.currentStopIndex];

    var stops = current.route.stops;
    if (stop.status != VisitStatus.checkedOut) {
      await _updateStopStatus(UpdateStopStatusParams(stopId: stop.id, status: VisitStatus.missed));
      stops = _replaceStop(stops, stop.id, (s) => s.copyWith(status: VisitStatus.missed));
    }

    final nextIndex = current.currentStopIndex + 1;
    emit(current.copyWith(
      route: current.route.copyWith(stops: stops),
      currentStopIndex: nextIndex < stops.length ? nextIndex : current.currentStopIndex,
      insideGeofence: false,
      blockedCheckInReason: () => null,
      checkInWarnings: const [],
    ));
  }

  Future<void> _onEndDay(EndDayRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady) return;
    await _updateRouteStatus(UpdateRouteStatusParams(current.route.id, RouteStatus.completed));
    emit(ActiveRouteCompleted(current.route.copyWith(status: RouteStatus.completed)));
  }

  List<RouteStop> _replaceStop(List<RouteStop> stops, String stopId, RouteStop Function(RouteStop) update) =>
      [for (final s in stops) if (s.id == stopId) update(s) else s];

  static String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
}
