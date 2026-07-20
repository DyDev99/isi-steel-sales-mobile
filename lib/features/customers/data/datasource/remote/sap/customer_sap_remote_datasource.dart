import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/dto/sap_business_partner.dart';

/// The SAP customer master, as seen from the mobile app.
///
/// Scope is deliberately narrow: **business-partner data only**. Authentication
/// beyond SAP's own JWT, user profiles, notifications, preferences and analytics
/// belong to `CustomerRemoteDataSource` (the ISI backend) and must never be
/// added here.
///
/// Implementations are called exclusively by the sync repository, preserving the
/// existing invariant that a `Customer` row can only ever come into existence
/// from SAP.
abstract interface class CustomerSapRemoteDataSource {
  /// `GET /api/Customer/Read/{conId}/{id}` — one full BP record.
  ///
  /// Returns null when SAP holds no such customer (HTTP 404 with a "not found"
  /// message), which is an absence rather than a fault.
  Future<SapBusinessPartner?> read(String customerNumber);

  /// `GET /api/Customer/GetPaging/{conId}` — server-side paged BP rows.
  ///
  /// [page] is **1-based**, matching SAP. [pageSize] should stay at or below 50
  /// per the technical document's guidance (§6.4).
  Future<SapCustomerPage> fetchPage({
    required int page,
    required int pageSize,
    String? salesOrg,
    String? division,
    String? nameFilter,
  });

  /// `GET /api/Customer/GetDetail/{conId}` — unpaged filtered rows.
  ///
  /// Kept for targeted lookups. Prefer [fetchPage] for anything list-shaped;
  /// the document warns that `GetDetail` is the slow path on large result sets.
  Future<List<SapBusinessPartner>> fetchDetail({
    String? customerNumber,
    String? salesOrg,
    String? division,
    String? nameFilter,
  });
}
