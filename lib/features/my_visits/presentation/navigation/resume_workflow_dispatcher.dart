import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_route_dispatch.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_stock_count_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/shop/shop_list_screen.dart';

/// Rebuilds a live screen from the args the workflow recorded. Returns `null`
/// when the required args are missing/invalid, so the dispatcher falls back to
/// the guided route resume.
typedef ResumeBuilder = Future<void>? Function(
    BuildContext context, RoutePlan route, ActiveWorkflow workflow);

/// The **single** registry mapping a persisted screen key (`routeName`) → how to
/// resume it. Adding a resumable screen is *one entry here* — the dispatcher
/// and every caller stay untouched. This is the read-side twin of the write
/// side (`ActiveRouteBloc._persistWorkflow` / `UpdateWorkflowStep`), which
/// records the matching `currentScreen` + `navigationArguments`.
final Map<String, ResumeBuilder> _navigationRegistry = {
  // Guided visit step — deep-link back to Stock Count for the checked-in stop
  // (Dispatch sits beneath; the deep link self-validates the stop).
  RouteStockCountScreen.routeName: (context, route, w) =>
      openRouteDispatch(context, route.id, resumeStopId: w.currentStopId),

  // Order handoff — re-enter the shop list for the visit's territory.
  ShopListScreen.routeName: (context, route, w) {
    final territory = w.navigationArguments?['territory'] as String?;
    if (territory == null) return null;
    return _push(context, ShopListScreen.routeName,
        ShopListScreen(territory: territory, skipOffVisitCheck: true));
  },

  // Customer profile.
  CustomerDetailScreen.routeName: (context, route, w) {
    final customerId = w.navigationArguments?['customerId'] as String?;
    if (customerId == null) return null;
    return _push(context, CustomerDetailScreen.routeName,
        CustomerDetailScreen(customerId: customerId));
  },
};

/// The canonical screen a coarse [VisitWorkflow] resumes to when no explicit
/// `currentScreen` was recorded (e.g. the Stock Count baseline written at
/// check-in).
String? _screenForWorkflow(VisitWorkflow? workflow) => switch (workflow) {
      VisitWorkflow.stockCount => RouteStockCountScreen.routeName,
      VisitWorkflow.quotation ||
      VisitWorkflow.salesOrder =>
        ShopListScreen.routeName,
      _ => null,
    };

/// The single entry point "Continue Working" calls to turn a persisted
/// [ActiveWorkflow] back into the exact screen the rep stopped on.
///
/// Resolution order: the explicit recorded `currentScreen` → the workflow's
/// canonical screen → the always-safe guided route resume (Choose Stop). Any
/// registry builder that can't rebuild (missing args) also falls back. Screen
/// validity (stop still checked in / in the route) is enforced downstream by
/// the deep link, which itself falls back to Choose Stop.
Future<void> resumeActiveWorkflow(
  BuildContext context,
  RoutePlan route,
  ActiveWorkflow? workflow,
) {
  if (workflow == null) return openRouteDispatch(context, route.id);

  final key =
      workflow.currentScreen ?? _screenForWorkflow(workflow.currentWorkflow);
  final builder = key == null ? null : _navigationRegistry[key];
  return builder?.call(context, route, workflow) ??
      openRouteDispatch(context, route.id);
}

Future<void> _push(BuildContext context, String routeName, Widget screen) {
  return Navigator.of(context).push(MaterialPageRoute(
    settings: RouteSettings(name: routeName),
    builder: (_) => LocalizedBuilder(builder: (_) => screen),
  ));
}
