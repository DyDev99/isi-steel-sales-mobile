import 'package:isi_steel_sales_mobile/features/customers/domain/entities/master_data_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/master_data_repository.dart';

/// Forces a network re-read of one SAP master-data list and rewrites its cache.
/// Invoked only by an explicit user refresh — see [MasterDataRepository.refresh].
class RefreshMasterData {
  const RefreshMasterData(this._repository);
  final MasterDataRepository _repository;

  Future<MasterDataResult> call(MasterDataType type) =>
      _repository.refresh(type);
}
