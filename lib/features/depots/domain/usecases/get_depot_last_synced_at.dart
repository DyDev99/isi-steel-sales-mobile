import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_sync_repository.dart';

class GetDepotLastSyncedAt extends UseCase<DateTime?, NoParams> {
  const GetDepotLastSyncedAt(this._repository);
  final DepotSyncRepository _repository;

  @override
  ResultFuture<DateTime?> call(NoParams params) => _repository.lastSyncedAt();
}
