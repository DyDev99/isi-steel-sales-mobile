import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/complete_visit_check_out.dart';
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
}) {
  return Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: InventoryVisibilityScreen.routeName),
    builder: (routeContext) => LocalizedBuilder(
      builder: (_) => InventoryVisibilityScreen(
        depotName: customerName,
        onSubmit: () => _onInventorySubmitted(
          routeContext,
          customerId: customerId,
          customerName: customerName,
        ),
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
  Navigator.of(context).pushReplacement(MaterialPageRoute(
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
