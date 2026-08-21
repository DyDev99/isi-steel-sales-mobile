import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/mock/mock_customer_data.dart';
import 'package:isi_steel_sales_mobile/features/order/data/mock/mock_product_data.dart';

/// Guards the single-source rule for mock master data: **every generated
/// record carries both languages on the same row**.
///
/// This is the regression these tests exist for. The catalog, the customer
/// directory and the route dataset each shipped with the Khmer half of the
/// data empty on the generated rows while the handful of curated rows had it —
/// which presents as "localization is broken" when it is really a data gap,
/// and is invisible to anyone testing in English.
///
/// They also pin the *committed assets*, not just the generators. The two
/// drift independently: `assets/mock/products.json` is what the app actually
/// serves, and it stayed a catalog generation behind `mock_product_data.dart`
/// for long enough that 17,145 rows had no Khmer name at all.
void main() {
  group('customer directory', () {
    final customers = MockCustomerData.generate(bulkCount: 60);

    test('every customer carries a Khmer name, not just the curated ones', () {
      final missing =
          customers.where((c) => (c.khName ?? '').trim().isEmpty).toList();
      expect(missing, isEmpty,
          reason: '${missing.length} of ${customers.length} customers have no '
              'khName — they will silently stay Latin in a Khmer session');
    });

    test('displayName resolves per language and never renders empty', () {
      for (final c in customers) {
        expect(c.displayName.resolve('en'), isNotEmpty);
        expect(c.displayName.resolve('km'), isNotEmpty);
      }
    });

    test('search spans both languages at once', () {
      final c = customers.first;
      expect(c.searchableValues, contains(c.displayName.en));
      expect(c.searchableValues, contains(c.displayName.km));
      expect(c.searchableValues, contains(c.customerCode));
    });
  });

  group('product catalog generator', () {
    final data = MockProductData.generate();

    test('every generated product carries a Khmer name', () {
      final products = (data['products'] as List).cast<Map<String, dynamic>>();
      final missing = products
          .where((p) => ((p['nameKh'] as String?) ?? '').trim().isEmpty)
          .toList();
      expect(missing, isEmpty);
    });

    test('every category carries a Khmer name', () {
      final categories =
          (data['categories'] as List).cast<Map<String, dynamic>>();
      final missing = categories
          .where((c) => ((c['nameKh'] as String?) ?? '').trim().isEmpty)
          .toList();
      expect(missing, isEmpty);
    });
  });

  // The generator being correct is not enough — `MockProductRemoteDataSource`
  // serves the committed asset and only falls back to the generator when the
  // file is *missing*, so a stale asset silently wins.
  group('committed assets/mock/products.json', () {
    late Map<String, dynamic> decoded;

    setUpAll(() {
      decoded =
          json.decode(File('assets/mock/products.json').readAsStringSync())
              as Map<String, dynamic>;
    });

    test('is not stale: every product row has a Khmer name', () {
      final products =
          (decoded['products'] as List).cast<Map<String, dynamic>>();
      final missing = products
          .where((p) => ((p['nameKh'] as String?) ?? '').trim().isEmpty)
          .length;
      expect(missing, 0,
          reason: '$missing of ${products.length} rows have no nameKh — '
              're-run `dart run tool/generate_mock_products.dart`');
    });

    test('is not stale: every category row has a Khmer name', () {
      final categories =
          (decoded['categories'] as List).cast<Map<String, dynamic>>();
      expect(
        categories
            .where((c) => ((c['nameKh'] as String?) ?? '').trim().isEmpty)
            .length,
        0,
      );
    });
  });
}
