import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/customer_stop_info.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/check_in_location_verifier.dart';

/// Where the check-in area for an outlet comes from.
///
/// One interface with two implementations so the swap from the demo pin to real
/// backend coordinates is a DI change and nothing else — no call site, no
/// verifier and no widget knows which is registered.
///
/// ```text
/// today                          later
/// ─────                          ─────
/// StaticOutletLocationSource     StopOutletLocationSource
///   fixed demo pin                 the synced stop's own pin
///          ↓                              ↓
///        CheckInLocationVerifier
///                    ↓
///          distance + radius verdict
/// ```
abstract interface class OutletLocationSource {
  /// The designated check-in area for [customer], or null when there is none
  /// to measure against.
  OutletLocation? locationFor(CustomerStopInfo customer);

  /// The radius used when [locationFor] cannot produce a location — so the UI
  /// can still say what the rule *would* have been.
  double get radiusMeters;
}

/// The check-in radius for this build: **100 m**.
///
/// Deliberately one constant rather than a per-territory figure. The
/// territory-sized radii on `TerritoryType` (urban 50 m … rural 250 m) remain
/// the production rule for `GeofenceService`, but a demo pin has no territory
/// worth honouring, and a dialog that said "within" at 85 m while the
/// underlying check refused at 50 m would be worse than either rule alone.
const double kCheckInRadiusMeters = 100;

/// A fixed pin, for demonstrating and testing the check-in flow before outlet
/// coordinates exist on the backend.
///
/// Every rep verifies against the same point regardless of which stop they
/// opened. That is correct *for a demo* and wrong for anything else, which is
/// why it is a named class rather than a constant buried in a widget: the thing
/// to change later is the registration in `my_visits_injection.dart`, and this
/// type is what makes that a one-line change.
///
/// The coordinates are ISI's Phnom Penh office.
class StaticOutletLocationSource implements OutletLocationSource {
  const StaticOutletLocationSource({
    this.latitude = kDemoOutletLatitude,
    this.longitude = kDemoOutletLongitude,
    this.radiusMeters = kCheckInRadiusMeters,
  });

  static const double kDemoOutletLatitude = 11.5564;
  static const double kDemoOutletLongitude = 104.9282;

  final double latitude;
  final double longitude;

  @override
  final double radiusMeters;

  @override
  OutletLocation? locationFor(CustomerStopInfo customer) => OutletLocation(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
}

/// The real thing: verify against the stop's own synced pin.
///
/// Already written because it is four lines and because leaving it unwritten is
/// how a "temporary" demo constant survives to production. Swapping to it is a
/// one-line change in `my_visits_injection.dart` once outlet coordinates are
/// trustworthy — no other file moves.
///
/// Returns null for a customer with no pin, which the verifier reports as
/// "no outlet location" rather than measuring against `(0, 0)`.
class StopOutletLocationSource implements OutletLocationSource {
  const StopOutletLocationSource({this.radiusMeters = kCheckInRadiusMeters});

  @override
  final double radiusMeters;

  @override
  OutletLocation? locationFor(CustomerStopInfo customer) =>
      OutletLocation.forStop(customer, radiusMeters: radiusMeters);
}

/// TODO(release-gate): take the rep's position from a constant, not the GPS.
///
/// **Debug builds only.** Defaulted to [kDebugMode] rather than a bare `true`
/// so it physically cannot reach a release build, and overridable either way
/// with `--dart-define=STATIC_CHECK_IN_POSITION=false`.
///
/// ## What this replaces
///
/// The rep's own position, everywhere it is used in the check-in flow:
///
/// * the distance the verification dialog measures and shows, and
/// * the `latitude`/`longitude` stamped on the pushed check-in row.
///
/// Both come from [kStaticCheckInPosition] instead of the device. That is the
/// point: on a simulator, or any handset that has not been granted location,
/// there is no fix — so the dialog would sit on "Locating You" and no check-in
/// could ever be made. This makes the whole flow exercisable without GPS.
///
/// ## What it costs
///
/// `latitude`/`longitude` on a check-in are the geofence evidence the **server**
/// judges the visit on (api.md §8.2). `ActiveRouteBloc` normally sends the
/// rep's measured position for exactly that reason — an earlier version sent
/// the shop's own pin, which made every check-in arrive reading as precisely
/// on-location whoever sent it, and left the server-side check structurally
/// incapable of catching anything.
///
/// With this on, that is deliberately true again, and the rep is also *shown* a
/// distance nobody measured. Neither is acceptable in a rep's hands; both are
/// exactly what is wanted while the outlet feed and location permissions are
/// still being built. It must be off before release.
const bool kUseStaticCheckInPosition = bool.fromEnvironment(
  'STATIC_CHECK_IN_POSITION',
  defaultValue: kDebugMode,
);

/// The rep's stand-in position while [kUseStaticCheckInPosition] is on.
///
/// Defaults to the demo outlet pin, so the verdict is **0 m — within the
/// check-in radius** and a check-in can be completed end to end with no GPS.
///
/// To exercise the *outside* path — the reason sheet, the `reasonedOverride`
/// fraud flag, the reason on the pushed row — move this far enough out. Roughly
/// 250 m north of the pin:
///
/// ```dart
/// const kStaticCheckInPosition = (latitude: 11.5586, longitude: 104.9282);
/// ```
const ({double latitude, double longitude}) kStaticCheckInPosition = (
  latitude: StaticOutletLocationSource.kDemoOutletLatitude,
  longitude: StaticOutletLocationSource.kDemoOutletLongitude,
);
