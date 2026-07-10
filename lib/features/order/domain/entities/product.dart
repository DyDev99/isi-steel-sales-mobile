import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_pricing.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_status.dart';

/// A single sellable SKU (a size/grade/warehouse variant of some product
/// family — e.g. "SD390 Rebar 12mm" at warehouse WH-PP01). Denormalized read
/// model joined from `products` + `prices` + that row's own `stock` entry;
/// the underlying tables stay separate so the sync engine can apply
/// product/price/stock deltas independently.
///
/// [familyId]/[familyName] group sibling size/grade variants together (see
/// `getProductVariants`); [code] groups the same variant across warehouses
/// (see `getWarehouseStock`) — two different, orthogonal groupings.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.code,
    required this.sku,
    required this.materialCode,
    required this.barcode,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.subCategory,
    required this.brand,
    required this.grade,
    required this.material,
    required this.size,
    required this.diameter,
    required this.thickness,
    required this.length,
    required this.width,
    required this.height,
    required this.weight,
    required this.unit,
    required this.warehouseCode,
    required this.territory,
    required this.businessUnit,
    required this.imageUrl,
    required this.isMto,
    required this.status,
    required this.updatedAt,
    required this.pricing,
    required this.stockQuantity,
    required this.reservedQuantity,
    required this.minStock,
    required this.maxStock,
  });

  final String id;
  final String familyId;
  final String familyName;
  final String code;
  final String sku;
  final String materialCode;
  final String barcode;
  final String name;
  final String description;
  final String categoryId;
  final String subCategory;
  final String brand;
  final String grade;
  final String material;
  final String size;
  final double diameter;
  final double thickness;
  final double length;
  final double width;
  final double height;
  final double weight;
  final String unit;
  final String warehouseCode;
  final String territory;
  final String businessUnit;
  final String imageUrl;
  final bool isMto;
  final ProductStatus status;
  final DateTime updatedAt;

  final ProductPricing pricing;

  final double stockQuantity;
  final double reservedQuantity;
  final double minStock;
  final double maxStock;

  double get availableQuantity =>
      (stockQuantity - reservedQuantity).clamp(0, double.infinity);
  bool get isAvailable =>
      availableQuantity > 0 && status == ProductStatus.active;
  bool get isBelowMinStock => availableQuantity < minStock;
  bool get hasPromotion => pricing.hasPromotion;
  double get effectivePrice => pricing.effectivePrice();

  @override
  List<Object?> get props => [
        id,
        familyId,
        code,
        sku,
        materialCode,
        barcode,
        name,
        categoryId,
        subCategory,
        brand,
        warehouseCode,
        territory,
        status,
        updatedAt,
        pricing,
        stockQuantity,
        reservedQuantity,
      ];
}
