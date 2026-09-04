import 'dart:math';

import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_out_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/active_workflow_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/route_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/check_out.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/routes_params.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_stop_status.dart';

/// Completes the deferred check-out for the rep's active visit and clears the
/// navigation state — the counterpart to the guided flow no longer checking
/// out at the end of the stock count (the stop stays "Checked In" through the
/// Quotation/Sales Order task).
///
/// Works purely off the persisted [ActiveWorkflow] row (route + stop) so it can
/// be triggered from *anywhere* — the Order feature's submit handler or an
/// explicit "Check out" control on the Continue-Working card — without a live
/// [ActiveRouteBloc] reference (that bloc is out of scope over there).
///
/// Idempotent: an already-checked-out (or vanished) stop just clears the
/// pointer and reports success, so a double-tap or a race with the bloc's own
/// check-out can't create a second `checkouts` row. Returns `true` when a visit
/// was actually completed/cleared.
class CompleteVisitCheckOut extends UseCase<bool, NoParams> {
  const CompleteVisitCheckOut(
    this._workflowRepository,
    this._routeRepository,
    this._checkOut,
    this._updateStopStatus,
  );

  final ActiveWorkflowRepository _workflowRepository;
  final RouteRepository _routeRepository;
  final CheckOut _checkOut;
  final UpdateStopStatus _updateStopStatus;

  @override
  ResultFuture<bool> call(NoParams params) async {
    final workflowResult = await _workflowRepository.getActiveWorkflow();
    final workflow =
        workflowResult.when(success: (w) => w, failure: (_) => null);
    final stopId = workflow?.currentStopId;
    if (workflow == null || stopId == null) {
      return _clearAndReturn(false);
    }

    final routeResult = await _routeRepository.getRoute(workflow.routeId);
    final route = routeResult.when(success: (r) => r, failure: (_) => null);
    RouteStop? stop;
    if (route != null) {
      for (final s in route.stops) {
        if (s.id == stopId) {
          stop = s;
          break;
        }
      }
    }
    if (stop == null) return _clearAndReturn(true);

    // Already resolved — nothing to write, just drop the pointer (idempotent).
    if (stop.status != VisitStatus.checkedIn) return _clearAndReturn(true);

    final now = DateTime.now();
    final checkOutResult = await _checkOut(_recordFor(stop, now));
    if (checkOutResult is Failed<CheckOutRecord>) {
      return Failed(checkOutResult.failure);
    }
    await _updateStopStatus(UpdateStopStatusParams(
        stopId: stop.id, status: VisitStatus.checkedOut, actualDeparture: now));
    return _clearAndReturn(true);
  }

  CheckOutRecord _recordFor(RouteStop stop, DateTime now) => CheckOutRecord(
        id: '${now.microsecondsSinceEpoch}-${Random().nextInt(99999)}',
        stopId: stop.id,
        timestamp: now,
        latitude: stop.customer.latitude,
        longitude: stop.customer.longitude,
        durationMinutes: stop.actualArrival == null
            ? 0
            : now.difference(stop.actualArrival!).inMinutes,
        visitSummary: 'Visit completed',
      );

  Future<Result<bool>> _clearAndReturn(bool completed) async {
    await _workflowRepository.clearActiveWorkflow();
    return Success(completed);
  }
}
