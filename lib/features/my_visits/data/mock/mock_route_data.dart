import 'dart:math';

/// Deterministic generator for the demo route-management dataset. Composed
/// from small single-purpose generators (mirrors
/// `order/data/mock/mock_product_data.dart`'s shape): [TerritoryGenerator]
/// supplies the province/geofence-class table, [CustomerGenerator] scatters
/// 300+ customers around those provinces, [RouteGenerator]/[StopGenerator]
/// assemble 10-30 daily routes of 8-15 sequenced stops each. Produces plain
/// JSON-ready maps — the only consumer is
/// `tool/generate_mock_routes.dart` (writes `assets/mock/routes.json`) and
/// `MockRouteRemoteDataSource`'s in-memory fallback.
class MockRouteData {
  MockRouteData._();

  static Map<String, dynamic> generate({int seed = 11}) {
    final rand = Random(seed);
    final customers = CustomerGenerator.build(rand);
    final routes = RouteGenerator.build(rand, customers);

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'territories': TerritoryGenerator.territories.entries
          .map((e) => {
                'name': e.key,
                'type': e.value.type,
                'latitude': e.value.lat,
                'longitude': e.value.lng,
              })
          .toList(),
      'customers': customers,
      'routes': routes,
    };
  }
}

class _Territory {
  const _Territory(
      {required this.type,
      required this.lat,
      required this.lng,
      required this.districts});
  final String type; // urban | suburban | industrial | rural
  final double lat;
  final double lng;
  final List<String> districts;
}

/// Reuses the same province/coordinate table `mock_lead_data.dart` already
/// established, classified into the geofence-radius tiers the spec calls
/// for (urban 50m / suburban 100m / industrial 150m / rural 250m).
class TerritoryGenerator {
  TerritoryGenerator._();

  static const territories = <String, _Territory>{
    'Phnom Penh': _Territory(
        type: 'urban',
        lat: 11.5564,
        lng: 104.9282,
        districts: [
          'Chamkarmon',
          'Toul Kork',
          'Meanchey',
          'Sen Sok',
          'Daun Penh'
        ]),
    'Kandal': _Territory(
        type: 'suburban',
        lat: 11.4780,
        lng: 104.9450,
        districts: ['Ta Khmau', 'Kien Svay', "Sa'ang"]),
    'Kampot': _Territory(
        type: 'rural',
        lat: 10.6104,
        lng: 104.1817,
        districts: ['Kampot Town', 'Chum Kiri', 'Angkor Chey']),
    'Battambang': _Territory(
        type: 'suburban',
        lat: 13.0957,
        lng: 103.2022,
        districts: ['Battambang Town', 'Bavel', 'Sangkae']),
    'Siem Reap': _Territory(
        type: 'suburban',
        lat: 13.3671,
        lng: 103.8448,
        districts: ['Siem Reap Town', 'Angkor Thom', 'Puok']),
    'Preah Sihanouk': _Territory(
        type: 'industrial',
        lat: 10.6104,
        lng: 103.5299,
        districts: ['Sihanoukville', 'Prey Nob']),
    'Kampong Cham': _Territory(
        type: 'suburban',
        lat: 12.0000,
        lng: 105.4630,
        districts: ['Kampong Cham Town', 'Cheung Prey']),
    'Kampong Speu': _Territory(
        type: 'suburban',
        lat: 11.4585,
        lng: 104.5225,
        districts: ['Chbar Mon', 'Samraong Tong']),
    'Takeo': _Territory(
        type: 'rural',
        lat: 10.9908,
        lng: 104.7852,
        districts: ['Doun Kaev', 'Bati']),
    'Prey Veng': _Territory(
        type: 'rural',
        lat: 11.4860,
        lng: 105.3251,
        districts: ['Prey Veng Town', 'Kamchay Mear']),
  };
}

class CustomerGenerator {
  CustomerGenerator._();

  static const _namePrefixes = [
    'Angkor',
    'Mekong',
    'Golden',
    'Royal',
    'Prosperity',
    'Union',
    'Kingdom',
    'Sunrise',
    'Diamond',
    'Phnom',
    'Delta',
    'Heritage',
    'Central',
    'National',
    'Pacific',
  ];
  static const _nameSuffixes = [
    'Hardware',
    'Construction Supply',
    'Steel Depot',
    'Trading Co.',
    'Building Materials',
    'Iron Works',
    'Metal Center',
    'Engineering',
    'Contractors',
    'Warehouse',
  ];
  static const _contactFirstNames = [
    'Sokha',
    'Dara',
    'Vichea',
    'Sreymom',
    'Bunthoeun',
    'Chanthou',
    'Rithy',
    'Sopheak',
    'Mealea',
    'Pisach',
    'Kunthea',
    'Vibol',
  ];

  static List<Map<String, dynamic>> build(Random rand) {
    final customers = <Map<String, dynamic>>[];
    var seq = 1;
    for (var i = 0; i < 320; i++) {
      final provinceEntry = TerritoryGenerator.territories.entries
          .elementAt(rand.nextInt(TerritoryGenerator.territories.length));
      final province = provinceEntry.key;
      final territory = provinceEntry.value;
      final district =
          territory.districts[rand.nextInt(territory.districts.length)];

      final name = '${_namePrefixes[rand.nextInt(_namePrefixes.length)]} '
          '${_nameSuffixes[rand.nextInt(_nameSuffixes.length)]}';
      final contact =
          _contactFirstNames[rand.nextInt(_contactFirstNames.length)];

      // ~0.01-0.09 degrees (~1-10km) jitter around the province center.
      final latJitter = (rand.nextDouble() - 0.5) * 0.18;
      final lngJitter = (rand.nextDouble() - 0.5) * 0.18;

      customers.add({
        'id': 'CUST-${seq.toString().padLeft(4, '0')}',
        'name': name,
        'code': 'C${(10000 + seq)}',
        'contact': contact,
        'phone':
            '0${6 + rand.nextInt(3)}${100 + rand.nextInt(900)}${1000 + rand.nextInt(9000)}',
        'address': '#${1 + rand.nextInt(300)}, $district, $province',
        'territory': province,
        'territoryType': territory.type,
        'latitude': territory.lat + latJitter,
        'longitude': territory.lng + lngJitter,
        'geofenceRadiusOverride': null,
      });
      seq++;
    }
    return customers;
  }
}

class RouteGenerator {
  RouteGenerator._();

  static const _repNames = [
    'Sokha Meas',
    'Dara Chan',
    'Vichea Long',
    'Sreymom Kim',
    'Bunthoeun Ny',
    'Rithy Pech',
  ];

  static List<Map<String, dynamic>> build(
      Random rand, List<Map<String, dynamic>> customers) {
    final routeCount = 18 + rand.nextInt(13); // 18-30
    final routes = <Map<String, dynamic>>[];
    final today = DateTime.now();
    final visitDate = DateTime(today.year, today.month, today.day);

    final byTerritory = <String, List<Map<String, dynamic>>>{};
    for (final c in customers) {
      (byTerritory[c['territory'] as String] ??= []).add(c);
    }
    final territoryNames = byTerritory.keys.toList();

    for (var r = 0; r < routeCount; r++) {
      // Guarantee the synced territory (Phnom Penh — see RouteSyncScope) has a
      // full day of routes; the rest scatter randomly across provinces.
      final territoryName = r < 6
          ? 'Phnom Penh'
          : territoryNames[rand.nextInt(territoryNames.length)];
      final pool = List<Map<String, dynamic>>.from(byTerritory[territoryName]!)
        ..shuffle(rand);
      final stopCount = min(pool.length, 8 + rand.nextInt(8)); // 8-15
      final routeId = 'ROUTE-${(1000 + r)}';
      final rep = _repNames[rand.nextInt(_repNames.length)];

      var cursor = visitDate.add(const Duration(hours: 8));
      final stops = <Map<String, dynamic>>[];
      for (var s = 0; s < stopCount; s++) {
        final customer = pool[s];
        final travelMinutes = 15 + rand.nextInt(25);
        final visitMinutes = 15 + rand.nextInt(20);
        final plannedArrival = cursor.add(Duration(minutes: travelMinutes));
        final plannedDeparture =
            plannedArrival.add(Duration(minutes: visitMinutes));
        stops.add({
          'id': '$routeId-STOP-${s + 1}',
          'routeId': routeId,
          'customerId': customer['id'],
          'sequence': s + 1,
          'plannedArrival': plannedArrival.toIso8601String(),
          'plannedDeparture': plannedDeparture.toIso8601String(),
        });
        cursor = plannedDeparture;
      }

      routes.add({
        'id': routeId,
        'name': '$territoryName Route ${r + 1}',
        'repId': 'REP-${rep.hashCode & 0xFFFF}',
        'repName': rep,
        'territory': territoryName,
        'visitDate': visitDate.toIso8601String(),
        'plannedStart':
            visitDate.add(const Duration(hours: 8)).toIso8601String(),
        'plannedEnd': cursor.toIso8601String(),
        'status': 'published',
        'stops': stops,
      });
    }
    return routes;
  }
}
