import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/routes_database.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/active_workflow_model.dart';
import 'package:sqflite/sqflite.dart';

const _kActiveWorkflowId = 'active';

abstract interface class WorkflowStateLocalDataSource {
  Future<ActiveWorkflowModel?> getActiveWorkflow();
  Future<void> saveActiveWorkflow(ActiveWorkflowModel workflow);
  Future<void> clearActiveWorkflow();
}

class WorkflowStateLocalDataSourceImpl implements WorkflowStateLocalDataSource {
  const WorkflowStateLocalDataSourceImpl(this._routesDb);
  final RoutesDatabase _routesDb;
  Database get _db => _routesDb.db;

  @override
  Future<ActiveWorkflowModel?> getActiveWorkflow() async {
    try {
      final rows = await _db.query('workflow_state',
          where: 'id = ?', whereArgs: [_kActiveWorkflowId]);
      if (rows.isEmpty) return null;
      return ActiveWorkflowModel.fromRow(rows.first);
    } catch (e) {
      throw CacheException(message: 'Failed to load active workflow: $e');
    }
  }

  @override
  Future<void> saveActiveWorkflow(ActiveWorkflowModel workflow) async {
    try {
      await _db.insert('workflow_state', workflow.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save active workflow: $e');
    }
  }

  @override
  Future<void> clearActiveWorkflow() async {
    try {
      await _db.delete('workflow_state',
          where: 'id = ?', whereArgs: [_kActiveWorkflowId]);
    } catch (e) {
      throw CacheException(message: 'Failed to clear active workflow: $e');
    }
  }
}
