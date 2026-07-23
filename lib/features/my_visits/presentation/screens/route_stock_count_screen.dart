import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/shop/shop_list_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/stock_level.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_stock_update.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_workflow_step.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_dispatch_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stock_level_selector.dart';

/// Step 4 of the guided field flow — Market Intelligence Inventory Check
/// (សុេីបការ). A rapid on-shelf status sweep: one Low / Medium / High
/// selector per SKU (no counting, no steppers), an insight banner flagging
/// anything low as a quotation opportunity, and a dual-action
/// "Done · Build Quotation" CTA that records the statuses and hands off to
/// the order catalog to quote what the shop is running out of. Completion is
/// blocked until every SKU has exactly one status.
class RouteStockCountScreen extends StatefulWidget {
  const RouteStockCountScreen({super.key});

  /// Stable resume-target key persisted on [ActiveWorkflow.currentScreen] and
  /// mapped back by the resume dispatcher. Matches [VisitWorkflow.stockCount].
  static const String routeName = 'route_stock_count';

  @override
  State<RouteStockCountScreen> createState() => _RouteStockCountScreenState();
}

class _RouteStockCountScreenState extends State<RouteStockCountScreen> {
  // Standard market-survey template — the SKUs a rep sweeps every shop for.
  final List<_ShelfItem> _items = [
    _ShelfItem('Rebar 12 mm'),
    _ShelfItem('Channel 100'),
    _ShelfItem('GI sheet 0.8'),
    _ShelfItem('Rebar 16 mm'),
    _ShelfItem('Angle Bar 50'),
  ];

  bool _submitting = false;
  bool _showValidation = false;

  bool get _allSet => _items.every((i) => i.level != null);

  List<String> get _lowStock => [
        for (final i in _items)
          if (i.level == StockLevel.low) i.name
      ];

  void _select(_ShelfItem item, StockLevel level) {
    setState(() => item.level = level);
  }

  Future<void> _doneAndQuote(BuildContext context, RouteStop stop) async {
    if (_submitting) return;
    if (!_allSet) {
      // Refuse to complete while any SKU is unset; highlight the gaps.
      setState(() => _showValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('my_visits.stock_level.select_all'.tr)));
      return;
    }
    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    final navigator = Navigator.of(context);
    final visit = context.read<VisitCubit>();

    // 1. Persist every shelf status as a stock update (offline-safe).
    for (final item in _items) {
      visit.addStockUpdate(VisitStockUpdate(
        id: '${DateTime.now().microsecondsSinceEpoch}-${item.name.hashCode}',
        stopId: stop.id,
        productId: item.name,
        productName: item.name,
        stockLevel: item.level!,
        notes: item.level == StockLevel.low
            ? 'my_visits.stop.low_stock_opportunity'.tr
            : '',
      ));
    }

    // 2. Advance the *navigation state* to the Quotation task WITHOUT checking
    // out. Check-out is now deferred until the rep is done (explicit "Check out"
    // on the Continue-Working card / CompleteVisitCheckOut), so the stop stays
    // "Checked In" and "Continue Working" resumes straight into the order flow
    // for this shop — the exact screen the rep stopped on. The recorded
    // navigation args let the resume dispatcher rebuild the Shop list.
    unawaited(sl<UpdateWorkflowStep>()(UpdateWorkflowStepParams(
      VisitWorkflow.quotation,
      screen: ShopListScreen.routeName,
      navigationArguments: {
        'territory': stop.customer.territory,
        'customerId': stop.customer.id,
      },
    )));

    // 3. Return to Dispatch, then hand off to the Shop list — pre-filtered
    // to this stop's territory (the one reliable join between my_visits'
    // and customers' mock datasets), skipping both Territory-picking and
    // the off-visit reason gate since the rep is provably on-visit already.
    final seed = _lowStock.isNotEmpty ? _lowStock.first : null;
    navigator.popUntil((r) => r.settings.name == RouteDispatchScreen.routeName);
    navigator.push(MaterialPageRoute(
      settings: const RouteSettings(name: ShopListScreen.routeName),
      builder: (_) => ShopListScreen(
        territory: stop.customer.territory,
        skipOffVisitCheck: true,
        seedSearchTerm: seed,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('my_visits.flow.shelf_count_title'.tr,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
        builder: (context, state) {
          if (state is! ActiveRouteReady || !state.hasCurrentStop) {
            return Center(
                child: Text('my_visits.flow.no_stop'.tr,
                    style: TextStyle(color: colors.textSecondary)));
          }
          final stop = state.route.stops[state.currentStopIndex];
          final lowStock = _lowStock;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
                    Text(stop.customer.name,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('my_visits.flow.shelf_count_subtitle'.tr,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 14),
                    if (lowStock.isNotEmpty) ...[
                      _InsightBanner(lowStock: lowStock),
                      const SizedBox(height: 14),
                    ],
                    for (final item in _items)
                      StockLevelRow(
                        key: ValueKey(item.name),
                        name: item.name,
                        subtitle: 'my_visits.flow.on_shelf'.tr,
                        level: item.level,
                        showMissingHighlight: _showValidation,
                        onLevelSelected: (level) => _select(item, level),
                      ),
                  ],
                ),
              ),
              _StockCountBar(
                submitting: _submitting,
                onBack: () => Navigator.of(context).pop(),
                onDone: () => _doneAndQuote(context, stop),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShelfItem {
  _ShelfItem(this.name);
  final String name;
  StockLevel? level;
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.lowStock});
  final List<String> lowStock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final names = lowStock.join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: colors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'my_visits.flow.stock_insight'.tr.replaceAll('{names}', names),
              style: TextStyle(
                  color: colors.warning,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCountBar extends StatelessWidget {
  const _StockCountBar(
      {required this.submitting, required this.onBack, required this.onDone});
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            TextButton(
              onPressed: submitting ? null : onBack,
              child: Text('my_visits.flow.back'.tr,
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: submitting ? null : onDone,
                icon: submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: scheme.onPrimary))
                    : const Icon(Icons.request_quote_rounded, size: 20),
                label: Text('my_visits.flow.done_build_quote'.tr,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
