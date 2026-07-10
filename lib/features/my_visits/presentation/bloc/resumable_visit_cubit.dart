import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/clear_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_resumable_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/routes_params.dart';

class ResumableVisitState extends Equatable {
  const ResumableVisitState({this.route, this.loaded = false});

  /// The in-progress route the rep can resume, or null when there's nothing to
  /// continue (never started, already finished, or dismissed).
  final RoutePlan? route;
  final bool loaded;

  bool get hasResumable => route != null;

  @override
  List<Object?> get props => [route, loaded];
}

/// The visit-flow twin of [ContinueWorkCubit]: surfaces the rep's in-progress
/// check-in (the "active workflow") so it can be resumed from the Home
/// Continue-Working section instead of the old app-launch auto-redirect.
///
/// Registered as a lazy singleton so its state survives tab switches; the shell
/// calls [refresh] whenever the Home tab is shown or a route screen is closed,
/// which is what makes "clear the old, show the new" work — [GetResumableRoute]
/// self-heals a stale/finished pointer to null, and a fresh check-in overwrites
/// it with the current route.
class ResumableVisitCubit extends Cubit<ResumableVisitState> {
  ResumableVisitCubit({
    required GetResumableRoute getResumableRoute,
    required GetRoute getRoute,
    required ClearActiveWorkflow clearActiveWorkflow,
  })  : _getResumableRoute = getResumableRoute,
        _getRoute = getRoute,
        _clearActiveWorkflow = clearActiveWorkflow,
        super(const ResumableVisitState()) {
    refresh();
  }

  final GetResumableRoute _getResumableRoute;
  final GetRoute _getRoute;
  final ClearActiveWorkflow _clearActiveWorkflow;

  bool _loading = false;

  /// Re-resolves the resumable route. Guarded against overlapping runs.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final idResult = await _getResumableRoute(const NoParams());
      final routeId = idResult.when(success: (id) => id, failure: (_) => null);
      if (routeId == null) {
        if (!isClosed) emit(const ResumableVisitState(loaded: true));
        return;
      }
      final routeResult = await _getRoute(RouteIdParams(routeId));
      final route = routeResult.when(success: (r) => r, failure: (_) => null);
      if (!isClosed) emit(ResumableVisitState(route: route, loaded: true));
    } finally {
      _loading = false;
    }
  }

  /// User chose not to continue — clears the active workflow so the card goes
  /// away and won't reappear until the next check-in.
  Future<void> dismiss() async {
    await _clearActiveWorkflow(const NoParams());
    if (!isClosed) emit(const ResumableVisitState(loaded: true));
  }
}
