import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_scope.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_repository.dart';

class RunDeltaSync extends UseCase<SyncResult, SyncScope> {
  const RunDeltaSync(this._repository);
  final SyncRepository _repository;

  @override
  ResultFuture<SyncResult> call(SyncScope params) =>
      _repository.runDeltaSync(params);
}
