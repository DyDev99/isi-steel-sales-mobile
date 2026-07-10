import 'package:geolocator/geolocator.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/order_location_service.dart';

/// One-shot GPS capture for off-visit order entry, backed by `geolocator`
/// (already a dependency via `my_visits`). Foreground-only — no background
/// permission escalation needed for a single snapshot.
class GeolocatorOrderLocationService implements OrderLocationService {
  const GeolocatorOrderLocationService();

  @override
  Future<({double lat, double lng})?> captureOnce() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }
}
