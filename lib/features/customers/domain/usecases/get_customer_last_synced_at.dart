import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_sync_repository.dart';

class GetCustomerLastSyncedAt extends UseCase<DateTime?, NoParams> {
  const GetCustomerLastSyncedAt(this._repository);
  final CustomerSyncRepository _repository;

  @override
  ResultFuture<DateTime?> call(NoParams params) => _repository.lastSyncedAt();
}
