import 'package:isi_steel_sales_mobile/features/routes/domain/entities/location_sample.dart';

/// Abstracts the actual GPS hardware/permission/foreground-service
/// mechanics away from the rest of the feature — [GeolocatorTrackingService]
/// is the real implementation.
abstract interface class LocationTrackingService {
  /// Requests location permission, escalating to background ("always") if
  /// [background] is true — called right before "Start Day", matching the
  /// staged-permission-request pattern the platforms expect.
  Future<bool> ensurePermission({bool background = false});

  /// Starts (or returns the existing) continuous GPS stream for [routeId],
  /// backed by a real Android foreground service / iOS background mode so
  /// it keeps running with the screen off or the app backgrounded.
  Stream<LocationSample> track(String routeId);

  Future<void> stop();
}
