import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart' show NoParams;
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/complete_visit_check_out.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_workflow_step.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_quotation.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/inventory_visible/inventory_completion_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/inventory_visible/inventory_visible_screen.dart';

/// Opens the guided Inventory Visibility step (stock count) for the
/// checked-in customer — the task that now sits between check-in and the
/// Quotation Builder.
///
/// The single construction path for "audit stock at this shop", so the
/// live check-in flow and the "Continue Working" resume land on the
/// identical screen with identical follow-on actions, exactly like
/// [openQuotationForCustomer] does for the quotation step.
Future<void> openInventoryVisibilityForCustomer(
  BuildContext context, {
  required String customerId,
  required String customerName,
}) async {
  // Read any judgements already recorded for this depot before building the
  // screen, so a resumed audit opens showing the work already done.
  final saved = await _readSavedAudit(customerId);
  if (!context.mounted) return;

  // `await`, not `return`: the function is now async, so returning the push
  // future directly would surface the route's own result type.
  await Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: InventoryVisibilityScreen.routeName),
    builder: (routeContext) => LocalizedBuilder(
      builder: (_) => InventoryVisibilityScreen(
        depotName: customerName,
        initialStatuses: saved,
        onProgressChanged: (progress) => _saveAudit(
          customerId: customerId,
          customerName: customerName,
          progress: progress,
        ),
        onSubmit: () => _onInventorySubmitted(
          routeContext,
          customerId: customerId,
          customerName: customerName,
        ),
      ),
    ),
  ));
}

/// Key under which a partial audit lives inside the workflow pointer's
/// `navigationArguments`.
///
/// Reusing that map rather than adding a table is deliberate. It is already
/// persisted (JSON-encoded into the active-workflow row), already scoped to the
/// current visit, and already cleared on check-out — which is exactly the
/// lifetime a half-finished stock count should have. A dedicated table would
/// need its own migration and its own cleanup, both to store something that is
/// meaningless once the visit ends.
const String _auditKey = 'stockAudit';

/// The audit is stored keyed by customer id so a pointer left over from a
/// different depot can never repopulate this one's sheet with someone else's
/// counts.
Future<Map<String, StockStatus>> _readSavedAudit(String customerId) async {
  final result = await sl<GetActiveWorkflow>()(const NoParams());
  final workflow = result.when(success: (w) => w, failure: (_) => null);
  final args = workflow?.navigationArguments;
  if (args == null) return const {};
  if (args['customerId'] != customerId) return const {};

  final raw = args[_auditKey];
  if (raw is! Map) return const {};

  final restored = <String, StockStatus>{};
  raw.forEach((key, value) {
    final match = StockStatus.values.where((s) => s.name == value);
    // Unknown values are skipped rather than defaulted: an item whose stored
    // level cannot be read must come back as *unjudged*, so the rep is asked
    // again instead of shipping a guess.
    if (match.isNotEmpty) restored['$key'] = match.first;
  });
  return restored;
}

/// Merges the audit onto the existing pointer. Fire-and-forget: a rep tapping
/// through four items must never wait on a database write, and losing the last
/// tap to a crash costs one tap.
void _saveAudit({
  required String customerId,
  required String customerName,
  required Map<String, StockStatus> progress,
}) {
  unawaited(sl<UpdateWorkflowStep>()(UpdateWorkflowStepParams(
    VisitWorkflow.stockCount,
    screen: InventoryVisibilityScreen.routeName,
    navigationArguments: {
      'customerId': customerId,
      'customerName': customerName,
      _auditKey: {
        for (final e in progress.entries) e.key: e.value.name,
      },
    },
  )));
}

/// Opens the post-audit decision screen directly.
///
/// Exists so the resume dispatcher lands on the same screen, wired the same
/// way, as the live flow does — the pattern every other step here follows. A
/// resumed visit that reached a subtly different screen is worse than one that
/// did not resume at all.
Future<void> openInventoryCompletion(
  BuildContext context, {
  required String customerId,
  required String customerName,
}) async {
  await Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: InventoryCompletionScreen.routeName),
    builder: (completionContext) => LocalizedBuilder(
      builder: (_) => InventoryCompletionScreen(
        outletName: customerName,
        onCreateQuotation: () => _createQuotation(
          completionContext,
          customerId: customerId,
          customerName: customerName,
        ),
        onEndVisit: () => _endVisit(completionContext),
      ),
    ),
  ));
}

/// Stock count logged — swap in the completion screen so the audit step
/// doesn't linger as a separate stack entry underneath the decision it led to.
void _onInventorySubmitted(
  BuildContext context, {
  required String customerId,
  required String customerName,
}) {
  // Move the resume pointer onto the completion step. Without this the audit
  // is finished but the pointer still says "audit", so leaving here and
  // tapping Continue Working sends the rep back to redo a completed count.
  unawaited(sl<UpdateWorkflowStep>()(UpdateWorkflowStepParams(
    VisitWorkflow.stockCount,
    screen: InventoryCompletionScreen.routeName,
    navigationArguments: {
      'customerId': customerId,
      'customerName': customerName,
    },
  )));

  Navigator.of(context).pushReplacement(MaterialPageRoute(
    settings: const RouteSettings(name: InventoryCompletionScreen.routeName),
    builder: (completionContext) => LocalizedBuilder(
      builder: (_) => InventoryCompletionScreen(
        outletName: customerName,
        onCreateQuotation: () => _createQuotation(
          completionContext,
          customerId: customerId,
          customerName: customerName,
        ),
        onEndVisit: () => _endVisit(completionContext),
      ),
    ),
  ));
}

/// Drops the (replaced) inventory slot first, so the Quotation Builder lands
/// directly on whatever screen sat below it — the stop review screen on a
/// live check-in, or Home on a cold resume — matching the pre-inventory
/// back-navigation shape rather than stacking on top of a screen the rep has
/// already finished with.
void _createQuotation(
  BuildContext context, {
  required String customerId,
  required String customerName,
}) {
  final navigator = Navigator.of(context);
  navigator.pop();
  openQuotationForCustomer(
    navigator.context,
    customerId: customerId,
    customerName: customerName,
  );
}

/// Completes the deferred check-out and clears the resume pointer — the same
/// usecase the Continue-Working card's own "check out" control uses — then
/// backs out of the whole guided-visit stack to wherever it started from.
void _endVisit(BuildContext context) {
  unawaited(sl<CompleteVisitCheckOut>()(const NoParams()));
  Navigator.of(context).popUntil((route) => route.isFirst);
}
