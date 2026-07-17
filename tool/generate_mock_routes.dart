import 'dart:convert';
import 'dart:io';

import 'package:isi_steel_sales_mobile/features/my_visits/data/mock/mock_route_data.dart';

/// Writes `assets/mock/routes.json`, the demo route-management dataset that
/// `MockRouteRemoteDataSource` simulates syncing from.
///
/// Run with: `dart run tool/generate_mock_routes.dart [--seed=11]`
///
/// The dataset is the single source of truth for the My Visits demo: 320
/// customers across 10 territories, 18-30 daily routes of 8-15 sequenced
/// stops, each stop carrying an execution `status` (checkedOut / checkedIn /
/// missed / pending) plus actual arrival/departure times, and each route a
/// `status` (completed / inProgress / published). The datasource re-bases the
/// baked `visitDate` onto the current day at load, so this asset never goes
/// stale even though it stamps a concrete generation date here.
void main(List<String> args) {
  var seed = 11;
  for (final arg in args) {
    if (arg.startsWith('--seed=')) seed = int.parse(arg.substring(7));
  }

  final data = MockRouteData.generate(seed: seed);
  final file = File('assets/mock/routes.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(data));

  final customers = data['customers'] as List;
  final routes = data['routes'] as List;
  final stops =
      routes.fold<int>(0, (sum, r) => sum + (r['stops'] as List).length);
  stdout.writeln(
      'Wrote ${routes.length} routes ($stops stops) across ${customers.length} '
      'customers to ${file.path}');
}
