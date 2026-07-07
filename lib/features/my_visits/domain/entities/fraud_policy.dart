import 'package:equatable/equatable.dart';

/// Configurable enforcement rules — modular by design so business rules can
/// enable/disable/relax individual checks without touching
/// `FraudDetectionService`'s detection logic itself.
///
/// [blockOnMockLocation] defaults `false` in this build: Android emulators
/// always report `Position.isMocked == true` for simulated GPS, so a
/// strict default would make check-in untestable during development. Flip
/// to `true` for a real-device/production build.
class FraudPolicy extends Equatable {
  const FraudPolicy({
    this.blockOnMockLocation = false,
    this.blockOnVpn = false,
    this.maxAccuracyMeters = 30,
    this.maxSpeedKmh = 150,
  });

  final bool blockOnMockLocation;
  final bool blockOnVpn;
  final double maxAccuracyMeters;
  final double maxSpeedKmh;

  @override
  List<Object?> get props => [blockOnMockLocation, blockOnVpn, maxAccuracyMeters, maxSpeedKmh];
}
