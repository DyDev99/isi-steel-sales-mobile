import 'package:isi_steel_sales_mobile/features/customers/domain/entities/master_data_item.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/master_data_type.dart';

/// The SAP Customer Helper API (`/api/CustHelper/*`) as seen from the app.
///
/// The seam ADR-009 decision 4 reserved. It played out exactly as designed: a
/// mock held this boundary while the SAP gateway was a stub, and when the
/// gateway landed the real `SapMasterDataRemoteDataSource`
/// (`data/datasource/remote/sap/`) replaced it with no change above this line.
/// The mock is deleted.
///
/// Implementations surface transport problems as the networking layer's
/// `ApiException`s — never a raw `DioException` — and the repository translates
/// those into domain `Failure`s, so presentation never sees transport detail.
abstract interface class MasterDataRemoteDataSource {
  /// Fetches every row for [type]. A SAP 404 means "zero rows", not a server
  /// fault (see the API document §4.4), and must surface as an empty list.
  Future<List<MasterDataItem>> fetch(MasterDataType type);
}
