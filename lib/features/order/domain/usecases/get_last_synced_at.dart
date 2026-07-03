import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_repository.dart';

class GetLastSyncedAt extends UseCase<DateTime?, NoParams> {
  const GetLastSyncedAt(this._repository);
  final SyncRepository _repository;

  @override
  ResultFuture<DateTime?> call(NoParams params) => _repository.lastSyncedAt();
}
