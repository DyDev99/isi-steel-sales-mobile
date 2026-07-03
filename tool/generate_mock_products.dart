import 'dart:convert';
import 'dart:io';

import 'package:isi_steel_sales_mobile/features/order/data/mock/mock_product_data.dart';

/// Writes `assets/mock/products.json`, the demo catalog dataset that
/// `MockProductRemoteDataSource` simulates syncing from.
///
/// Run with: `dart run tool/generate_mock_products.dart [--seed=7]`
///
/// Row count isn't a direct parameter — it falls out of
/// `MockProductData`'s composed generators (~300 families x 20-100 variants
/// x 1-3 warehouses each, landing in the 10k-30k SKU range described in
/// `ProductGenerator`/`VariantGenerator`/`WarehouseGenerator`). The same
/// generators scale to millions on a real backend without this script
/// changing shape.
void main(List<String> args) {
  var seed = 7;
  for (final arg in args) {
    if (arg.startsWith('--seed=')) seed = int.parse(arg.substring(7));
  }

  final data = MockProductData.generate(seed: seed);
  final file = File('assets/mock/products.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(data));

  final products = data['products'] as List;
  final categories = data['categories'] as List;
  stdout.writeln(
      'Wrote ${products.length} products across ${categories.length} categories to ${file.path}');
}
