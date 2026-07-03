import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.sortOrder,
    super.parentId,
  });

  factory CategoryModel.fromJson(DataMap json) => CategoryModel(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        name: json['name'] as String,
        sortOrder: (json['sortOrder'] as num).toInt(),
      );

  factory CategoryModel.fromRow(DataMap row) => CategoryModel(
        id: row['id'] as String,
        parentId: row['parent_id'] as String?,
        name: row['name'] as String,
        sortOrder: (row['sort_order'] as num).toInt(),
      );

  DataMap toRow() => {
        'id': id,
        'parent_id': parentId,
        'name': name,
        'sort_order': sortOrder,
      };
}
