import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_sync_scope.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_sync_repository.dart';

class RunRouteInitialSync extends UseCase<RouteSyncResult, RouteSyncScope> {
  const RunRouteInitialSync(this._repository);
  final RouteSyncRepository _repository;
  @override
  ResultFuture<RouteSyncResult> call(RouteSyncScope params) => _repository.runInitialSync(params);
}
