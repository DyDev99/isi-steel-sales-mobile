import 'package:isi_steel_sales_mobile/core/utils/mock_latency.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sap_submit_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/quotation_sap_service.dart';

/// Deterministic mock SAP endpoint. Outcomes are keyed off the quotation id so
/// a given draft behaves consistently across retries, while the set as a whole
/// exercises every branch of the pipeline:
///   • bucket 0  → rejected (credit limit) — terminal, needs user action
///   • bucket 1  → conflict (price changed) — routes to conflict queue
///   • buckets 2-3 → transient failure until the 3rd try, then accepted
///                   (demonstrates the 5s/15s/30s backoff → success path)
///   • otherwise → accepted immediately
class MockQuotationSapService implements QuotationSapService {
  const MockQuotationSapService();

  @override
  Future<SapSubmitResult> submit(Quotation quotation,
      {required int attempt}) async {
    await MockLatency.tick(); // simulate the SAP round-trip

    if (quotation.lines.isEmpty || quotation.total <= 0) {
      return const SapRejected(
        errorCode: 'SAP_EMPTY',
        message: 'Quotation has no billable lines.',
      );
    }

    final bucket = quotation.id.hashCode.abs() % 10;
    switch (bucket) {
      case 0:
        return const SapRejected(
          errorCode: 'SAP_CREDIT_LIMIT',
          message: 'Customer credit limit exceeded.',
        );
      case 1:
        return const SapConflict(
          message: 'Price changed in SAP since this draft was created.',
          field: 'price',
        );
      case 2:
      case 3:
        // Fails the first two tries, succeeds on the third (attempt index 2).
        if (attempt < 2) {
          return const SapTransportFailure(
            message: 'SAP gateway timeout. Will retry.',
          );
        }
        return _accepted(quotation);
      default:
        return _accepted(quotation);
    }
  }

  SapAccepted _accepted(Quotation quotation) {
    final docNumber =
        'SO-${(quotation.id.hashCode.abs() % 90000000 + 10000000)}';
    return SapAccepted(
      documentNumber: docNumber,
      message: 'Sales order $docNumber created in SAP.',
      timestamp: DateTime.now(),
    );
  }
}
