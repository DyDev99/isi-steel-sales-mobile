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
    this.allowReasonedCheckInOverride = true,
    this.minOverrideReasonLength = 10,
  });

  final bool blockOnMockLocation;
  final bool blockOnVpn;
  final double maxAccuracyMeters;
  final double maxSpeedKmh;

  /// Whether a rep may check in from outside the geofence, or on a fix too
  /// imprecise to judge, by giving a written reason.
  ///
  /// Exists because the geofence assumes two things a depot often breaks: that
  /// the shop's recorded pin is where the rep can stand, and that the handset
  /// can get a clean fix there. A yard entrance a hundred metres from the
  /// office pin, or a warehouse under a steel roof, fails both while the rep is
  /// demonstrably doing their job.
  ///
  /// **This never relaxes the integrity rules.** A mock location provider or a
  /// VPN cannot be reasoned past — those are claims about whether the device is
  /// telling the truth, and no free-text box should be able to answer them.
  /// Only the two location-derived rules are overridable.
  ///
  /// Turn it off for a territory where every stop is reliably geotagged and the
  /// override would just be a habit.
  final bool allowReasonedCheckInOverride;

  /// The shortest reason accepted. Long enough that "ok" and "." do not pass,
  /// short enough that a rep typing on a phone in a yard is not fighting it.
  final int minOverrideReasonLength;

  @override
  List<Object?> get props => [
        blockOnMockLocation,
        blockOnVpn,
        maxAccuracyMeters,
        maxSpeedKmh,
        allowReasonedCheckInOverride,
        minOverrideReasonLength,
      ];
}
