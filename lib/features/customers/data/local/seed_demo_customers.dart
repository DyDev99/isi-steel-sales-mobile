import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// TODO(release-gate): DEBUG / DEMO ONLY — must never run in a release build.
///
/// Seeds the customer directory from the My Visits demo fixture
/// (`assets/mock/routes.json`) so the mock route sync can attach stops.
///
/// **Why this exists.** `route_stops.customer_id` is a real FK into the
/// SAP-owned customer directory (ADR-001, `my_visits/my_visite.md` §8), and
/// `RouteDriftLocalDataSource.upsertCustomers` only *updates* customers that
/// already exist — route sync may never invent one. The old in-memory customer
/// generator that used to provide the demo's `CUST-xxxx` rows was removed when
/// the directory became SAP-only (`customers_injection.dart`), but the demo
/// route fixture still references those IDs, which a real SAP backend never
/// returns. Without this shim every stop's customer is "not in directory",
/// every `route_stops` insert fails its FK, the whole route transaction aborts,
/// and the dashboard shows zero routes.
///
/// This is *not* route sync inventing customers: it runs through the Customers
/// feature's own [CustomerLocalDataSource], and only when the directory is
/// empty, so it never clobbers a real SAP-synced directory.
Future<int> seedDemoCustomersFromRoutesAsset(
  CustomerLocalDataSource local, {
  String assetPath = 'assets/mock/routes.json',
}) async {
  // Only seed a fresh, empty directory — never overwrite real (SAP) data.
  final existing = await local.browse(page: 0, pageSize: 1);
  if (existing.isNotEmpty) return 0;

  final raw = await rootBundle.loadString(assetPath);
  final decoded = json.decode(raw) as Map<String, dynamic>;
  final rows = (decoded['customers'] as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  if (rows.isEmpty) return 0;

  final now = DateTime.now().toUtc();
  final models = <CustomerModel>[
    for (final r in rows)
      CustomerModel(
        id: r['id'] as String,
        // The demo fixture carries no SAP id; reuse the customer code so the
        // row is self-consistent for the demo.
        sapCustomerId: (r['code'] as String?) ?? r['id'] as String,
        customerCode: (r['code'] as String?) ?? r['id'] as String,
        shopName: (r['name'] as String?) ?? 'Customer',
        ownerName: (r['contact'] as String?) ?? '',
        phone: (r['phone'] as String?) ?? '',
        address: (r['address'] as String?) ?? '',
        province: (r['territory'] as String?) ?? '',
        district: (r['territory'] as String?) ?? '',
        territory: r['territory'] as String?,
        latitude: (r['latitude'] as num?)?.toDouble(),
        longitude: (r['longitude'] as num?)?.toDouble(),
        creditLimit: 0,
        status: CustomerStatus.active,
        updatedAt: now,
      ),
  ];

  await local.upsertCustomers(models);
  return models.length;
}
