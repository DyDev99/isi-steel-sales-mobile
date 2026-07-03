import 'dart:convert';
import 'dart:io';

import 'package:isi_steel_sales_mobile/features/routes/data/mock/mock_route_data.dart';

/// Writes `assets/mock/routes.json`, the demo route/customer dataset
/// `MockRouteRemoteDataSource` simulates syncing from.
///
/// Run with: `dart run tool/generate_mock_routes.dart [--seed=11]`
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
  final stopCount = routes.fold<int>(0, (sum, r) => sum + (r['stops'] as List).length);
  stdout.writeln(
      'Wrote ${customers.length} customers, ${routes.length} routes, $stopCount stops to ${file.path}');
}
