import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/location_tracking_service.dart';

/// Real GPS tracking backed by `geolocator`. Background tracking uses
/// geolocator's own foreground-service mode on Android
/// (`AndroidSettings.foregroundNotificationConfig`) and background location
/// modes on iOS (`AppleSettings.allowBackgroundLocationUpdates`) — no
/// separate background-execution package needed.
class GeolocatorTrackingService implements LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  StreamController<LocationSample>? _controller;

  // Separate lifecycle from the route-scoped [track] stream above so the
  // dashboard's foreground-only observation never starts/stops the foreground
  // service.
  StreamSubscription<Position>? _observeSubscription;
  StreamController<LocationSample>? _observeController;

  @override
  Future<bool> ensurePermission({bool background = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Staged request: only ask for "always" (background) right before it's
    // actually needed, matching platform-expected UX.
    if (background && permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
    }
    return true;
  }

  @override
  Stream<LocationSample> track(String routeId) {
    _controller ??= StreamController<LocationSample>.broadcast(onCancel: stop);
    _subscription ??=
        Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (position) => _controller?.add(_toSample(routeId, position)),
      onError: (Object _) {},
    );
    return _controller!.stream;
  }

  /// Platform-tuned settings.
  ///
  /// Uses [defaultTargetPlatform] rather than `dart:io`'s `Platform.isAndroid`
  /// because `dart:io` does not exist on web. The check is equivalent on mobile
  /// and, on web, simply falls through to the plain [LocationSettings] default
  /// below — which is correct: the Android/iOS branches configure *background*
  /// tracking (foreground notifications, background location indicators), and a
  /// browser cannot track location in the background at all. Web tracking is
  /// foreground-only for as long as the tab is open.
  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'ISI Steel Sales',
          notificationText: 'Tracking your route',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
        accuracy: LocationAccuracy.high, distanceFilter: 10);
  }

  @override
  Stream<LocationSample> observe({int distanceFilterMeters = 25}) {
    _observeController ??=
        StreamController<LocationSample>.broadcast(onCancel: stopObserving);
    _observeSubscription ??= Geolocator.getPositionStream(
      // Plain settings: no foreground-service notification (that belongs to the
      // route-scoped [track]); larger distance filter to conserve battery.
      locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilterMeters),
    ).listen(
      (position) =>
          _observeController?.add(_toSample('stop-dashboard', position)),
      onError: (Object _) {},
    );
    return _observeController!.stream;
  }

  @override
  Future<void> stopObserving() async {
    await _observeSubscription?.cancel();
    _observeSubscription = null;
    await _observeController?.close();
    _observeController = null;
  }

  LocationSample _toSample(String routeId, Position position) => LocationSample(
        id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}',
        routeId: routeId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        speedMps: position.speed,
        headingDegrees: position.heading,
        altitudeMeters: position.altitude,
        timestamp: position.timestamp,
        isMocked: position.isMocked,
      );

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
  }
}
