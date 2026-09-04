import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sap_submit_result.dart';

/// The outbound SAP boundary: pushes one quotation and reports a typed
/// [SapSubmitResult]. In production this is an OData/BAPI call; here a mock
/// stands in so the whole offline→queue→sync→resolve pipeline runs without a
/// backend. [attempt] is the 0-based try number, letting an idempotent backend
/// (or the mock) reason about retries.
abstract interface class QuotationSapService {
  Future<SapSubmitResult> submit(Quotation quotation, {required int attempt});
}
