import 'dart:math';

import 'package:isi_steel_sales_mobile/features/routes/domain/entities/customer_stop_info.dart';

class GeofenceCheckResult {
  const GeofenceCheckResult({required this.insideGeofence, required this.distanceMeters, required this.radiusMeters});
  final bool insideGeofence;
  final double distanceMeters;
  final double radiusMeters;
}

/// Pure, no I/O, unit-testable — mirrors `lead`'s `pipeline_rules.dart` shape
/// (a small top-level-function file, not a DI-registered service) since
/// there's nothing here to swap or mock.
class GeofenceService {
  const GeofenceService._();

  static const _earthRadiusMeters = 6371000.0;

  /// Haversine great-circle distance between two lat/lng points, in meters.
  static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  static GeofenceCheckResult evaluate({
    required double repLatitude,
    required double repLongitude,
    required CustomerStopInfo customer,
  }) {
    final distance = distanceMeters(repLatitude, repLongitude, customer.latitude, customer.longitude);
    final radius = customer.geofenceRadiusMeters;
    return GeofenceCheckResult(insideGeofence: distance <= radius, distanceMeters: distance, radiusMeters: radius);
  }
}
