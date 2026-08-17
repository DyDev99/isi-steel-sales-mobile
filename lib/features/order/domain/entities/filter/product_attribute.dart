/// The catalog column a dynamic filter step narrows on.
///
/// This is the *only* hardcoded thing in the guided filter flow, and it has to
/// be: it's the closed set of product columns the catalog physically stores
/// (see `core/database/drift/tables/catalog_tables.dart`). SAP decides which
/// attributes a category exposes, in what order, and under what business label
/// ("Profile", "Shape", "Colour" all land on real columns) — the app never
/// decides that. Adding a genuinely new attribute is a schema change, not a
/// configuration change, which is exactly why it lives in code.
enum ProductAttribute {
  family,

  /// The plant/warehouse holding the stock — `products.warehouse_code`.
  ///
  /// Unlike the others this is not a property of the article, it is where the
  /// article is. It earns a place in this enum anyway because a `products` row
  /// is a SKU *at a location*, so narrowing by location is narrowing to a
  /// sellable SKU — the last thing the rep must pin down before quoting.
  warehouse,

  subCategory,
  brand,
  size,
  grade,
  material,
  length,
  width,
  height,
  diameter,
  thickness;

  /// Numeric attributes round-trip through `double`; the rest are text.
  bool get isNumeric => switch (this) {
        ProductAttribute.length ||
        ProductAttribute.width ||
        ProductAttribute.height ||
        ProductAttribute.diameter ||
        ProductAttribute.thickness =>
          true,
        _ => false,
      };

  static ProductAttribute? tryParse(String raw) {
    for (final value in ProductAttribute.values) {
      if (value.name.toLowerCase() == raw.toLowerCase()) return value;
    }
    return null;
  }
}
