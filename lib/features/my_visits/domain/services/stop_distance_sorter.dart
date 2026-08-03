import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/ranked_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';

/// Pure domain rule for ordering a rep's stops (keeps sort/distance logic OUT of
/// the UI — the presentation cubit only orchestrates streams and calls this).
///
/// - **Location available** → stamps each stop with the Haversine distance from
///   `(latitude, longitude)` and returns nearest-first (the optimized visit
///   sequence).
/// - **Location unavailable** (null) → returns the **planned order** (by
///   `sequence`) with distances left null, so the dashboard still works with no
///   GPS. See `docs/OFFLINE_FIRST.md` — the visit flow never depends on GPS.
class StopDistanceSorter {
  const StopDistanceSorter();

  List<RankedStop> sort(
    List<RouteStop> stops, {
    double? latitude,
    double? longitude,
  }) {
    if (latitude == null || longitude == null) {
      final planned = [...stops]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      return [for (final s in planned) RankedStop(stop: s)];
    }

    final ranked = [
      for (final s in stops)
        RankedStop(
          stop: s,
          distanceMeters: GeofenceService.distanceMeters(
              latitude, longitude, s.customer.latitude, s.customer.longitude),
        ),
    ];
    ranked.sort((a, b) => (a.distanceMeters ?? double.infinity)
        .compareTo(b.distanceMeters ?? double.infinity));
    return ranked;
  }
}
