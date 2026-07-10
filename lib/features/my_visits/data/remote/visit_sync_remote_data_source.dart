import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_push_batch.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_push_result.dart';

/// Push endpoint for locally-captured visit data (check-ins, check-outs,
/// stock counts, notes, photos, ...). [MockVisitSyncRemoteDataSource] is the
/// only implementation today — a real backend endpoint is a drop-in
/// replacement behind this interface, mirroring [RouteRemoteDataSource]'s
/// pull-side shape.
abstract interface class VisitSyncRemoteDataSource {
  Future<VisitPushResult> pushVisitData(VisitPushBatch batch);
}
