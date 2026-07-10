import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/mock_latency.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_push_batch.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_push_result.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_sync_remote_data_source.dart';

/// Simulates a backend that accepts every pushed row — stands in for the
/// eventual real push endpoint, exactly as [MockRouteRemoteDataSource]
/// stands in for a real pull endpoint.
class MockVisitSyncRemoteDataSource implements VisitSyncRemoteDataSource {
  const MockVisitSyncRemoteDataSource();

  @override
  Future<VisitPushResult> pushVisitData(VisitPushBatch batch) async {
    try {
      await MockLatency.tick();
      final ids = batch.idsByTable().values.expand((ids) => ids).toList();
      return VisitPushResult(
          acceptedIds: ids, rejectedIds: const [], syncedAt: DateTime.now());
    } catch (e) {
      throw ServerException(message: 'Visit push sync failed: $e');
    }
  }
}
