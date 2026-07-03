import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';

abstract interface class CategoryRepository {
  ResultFuture<List<Category>> fetchAll();
}
