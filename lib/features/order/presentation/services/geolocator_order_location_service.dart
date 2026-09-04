import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/order_location_service.dart';

/// One-shot GPS capture for off-visit order entry, backed by `geolocator`
/// (already a dependency via `my_visits`). Foreground-only — no background
/// permission escalation needed for a single snapshot.
class GeolocatorOrderLocationService implements OrderLocationService {
  const GeolocatorOrderLocationService();

  @override
  Future<({double lat, double lng})?> captureOnce() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      debugPrint('[CustomerRegistration][GPS] Location services are disabled');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    debugPrint('[CustomerRegistration][GPS] Permission before request: '
        '${permission.name}');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('[CustomerRegistration][GPS] Permission after request: '
          '${permission.name}');
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[CustomerRegistration][GPS] Location permission unavailable');
      return null;
    }

    try {
      final position = await _getPosition(LocationAccuracy.high);
      debugPrint('[CustomerRegistration][GPS] High-accuracy fix: '
          'lat=${position.latitude}, lng=${position.longitude}, '
          'accuracy=${position.accuracy}m');
      return (lat: position.latitude, lng: position.longitude);
    } catch (error) {
      // A high-accuracy (GPS) fix can take too long indoors. A network-backed
      // medium-accuracy position is still sufficient for the form's Cambodia
      // bounds validation, and prevents the button from failing silently.
      debugPrint('[CustomerRegistration][GPS] High-accuracy capture failed: '
          '$error. Retrying with medium accuracy.');
      try {
        final position = await _getPosition(LocationAccuracy.medium);
        debugPrint('[CustomerRegistration][GPS] Medium-accuracy fix: '
            'lat=${position.latitude}, lng=${position.longitude}, '
            'accuracy=${position.accuracy}m');
        return (lat: position.latitude, lng: position.longitude);
      } catch (fallbackError) {
        debugPrint('[CustomerRegistration][GPS] No position captured: '
            '$fallbackError');
        return null;
      }
    }
  }

  Future<Position> _getPosition(LocationAccuracy accuracy) =>
      Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 20),
      );
}
