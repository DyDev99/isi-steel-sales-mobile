import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_code_lookup.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_sync_repository.dart';

/// Resolves a depot number that is not in the rep's local book.
///
/// The one depot read that is allowed to leave the device, and only on an
/// explicit full-code lookup — a number the rep typed or scanned. The browse
/// and search paths stay local by design.
class LookupDepotByCode extends UseCase<DepotCodeLookup, String> {
  const LookupDepotByCode(this._repository);
  final DepotSyncRepository _repository;

  @override
  ResultFuture<DepotCodeLookup> call(String code) =>
      _repository.lookupByCode(code);
}
