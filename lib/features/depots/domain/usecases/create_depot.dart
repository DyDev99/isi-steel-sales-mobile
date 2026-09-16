import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_draft.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_sync_repository.dart';

/// Registers a shop the rep visited.
///
/// Goes through [DepotSyncRepository] rather than `DepotRepository`
/// because it writes: reads are local-only, and the sync repository is the one
/// door to the network. The created depot lands in `Draft` and cannot trade
/// until someone holding `depots.approve` activates it.
class CreateDepot extends UseCase<Depot, DepotDraft> {
  const CreateDepot(this._repository);

  final DepotSyncRepository _repository;

  @override
  ResultFuture<Depot> call(DepotDraft params) =>
      _repository.createDepot(params);
}
