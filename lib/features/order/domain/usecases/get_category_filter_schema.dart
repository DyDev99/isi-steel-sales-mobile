import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_filter_repository.dart';

class CategorySchemaParams extends Equatable {
  const CategorySchemaParams(this.categoryId);
  final String categoryId;
  @override
  List<Object?> get props => [categoryId];
}

/// Fetches the SAP-defined filter hierarchy for one category — the shape of
/// every level the rep is about to walk, before any of them is resolved.
class GetCategoryFilterSchema
    extends UseCase<CategoryFilterSchema, CategorySchemaParams> {
  const GetCategoryFilterSchema(this._repository);
  final ProductFilterRepository _repository;

  @override
  ResultFuture<CategoryFilterSchema> call(CategorySchemaParams params) =>
      _repository.getFilterSchema(params.categoryId);
}
