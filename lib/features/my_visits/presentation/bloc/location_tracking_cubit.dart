import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/fraud_policy.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/fraud_detection_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/location_tracking_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/record_fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/record_location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/location_tracking_state.dart';

const _trailCap = 500;

/// Starts/stops the real GPS stream for the active route, persists every
/// sample durably, and screens each one for impossible-travel-speed fraud
/// (mock-location/accuracy are checked at check-in time instead, in
/// `FraudDetectionService.validateCheckIn`).
class LocationTrackingCubit extends Cubit<LocationTrackingState> {
  LocationTrackingCubit({
    required LocationTrackingService trackingService,
    required RecordLocationSample recordLocationSample,
    required RecordFraudFlag recordFraudFlag,
    required FraudDetectionService fraudDetectionService,
  })  : _trackingService = trackingService,
        _recordLocationSample = recordLocationSample,
        _recordFraudFlag = recordFraudFlag,
        _fraudDetectionService = fraudDetectionService,
        super(const LocationTrackingState());

  final LocationTrackingService _trackingService;
  final RecordLocationSample _recordLocationSample;
  final RecordFraudFlag _recordFraudFlag;
  final FraudDetectionService _fraudDetectionService;

  StreamSubscription<LocationSample>? _subscription;
  static const _policy = FraudPolicy();

  Future<bool> start(String routeId, {bool background = false}) async {
    final granted =
        await _trackingService.ensurePermission(background: background);
    if (!granted) {
      emit(state.copyWith(permissionDenied: true));
      return false;
    }

    emit(state.copyWith(isTracking: true, permissionDenied: false));
    _subscription?.cancel();
    _subscription = _trackingService
        .track(routeId)
        .listen((sample) => _onSample(routeId, sample));
    return true;
  }

  Future<void> _onSample(String routeId, LocationSample sample) async {
    final trail = [...state.trail, sample];
    emit(state.copyWith(
        current: sample,
        trail: trail.length > _trailCap
            ? trail.sublist(trail.length - _trailCap)
            : trail));

    unawaited(_recordLocationSample(sample));

    final previous =
        state.trail.length >= 2 ? state.trail[state.trail.length - 2] : null;
    if (previous != null &&
        _fraudDetectionService.isImpossibleTravel(previous, sample, _policy)) {
      unawaited(_recordFraudFlag(FraudFlag(
        id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}',
        routeId: routeId,
        type: FraudFlagType.impossibleSpeed,
        detail:
            'Implausible travel speed detected between consecutive GPS samples.',
        timestamp: sample.timestamp,
        blocked: false,
      )));
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _trackingService.stop();
    emit(state.copyWith(isTracking: false));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _trackingService.stop();
    return super.close();
  }
}
