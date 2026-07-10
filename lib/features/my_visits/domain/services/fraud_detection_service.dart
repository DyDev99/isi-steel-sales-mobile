import 'dart:io';

import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/fraud_policy.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';

class CheckInValidation {
  const CheckInValidation(
      {required this.allowed,
      required this.blockedReasons,
      required this.warnings});
  final bool allowed;
  final List<String> blockedReasons;
  final List<String> warnings;
}

/// Anti-fraud checks for check-in/out and the continuous location trail.
/// Every rule is individually gated by [FraudPolicy] so it can be relaxed
/// per business rule without touching this detection logic (per the
/// "modular so future business rules can enable/disable/relax" requirement).
class FraudDetectionService {
  const FraudDetectionService();

  /// Combines geofence + accuracy + mock-location into one pass/fail with
  /// specific reasons — never a generic "can't check in".
  CheckInValidation validateCheckIn({
    required bool insideGeofence,
    required double accuracyMeters,
    required bool isMocked,
    required bool vpnDetected,
    required FraudPolicy policy,
  }) {
    final blocked = <String>[];
    final warnings = <String>[];

    if (!insideGeofence) blocked.add("You're outside the customer's geofence.");
    if (accuracyMeters > policy.maxAccuracyMeters) {
      blocked.add(
          'GPS accuracy too low (±${accuracyMeters.toStringAsFixed(0)}m) — move to open sky and retry.');
    }
    if (isMocked) {
      if (policy.blockOnMockLocation) {
        blocked.add('Mock/fake location detected.');
      } else {
        warnings.add('Simulated location detected (allowed in this build).');
      }
    }
    if (vpnDetected) {
      if (policy.blockOnVpn) {
        blocked.add('Disable your VPN to check in.');
      } else {
        warnings.add(
            'VPN or proxy detected — location verification may be unreliable.');
      }
    }

    return CheckInValidation(
        allowed: blocked.isEmpty, blockedReasons: blocked, warnings: warnings);
  }

  /// Flags a consecutive sample pair as an "impossible travel" / teleport
  /// event if the implied speed exceeds [FraudPolicy.maxSpeedKmh].
  bool isImpossibleTravel(
      LocationSample previous, LocationSample current, FraudPolicy policy) {
    final seconds = current.timestamp.difference(previous.timestamp).inSeconds;
    if (seconds <= 0) return false;
    final meters = GeofenceService.distanceMeters(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    final kmh = (meters / 1000) / (seconds / 3600);
    return kmh > policy.maxSpeedKmh;
  }

  /// Best-effort, dependency-free VPN heuristic: scans active network
  /// interfaces for common VPN tunnel naming patterns (`tun`, `ppp`, `utun`
  /// on iOS). Not authoritative — swappable for a dedicated detection
  /// plugin later without changing any call site.
  Future<bool> detectVpnHeuristic() async {
    try {
      final interfaces = await NetworkInterface.list();
      return interfaces.any((i) {
        final name = i.name.toLowerCase();
        return name.startsWith('tun') ||
            name.startsWith('ppp') ||
            name.startsWith('utun');
      });
    } catch (_) {
      return false;
    }
  }
}
