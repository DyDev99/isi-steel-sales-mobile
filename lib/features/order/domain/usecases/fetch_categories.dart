import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/category_repository.dart';

class FetchCategories extends UseCase<List<Category>, NoParams> {
  const FetchCategories(this._repository);
  final CategoryRepository _repository;

  @override
  ResultFuture<List<Category>> call(NoParams params) => _repository.fetchAll();
}
