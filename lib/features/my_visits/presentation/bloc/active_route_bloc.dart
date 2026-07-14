import 'dart:async';
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_in_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_out_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/fraud_policy.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/fraud_detection_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/check_in.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/check_out.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/clear_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/record_fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/routes_params.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/save_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_route_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_stop_status.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';

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
    required SaveActiveWorkflow saveActiveWorkflow,
    required ClearActiveWorkflow clearActiveWorkflow,
    required GetActiveWorkflow getActiveWorkflow,
  })  : _getRoute = getRoute,
        _updateRouteStatus = updateRouteStatus,
        _updateStopStatus = updateStopStatus,
        _checkIn = checkIn,
        _checkOut = checkOut,
        _recordFraudFlag = recordFraudFlag,
        _fraudDetectionService = fraudDetectionService,
        _saveActiveWorkflow = saveActiveWorkflow,
        _clearActiveWorkflow = clearActiveWorkflow,
        _getActiveWorkflow = getActiveWorkflow,
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
  final SaveActiveWorkflow _saveActiveWorkflow;
  final ClearActiveWorkflow _clearActiveWorkflow;
  final GetActiveWorkflow _getActiveWorkflow;

  /// Fire-and-forget resume-pointer upsert — advisory (stop status in the
  /// DB is the real source of truth on resume), so a slow/failed write here
  /// never blocks the UI.
  ///
  /// When the current stop is checked in, the pointer is enriched into a
  /// *workflow-aware* row: Shop/Depot + check-in time + a baseline
  /// [VisitWorkflow.stockCount] (the guided step that immediately follows
  /// check-in) + the [navigationArguments] the resume dispatcher needs to
  /// rebuild the exact screen. Business-task transitions (Quotation/Sales Order)
  /// layer onto this via [UpdateWorkflowStep]. When the stop is not checked in
  /// (before check-in or after check-out), the workflow fields are cleared so
  /// resume falls back to the guided route flow.
  void _persistWorkflow(ActiveRouteReady state) {
    if (!state.dayStarted) return;
    unawaited(_writeWorkflowPointer(state));
  }

  Future<void> _writeWorkflowPointer(ActiveRouteReady state) async {
    final stop = state.hasCurrentStop
        ? state.route.stops[state.currentStopIndex]
        : null;
    final isActive = stop != null && stop.status == VisitStatus.checkedIn;
    final now = DateTime.now();

    // Baseline for a live visit: the guided Stock Count step.
    var workflow = isActive ? VisitWorkflow.stockCount : null;
    String? screen;
    Map<String, dynamic>? args = isActive
        ? {
            'stopId': stop.id,
            'customerId': stop.customer.id,
            'territory': stop.customer.territory,
          }
        : null;

    // Never *downgrade* a business task the rep already advanced into
    // (Quotation/Sales Order) back to Stock Count when a later route event
    // re-persists for the same stop — that would strand "Continue Working" on
    // the wrong screen. Deferred check-out means the stop stays checked in
    // through those tasks, so this guard keeps the resume pointer stable.
    if (isActive) {
      final existingResult = await _getActiveWorkflow(const NoParams());
      final existing =
          existingResult.when(success: (w) => w, failure: (_) => null);
      if (existing != null &&
          existing.currentStopId == stop.id &&
          (existing.currentWorkflow?.isBusinessTask ?? false)) {
        workflow = existing.currentWorkflow;
        screen = existing.currentScreen;
        args = existing.navigationArguments ?? args;
      }
    }

    await _saveActiveWorkflow(ActiveWorkflow(
      routeId: state.route.id,
      currentStopId: stop?.id,
      dayStarted: state.dayStarted,
      updatedAt: now,
      customerId: isActive ? stop.customer.id : null,
      shopName: isActive ? stop.customer.name : null,
      checkInAt: isActive ? stop.actualArrival : null,
      currentWorkflow: workflow,
      currentScreen: screen,
      navigationArguments: args,
      workflowUpdatedAt: isActive ? now : null,
    ));
  }

  Future<void> _onLoad(
      ActiveRouteLoadRequested event, Emitter<ActiveRouteState> emit) async {
    emit(const ActiveRouteLoading());
    final result = await _getRoute(RouteIdParams(event.routeId));
    result.when(
      success: (route) => emit(ActiveRouteReady(
          route: route, dayStarted: false, currentStopIndex: -1)),
      failure: (f) => emit(ActiveRouteError(f.message)),
    );
  }

  Future<void> _onStartDay(
      StartDayRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady) return;
    await _updateRouteStatus(
        UpdateRouteStatusParams(current.route.id, RouteStatus.inProgress));

    // Re-read state instead of reusing the pre-await snapshot: StopSelected
    // and/or GeofenceStatusChanged (both processed concurrently, since
    // neither uses `droppable()`) can land while this update is in flight.
    // Emitting off the stale `current` would silently stomp on those
    // updates — e.g. reset a correctly-detected `insideGeofence: true` back
    // to false, leaving "I've Arrived" locked even while standing in the
    // geofence.
    final latest = state;
    if (latest is! ActiveRouteReady) return;
    final next = latest.copyWith(
      route: latest.route.copyWith(status: RouteStatus.inProgress),
      dayStarted: true,
      // Only default to the first stop if nothing has already selected one.
      currentStopIndex: latest.currentStopIndex >= 0
          ? latest.currentStopIndex
          : (latest.route.stops.isEmpty ? -1 : 0),
    );
    emit(next);
    _persistWorkflow(next);
  }

  void _onStopSelected(StopSelected event, Emitter<ActiveRouteState> emit) {
    final current = state;
    if (current is! ActiveRouteReady) return;
    final next = current.copyWith(
      currentStopIndex: event.index,
      insideGeofence: true,
      blockedCheckInReason: () => null,
      checkInWarnings: const [],
    );
    emit(next);
    _persistWorkflow(next);
  }

  void _onGeofenceChanged(
      GeofenceStatusChanged event, Emitter<ActiveRouteState> emit) {
    final current = state;
    if (current is! ActiveRouteReady ||
        !current.dayStarted ||
        !current.hasCurrentStop) {
      return;
    }
    emit(current.copyWith(
      insideGeofence: true,
      distanceMeters: event.distanceMeters,
      accuracyMeters: event.accuracyMeters,
      isMocked: event.isMocked,
    ));
  }

  Future<void> _onCheckIn(
      CheckInRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady || !current.hasCurrentStop) return;
    final stop = current.route.stops[current.currentStopIndex];
    // Idempotency guard: a double-tap or a resume-triggered re-entry into
    // RouteCheckInScreen must not create a second `checkins` row for the
    // same stop (mirrors the existing guard in `_onCheckOut`).
    if (stop.status == VisitStatus.checkedIn ||
        stop.status == VisitStatus.checkedOut) {
      return;
    }

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
        type: current.isMocked
            ? FraudFlagType.mockLocation
            : FraudFlagType.vpnDetected,
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
    await _updateStopStatus(UpdateStopStatusParams(
        stopId: stop.id, status: VisitStatus.checkedIn, actualArrival: now));

    final next = current.copyWith(
      route: current.route.copyWith(
          stops: _replaceStop(
              current.route.stops,
              stop.id,
              (s) => s.copyWith(
                  status: VisitStatus.checkedIn, actualArrival: now))),
      blockedCheckInReason: () => null,
      checkInWarnings: validation.warnings,
    );
    emit(next);
    _persistWorkflow(next);
  }

  Future<void> _onCheckOut(
      CheckOutRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady || !current.hasCurrentStop) return;
    final stop = current.route.stops[current.currentStopIndex];
    if (stop.status != VisitStatus.checkedIn) return;

    final now = DateTime.now();
    final duration = stop.actualArrival == null
        ? 0
        : now.difference(stop.actualArrival!).inMinutes;
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
      UpdateStopStatusParams(
          stopId: stop.id,
          status: VisitStatus.checkedOut,
          actualDeparture: now),
    );

    final next = current.copyWith(
      route: current.route.copyWith(
          stops: _replaceStop(
              current.route.stops,
              stop.id,
              (s) => s.copyWith(
                  status: VisitStatus.checkedOut, actualDeparture: now))),
    );
    emit(next);
    _persistWorkflow(next);
  }

  Future<void> _onNextStop(
      NextStopRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady || !current.hasCurrentStop) return;
    final stop = current.route.stops[current.currentStopIndex];

    var stops = current.route.stops;
    if (stop.status != VisitStatus.checkedOut) {
      await _updateStopStatus(
          UpdateStopStatusParams(stopId: stop.id, status: VisitStatus.missed));
      stops = _replaceStop(
          stops, stop.id, (s) => s.copyWith(status: VisitStatus.missed));
    }

    final nextIndex = current.currentStopIndex + 1;
    final next = current.copyWith(
      route: current.route.copyWith(stops: stops),
      currentStopIndex:
          nextIndex < stops.length ? nextIndex : current.currentStopIndex,
      insideGeofence: false,
      blockedCheckInReason: () => null,
      checkInWarnings: const [],
    );
    emit(next);
    _persistWorkflow(next);
  }

  Future<void> _onEndDay(
      EndDayRequested event, Emitter<ActiveRouteState> emit) async {
    final current = state;
    if (current is! ActiveRouteReady) return;
    await _updateRouteStatus(
        UpdateRouteStatusParams(current.route.id, RouteStatus.completed));
    unawaited(_clearActiveWorkflow(const NoParams()));
    emit(ActiveRouteCompleted(
        current.route.copyWith(status: RouteStatus.completed)));
  }

  List<RouteStop> _replaceStop(List<RouteStop> stops, String stopId,
          RouteStop Function(RouteStop) update) =>
      [
        for (final s in stops)
          if (s.id == stopId) update(s) else s
      ];

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
}
