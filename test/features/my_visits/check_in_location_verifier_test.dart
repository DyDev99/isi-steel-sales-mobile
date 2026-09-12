import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/customer_stop_info.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/check_in_location_verifier.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/outlet_location_source.dart';

/// The rule the check-in dialog renders and the check-in gate reads: is the rep
/// inside the designated check-in area.
///
/// Worth testing directly rather than through the dialog, because the failure
/// modes are arithmetic — a boundary compared with the wrong operator, a `(0,0)`
/// pin measured as a real one, a missing GPS fix read as "far away" — and none
/// of them look wrong on screen. They just quietly let the wrong rep check in,
/// or block the right one.
void main() {
  /// ISI's Phnom Penh office — the static demo pin.
  const outletLat = StaticOutletLocationSource.kDemoOutletLatitude;
  const outletLng = StaticOutletLocationSource.kDemoOutletLongitude;

  const outlet = OutletLocation(
    latitude: outletLat,
    longitude: outletLng,
    radiusMeters: kCheckInRadiusMeters,
  );

  CheckInLocationVerdict verifyAt(double? lat, double? lng,
          {OutletLocation? at = outlet}) =>
      CheckInLocationVerifier.verify(
        outlet: at,
        deviceLatitude: lat,
        deviceLongitude: lng,
        fallbackRadiusMeters: kCheckInRadiusMeters,
      );

  /// Metres north of the outlet, as a latitude. One degree of latitude is
  /// ~111 320 m everywhere, so this is exact enough to place a point at a known
  /// distance without re-deriving Haversine in the test.
  double latMetresNorth(double metres) => outletLat + metres / 111320.0;

  group('the 100 m check-in radius', () {
    test('standing on the outlet is within', () {
      final v = verifyAt(outletLat, outletLng);

      expect(v.isWithinRadius, isTrue);
      expect(v.distanceMeters, closeTo(0, 1));
      expect(v.radiusMeters, 100);
    });

    test('85 m away is within — the dialog\'s worked example', () {
      final v = verifyAt(latMetresNorth(85), outletLng);

      expect(v.isWithinRadius, isTrue);
      expect(v.distanceMeters, closeTo(85, 2));
    });

    test('250 m away is outside — the other worked example', () {
      final v = verifyAt(latMetresNorth(250), outletLng);

      expect(v.isWithinRadius, isFalse);
      expect(v.distanceMeters, closeTo(250, 3));
    });

    test('just inside and just outside fall on the right sides', () {
      expect(verifyAt(latMetresNorth(99), outletLng).isWithinRadius, isTrue);
      expect(verifyAt(latMetresNorth(101), outletLng).isWithinRadius, isFalse);
    });

    test('exactly on the boundary counts as within', () {
      // `<=`, not `<`. The radius is the edge of the permitted area, not the
      // first metre outside it — and a rep standing on a line they cannot see
      // should not be refused by a rounding decision.
      final v = CheckInLocationVerifier.verify(
        outlet: const OutletLocation(
            latitude: outletLat, longitude: outletLng, radiusMeters: 0),
        deviceLatitude: outletLat,
        deviceLongitude: outletLng,
        fallbackRadiusMeters: kCheckInRadiusMeters,
      );

      expect(v.distanceMeters, closeTo(0, 0.001));
      expect(v.isWithinRadius, isTrue);
    });

    test('distance is symmetric in every direction', () {
      // Not just north: a bug in the longitude term only shows up east-west,
      // where a degree is ~0.98× a latitude degree at this parallel.
      final north = verifyAt(latMetresNorth(150), outletLng).distanceMeters;
      final south = verifyAt(latMetresNorth(-150), outletLng).distanceMeters;

      expect(north, closeTo(150, 3));
      expect(south, closeTo(150, 3));
    });
  });

  group('the outcomes that are not "inside" or "outside"', () {
    test('no device fix is its own verdict, not "far away"', () {
      final v = verifyAt(null, null);

      expect(v.hasDeviceFix, isFalse);
      expect(v.isMeasurable, isFalse);
      expect(v.isWithinRadius, isFalse,
          reason: 'never confirmable without a position');
      expect(v.distanceMeters.isNaN, isTrue,
          reason: 'no distance to show — the UI must check isMeasurable');
      // The radius is still known, so the dialog can state the rule.
      expect(v.radiusMeters, 100);
    });

    test('a half-known position is treated as no fix', () {
      expect(verifyAt(outletLat, null).hasDeviceFix, isFalse);
      expect(verifyAt(null, outletLng).hasDeviceFix, isFalse);
    });

    test('no outlet location is reported, not measured against (0,0)', () {
      final v = verifyAt(outletLat, outletLng, at: null);

      expect(v.hasOutletLocation, isFalse);
      expect(v.isWithinRadius, isFalse);
      expect(v.distanceMeters.isNaN, isTrue);
      expect(v.radiusMeters, kCheckInRadiusMeters,
          reason: 'falls back to the configured radius so the rule is sayable');
    });
  });

  group('the static-position shim', _staticShimTests);

  group('the outlet source seam', () {
    CustomerStopInfo customer({double lat = 11.60, double lng = 104.90}) =>
        CustomerStopInfo(
          id: 'c1',
          name: 'ISI Steel Outlet',
          code: 'C-1',
          contact: 'Sok Dara',
          phone: '012345678',
          address: 'St 271',
          territory: 'PP-CENTRAL',
          territoryType: TerritoryType.urban,
          latitude: lat,
          longitude: lng,
        );

    test('the static source ignores the stop and returns the demo pin', () {
      const source = StaticOutletLocationSource();

      final location = source.locationFor(customer())!;

      // Every stop verifies against the same point — correct for a demo, and
      // the reason this is a named class rather than a constant in a widget.
      expect(location.latitude, outletLat);
      expect(location.longitude, outletLng);
      expect(location.radiusMeters, 100);
    });

    test('the stop source uses the customer’s own pin', () {
      const source = StopOutletLocationSource();

      final location = source.locationFor(customer(lat: 11.60, lng: 104.90))!;

      expect(location.latitude, 11.60);
      expect(location.longitude, 104.90);
      expect(location.radiusMeters, 100);
    });

    test('the stop source returns null for a customer with no pin', () {
      const source = StopOutletLocationSource();

      // `(0, 0)` is the Gulf of Guinea and what a handset reports when the fix
      // failed. Measuring against it would put every rep ~10 000 km out.
      expect(source.locationFor(customer(lat: 0, lng: 0)), isNull);
    });

    test('swapping the source is the only change needed', () {
      // The verifier reads whatever the source hands it, so the seam really is
      // one registration. If this ever needs more than the two lines below, the
      // indirection has stopped paying for itself.
      const staticSource = StaticOutletLocationSource();
      const stopSource = StopOutletLocationSource();
      final c = customer(lat: 11.60, lng: 104.90);

      final viaStatic = CheckInLocationVerifier.verify(
        outlet: staticSource.locationFor(c),
        deviceLatitude: outletLat,
        deviceLongitude: outletLng,
        fallbackRadiusMeters: kCheckInRadiusMeters,
      );
      final viaStop = CheckInLocationVerifier.verify(
        outlet: stopSource.locationFor(c),
        deviceLatitude: outletLat,
        deviceLongitude: outletLng,
        fallbackRadiusMeters: kCheckInRadiusMeters,
      );

      // Standing on the demo pin: inside the demo area, far from the real stop.
      expect(viaStatic.isWithinRadius, isTrue);
      expect(viaStop.isWithinRadius, isFalse);
    });
  });
}

/// The static-position shim, which is what makes the flow usable with no GPS.
///
/// Its predecessor measured the *real* device position while only the pushed
/// payload used the constant, so on a simulator the dialog sat on "Locating
/// You" and no check-in could be made at all.
void _staticShimTests() {
  test('the shim is debug-only and cannot ship enabled', () {
    // `kDebugMode`-defaulted rather than a bare `true`. Under `flutter test`
    // this is a debug VM, so it reads true here — the assertion that matters
    // is that it is not hardcoded on.
    expect(kUseStaticCheckInPosition, isTrue,
        reason: 'expected on under a debug test VM');
  });

  test('the default static position is within the radius of the demo pin', () {
    // 0 m — so a check-in completes end to end with no GPS, which is the whole
    // purpose of the shim.
    final v = CheckInLocationVerifier.verify(
      outlet: const StaticOutletLocationSource().locationFor(
        const CustomerStopInfo(
          id: 'c1',
          name: 'ISI Steel Outlet',
          code: 'C-1',
          contact: '',
          phone: '',
          address: '',
          territory: 'PP-CENTRAL',
          territoryType: TerritoryType.urban,
          latitude: 11.60,
          longitude: 104.90,
        ),
      ),
      deviceLatitude: kStaticCheckInPosition.latitude,
      deviceLongitude: kStaticCheckInPosition.longitude,
      fallbackRadiusMeters: kCheckInRadiusMeters,
    );

    expect(v.isMeasurable, isTrue,
        reason: 'never "Locating You" — that was the bug');
    expect(v.isWithinRadius, isTrue);
    expect(v.distanceMeters, closeTo(0, 1));
  });
}
