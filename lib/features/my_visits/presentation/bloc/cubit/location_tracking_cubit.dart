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
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';

const _trailCap = 500;

/// Starts/stops the real GPS stream, persists every sample durably, and screens
/// each one for impossible-travel-speed fraud (mock-location/accuracy are
/// checked at check-in time instead, in
/// `FraudDetectionService.validateCheckIn`).
///
/// Two modes, because a rep walking a route and a rep looking at one screen
/// need very different things from the battery:
///
/// * [start] — the route-scoped stream, behind a real foreground service so it
///   survives the screen going off. Every sample is stored; this is what the
///   GPS trail is made of.
/// * [observeForScreen] — foreground-only, no service and no notification, for
///   a screen that needs to know where the rep is *right now* — the check-in
///   verification and the nearest-first stop sort. Released on [stopObserving].
///
/// Both write [LocationTrackingState.current], which is what anything asking
/// "where is the rep" reads.
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
  StreamSubscription<LocationSample>? _observation;
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

  /// A light, screen-scoped position stream.
  ///
  /// Without this nothing ever called [start] either, so
  /// [LocationTrackingState.current] was **always null**: the check-in screen
  /// could not measure the rep against the outlet, `GeofenceStatusChanged` was
  /// never dispatched, and `insideGeofence` kept its optimistic default. The
  /// app looked like it verified location and never actually read the GPS.
  ///
  /// Samples from here are *not* persisted. They are a live reading for the UI,
  /// not the audit trail — that is [start]'s job, and writing a row every time
  /// a rep opens a screen would pad the trail with points that say nothing
  /// about where they travelled.
  ///
  /// Safe to call repeatedly: a second call replaces the first rather than
  /// stacking subscriptions. Returns false when permission was refused, with
  /// `permissionDenied` set so the UI can explain itself.
  Future<bool> observeForScreen({int distanceFilterMeters = 10}) async {
    final granted = await _trackingService.ensurePermission();
    if (!granted) {
      emit(state.copyWith(permissionDenied: true));
      return false;
    }
    emit(state.copyWith(permissionDenied: false));

    await _observation?.cancel();
    _observation = _trackingService
        .observe(distanceFilterMeters: distanceFilterMeters)
        .listen((sample) => emit(state.copyWith(current: sample)));
    return true;
  }

  /// Releases [observeForScreen]. Leaves a route-scoped [start] running — the
  /// two are independent, and a rep closing a screen has not ended their day.
  Future<void> stopObserving() async {
    await _observation?.cancel();
    _observation = null;
    await _trackingService.stopObserving();
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
    _observation?.cancel();
    _trackingService.stopObserving();
    _trackingService.stop();
    return super.close();
  }
}
