import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_filter_repository.dart';

/// Step 0 of the guided flow: the only thing loaded when the configurator
/// opens.
class FetchFilterCategories
    extends UseCase<List<MaterialCategory>, NoParams> {
  const FetchFilterCategories(this._repository);
  final ProductFilterRepository _repository;

  @override
  ResultFuture<List<MaterialCategory>> call(NoParams params) =>
      _repository.getFilterCategories();
}
