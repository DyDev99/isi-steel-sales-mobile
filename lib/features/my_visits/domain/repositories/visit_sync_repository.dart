import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_push_summary.dart';

abstract interface class VisitSyncRepository {
  /// Pushes every locally-pending visit-capture row (check-ins, check-outs,
  /// stock counts, notes, photos, ...) and marks accepted rows synced.
  /// Short-circuits to a zero-count success if nothing is pending.
  ResultFuture<VisitPushSummary> pushPendingVisitData();
}
