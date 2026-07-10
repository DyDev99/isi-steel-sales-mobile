import 'package:equatable/equatable.dart';

/// A sellable item shown in the Revenue catalog. UI-independent —
/// formatting (currency strings, stock labels) happens in the
/// presentation mapper, not here.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.unit,
    required this.unitPrice,
    required this.availableStock,
  });

  final String id;
  final String name;
  final String sku;
  final String categoryId;
  final String unit;
  final double unitPrice;
  final double availableStock;

  bool get isInStock => availableStock > 0;

  @override
  List<Object?> get props =>
      [id, name, sku, categoryId, unit, unitPrice, availableStock];
}
