import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';

/// Static mock payloads for the Revenue feature. UI-only — no backend.
/// Shaped as raw JSON maps so [ProductModel.fromJson] etc. are exercised
/// the same way they would be against a real response.
class RevenueMockData {
  RevenueMockData._();

  static const List<DataMap> categories = [
    {'id': 'cat-rebar', 'name': 'Rebar'},
    {'id': 'cat-pipe', 'name': 'Pipe'},
    {'id': 'cat-sheet', 'name': 'Sheet'},
    {'id': 'cat-wire', 'name': 'Wire Mesh'},
    {'id': 'cat-angle', 'name': 'Angle Bar'},
  ];

  static const List<DataMap> products = [
    {
      'id': 'p-001',
      'name': 'SD390 Rebar 12mm',
      'sku': 'RB-12-SD390',
      'categoryId': 'cat-rebar',
      'unit': 'Ton',
      'unitPrice': 685.0,
      'availableStock': 42.0,
    },
    {
      'id': 'p-002',
      'name': 'SD390 Rebar 16mm',
      'sku': 'RB-16-SD390',
      'categoryId': 'cat-rebar',
      'unit': 'Ton',
      'unitPrice': 690.0,
      'availableStock': 18.0,
    },
    {
      'id': 'p-003',
      'name': 'Galvanized Pipe 2"',
      'sku': 'PP-02-GAL',
      'categoryId': 'cat-pipe',
      'unit': 'Pcs',
      'unitPrice': 24.5,
      'availableStock': 130.0,
    },
    {
      'id': 'p-004',
      'name': 'Black Steel Pipe 3"',
      'sku': 'PP-03-BLK',
      'categoryId': 'cat-pipe',
      'unit': 'Pcs',
      'unitPrice': 31.0,
      'availableStock': 0.0,
    },
    {
      'id': 'p-005',
      'name': 'Hot Rolled Sheet 4x8',
      'sku': 'SH-HR-4X8',
      'categoryId': 'cat-sheet',
      'unit': 'Sheet',
      'unitPrice': 112.0,
      'availableStock': 65.0,
    },
    {
      'id': 'p-006',
      'name': 'Cold Rolled Sheet 4x8',
      'sku': 'SH-CR-4X8',
      'categoryId': 'cat-sheet',
      'unit': 'Sheet',
      'unitPrice': 128.0,
      'availableStock': 27.0,
    },
    {
      'id': 'p-007',
      'name': 'Wire Mesh 6x6',
      'sku': 'WM-6X6',
      'categoryId': 'cat-wire',
      'unit': 'Roll',
      'unitPrice': 46.0,
      'availableStock': 54.0,
    },
    {
      'id': 'p-008',
      'name': 'Angle Bar 50x50x5',
      'sku': 'AB-50-05',
      'categoryId': 'cat-angle',
      'unit': 'Pcs',
      'unitPrice': 18.75,
      'availableStock': 90.0,
    },
    {
      'id': 'p-009',
      'name': 'Angle Bar 40x40x4',
      'sku': 'AB-40-04',
      'categoryId': 'cat-angle',
      'unit': 'Pcs',
      'unitPrice': 14.2,
      'availableStock': 3.0,
    },
    {
      'id': 'p-010',
      'name': 'SD390 Rebar 20mm',
      'sku': 'RB-20-SD390',
      'categoryId': 'cat-rebar',
      'unit': 'Ton',
      'unitPrice': 695.0,
      'availableStock': 11.0,
    },
  ];

  static const List<DataMap> discountOptions = [
    {'id': 'd-000', 'label': '0%', 'percentage': 0.0, 'isDefault': true},
    {'id': 'd-005', 'label': '5%', 'percentage': 5.0, 'isDefault': false},
    {'id': 'd-010', 'label': '10%', 'percentage': 10.0, 'isDefault': false},
    {'id': 'd-015', 'label': '15%', 'percentage': 15.0, 'isDefault': false},
  ];

  static const DataMap customerCredit = {
    'customerId': 'cust-001',
    'customerName': 'Angkor Hardware Supply',
    'creditLimit': 25000.0,
    'usedCredit': 16200.0,
    'outstandingBalance': 3400.0,
  };
}
