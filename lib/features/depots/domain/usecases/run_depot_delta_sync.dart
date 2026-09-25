import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_sync_repository.dart';

class RunDepotDeltaSync extends UseCase<DepotSyncResult, NoParams> {
  const RunDepotDeltaSync(this._repository);
  final DepotSyncRepository _repository;

  @override
  ResultFuture<DepotSyncResult> call(NoParams params) =>
      _repository.runDeltaSync();
}
