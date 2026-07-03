import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_repository.dart';

class FetchTodayRoutes extends UseCase<List<RoutePlan>, NoParams> {
  const FetchTodayRoutes(this._repository);
  final RouteRepository _repository;
  @override
  ResultFuture<List<RoutePlan>> call(NoParams params) => _repository.fetchTodayRoutes();
}
