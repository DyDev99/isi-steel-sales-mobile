import 'package:isi_steel_sales_mobile/core/api_client/api_service/sap_api_service.dart';
import 'package:isi_steel_sales_mobile/core/config/app_config.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/master_data_item.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/master_data_type.dart';

/// The real SAP Customer Helper implementation — replaces the mock that stood
/// in while the SAP gateway was a stub (the seam ADR-009 decision 4 reserved).
///
/// All nine endpoints share one shape: `GET /api/CustHelper/{Action}/{conId}`
/// answering a JSON array whose rows hold exactly one code/name pair under
/// per-endpoint field names — `salesOrg`/`salesOrgName`,
/// `paymentTerm`/`paymentTermName`, and so on (technical document §4.1).
///
/// Rather than maintaining nine field-name tables, [_toItem] reads each row
/// **structurally**: the string field whose key ends in `name` is the name, and
/// the other string field is the code. This also absorbs the casing question —
/// the live `GetPaging` capture proved this façade serialises PascalCase where
/// the document shows camelCase, and a structural read is indifferent to both.
class SapMasterDataRemoteDataSource implements MasterDataRemoteDataSource {
  const SapMasterDataRemoteDataSource(this._api, {String? conId})
      : _overrideConId = conId;

  final SapApiService _api;
  final String? _overrideConId;

  String get _conId => _overrideConId ?? SapConfig.conId;

  @override
  Future<List<MasterDataItem>> fetch(MasterDataType type) async {
    final response = await _api.get<Object?>(
      '/api/CustHelper/${type.action}/$_conId',
      // §4.4: a 404 here means SAP returned zero rows — an empty dropdown, not
      // a fault.
      allowEmpty: true,
    );

    final body = response.data;
    if (body is! List) return const [];

    return body
        .whereType<Map>()
        .map(_toItem)
        .whereType<MasterDataItem>()
        .toList(growable: false);
  }

  /// Structural code/name extraction; returns null for a row with no usable
  /// code so one malformed row cannot break a dropdown.
  static MasterDataItem? _toItem(Map<dynamic, dynamic> row) {
    String? code;
    String? name;

    for (final entry in row.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! String) continue;

      final trimmed = value.trim();
      if (key.toLowerCase().endsWith('name')) {
        // First name-suffixed key wins; §4.1 rows carry exactly one.
        name ??= trimmed;
      } else {
        code ??= trimmed;
      }
    }

    if (code == null || code.isEmpty) return null;
    return MasterDataItem(code: code, name: name ?? '');
  }
}
