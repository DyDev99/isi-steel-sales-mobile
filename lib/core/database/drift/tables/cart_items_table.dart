import 'package:drift/drift.dart';

/// Local, ephemeral shopping cart (Blueprint Layer 1, local-only — never
/// synced). Ported from `catalog.db`. [createdAt] is kept as ISO **text** (not
/// a DateTimeColumn) to preserve the exact `DataMap` row contract the cart
/// repository already reads/writes, so the cutover needs no repository change.
class CartItems extends Table {
  @override
  String get tableName => 'cart_items';

  TextColumn get id => text()();
  TextColumn get productId => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  TextColumn get leadId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get editingQuotationId => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
