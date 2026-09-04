import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_push_summary.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_sync_repository.dart';

class PushPendingVisitData extends UseCase<VisitPushSummary, NoParams> {
  const PushPendingVisitData(this._repository);
  final VisitSyncRepository _repository;
  @override
  ResultFuture<VisitPushSummary> call(NoParams params) =>
      _repository.pushPendingVisitData();
}
