import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';

class CategoryModel extends ProductCategory {
  const CategoryModel({required super.id, required super.name});

  factory CategoryModel.fromJson(DataMap json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
