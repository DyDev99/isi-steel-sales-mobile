import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_sync_repository.dart';

class RunCustomerDeltaSync extends UseCase<CustomerSyncResult, NoParams> {
  const RunCustomerDeltaSync(this._repository);
  final CustomerSyncRepository _repository;

  @override
  ResultFuture<CustomerSyncResult> call(NoParams params) =>
      _repository.runDeltaSync();
}
