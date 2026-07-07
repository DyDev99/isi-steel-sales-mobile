import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.sku,
    required super.categoryId,
    required super.unit,
    required super.unitPrice,
    required super.availableStock,
  });

  factory ProductModel.fromJson(DataMap json) => ProductModel(
        id: json['id'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String,
        categoryId: json['categoryId'] as String,
        unit: json['unit'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        availableStock: (json['availableStock'] as num).toDouble(),
      );
}
