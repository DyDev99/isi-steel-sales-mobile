import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/services/location_tracking_service.dart';

/// Real GPS tracking backed by `geolocator`. Background tracking uses
/// geolocator's own foreground-service mode on Android
/// (`AndroidSettings.foregroundNotificationConfig`) and background location
/// modes on iOS (`AppleSettings.allowBackgroundLocationUpdates`) — no
/// separate background-execution package needed.
class GeolocatorTrackingService implements LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  StreamController<LocationSample>? _controller;

  @override
  Future<bool> ensurePermission({bool background = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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
    _subscription ??= Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (position) => _controller?.add(_toSample(routeId, position)),
      onError: (Object _) {},
    );
    return _controller!.stream;
  }

  LocationSettings _settings() {
    if (Platform.isAndroid) {
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
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
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
