import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/route_sync_repository.dart';

class GetRouteLastSyncedAt extends UseCase<DateTime?, NoParams> {
  const GetRouteLastSyncedAt(this._repository);
  final RouteSyncRepository _repository;
  @override
  ResultFuture<DateTime?> call(NoParams params) => _repository.lastSyncedAt();
}
