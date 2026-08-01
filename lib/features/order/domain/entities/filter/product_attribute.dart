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
