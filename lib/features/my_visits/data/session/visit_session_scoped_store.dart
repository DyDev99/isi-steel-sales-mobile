import 'package:isi_steel_sales_mobile/core/session/session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/active_workflow_repository.dart';

/// Drops the outgoing rep's "continue where you left off" pointer on sign-out.
///
/// [ActiveWorkflow] is a resume pointer into a route/stop the previous rep was
/// mid-way through (ADR-007). Left behind, the next rep signs in and the shell
/// offers to resume someone else's visit — and, worse, a check-in captured
/// under it would be attributed to the wrong person.
///
/// Only the pointer is cleared. Captured visit data (check-ins, stock counts,
/// photos) stays exactly where it is: it is pending sync, and discarding it on
/// sign-out would silently lose a rep's field work.
class VisitSessionScopedStore implements SessionScopedStore {
  const VisitSessionScopedStore(this._workflow);

  final ActiveWorkflowRepository _workflow;

  @override
  String get debugName => 'my_visits.active_workflow';

  @override
  Future<void> clearForSignOut() => _workflow.clearActiveWorkflow();
}
