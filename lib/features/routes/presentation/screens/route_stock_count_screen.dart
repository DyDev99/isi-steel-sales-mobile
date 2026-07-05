import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/catalog_screen.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_stock_update.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/screens/route_dispatch_screen.dart';

/// Step 4 of the guided field flow — Market Intelligence Inventory Count
/// (សុេីបការ). A rapid, high-density on-shelf counter: one stepper row per SKU
/// (tap ±1, long-press to fly by 10), an insight banner flagging anything
/// that's out of stock as a quotation opportunity, and a dual-action
/// "Done · Build Quotation" CTA that records the counts, checks the stop out,
/// and hands off to the order catalog to quote what the shop is missing.
class RouteStockCountScreen extends StatefulWidget {
  const RouteStockCountScreen({super.key});

  @override
  State<RouteStockCountScreen> createState() => _RouteStockCountScreenState();
}

class _RouteStockCountScreenState extends State<RouteStockCountScreen> {
  // Standard market-survey template — the SKUs a rep sweeps every shop for.
  final List<_ShelfItem> _items = [
    _ShelfItem('Rebar 12 mm', 42),
    _ShelfItem('Channel 100', 0),
    _ShelfItem('GI sheet 0.8', 120),
    _ShelfItem('Rebar 16 mm', 18),
    _ShelfItem('Angle Bar 50', 7),
  ];

  bool _submitting = false;

  List<String> get _outOfStock => [for (final i in _items) if (i.count == 0) i.name];

  void _step(_ShelfItem item, double delta) {
    setState(() => item.count = (item.count + delta).clamp(0, 99999));
  }

  Future<void> _doneAndQuote(BuildContext context, RouteStop stop) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    final navigator = Navigator.of(context);
    final visit = context.read<VisitCubit>();
    final activeRoute = context.read<ActiveRouteBloc>();

    // 1. Persist every shelf count as a stock update (offline-safe).
    for (final item in _items) {
      visit.addStockUpdate(VisitStockUpdate(
        id: '${DateTime.now().microsecondsSinceEpoch}-${item.name.hashCode}',
        stopId: stop.id,
        productId: item.name,
        productName: item.name,
        countedQuantity: item.count,
        notes: item.count == 0 ? 'Out of stock — quotation opportunity' : '',
      ));
    }

    // 2. Complete the visit.
    activeRoute.add(const CheckOutRequested('Shelf count completed'));

    // 3. Return to Dispatch, then open the catalog to quote the first gap.
    final seed = _outOfStock.isNotEmpty ? _outOfStock.first : null;
    navigator.popUntil((r) => r.settings.name == RouteDispatchScreen.routeName);
    navigator.push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) {
              final bloc = sl<CatalogBloc>();
              if (seed != null) bloc.add(CatalogSearchChanged(seed));
              return bloc;
            },
          ),
          BlocProvider(create: (_) => sl<CartCubit>()..load()),
          BlocProvider(create: (_) => sl<SyncCubit>()),
        ],
        child: LocalizedBuilder(builder: (_) => const CatalogScreen()),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: Text('routes.flow.shelf_count_title'.tr,
            style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
        builder: (context, state) {
          if (state is! ActiveRouteReady || !state.hasCurrentStop) {
            return Center(child: Text('routes.flow.no_stop'.tr, style: const TextStyle(color: Vibe.muted)));
          }
          final stop = state.route.stops[state.currentStopIndex];
          final outOfStock = _outOfStock;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
                    Text(stop.customer.name,
                        style: const TextStyle(color: Vibe.text, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('routes.flow.shelf_count_subtitle'.tr,
                        style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
                    const SizedBox(height: 14),
                    if (outOfStock.isNotEmpty) ...[
                      _InsightBanner(outOfStock: outOfStock),
                      const SizedBox(height: 14),
                    ],
                    for (final item in _items)
                      _ShelfRow(
                        item: item,
                        onStep: (delta) => _step(item, delta),
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
  _ShelfItem(this.name, this.count);
  final String name;
  double count;
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.outOfStock});
  final List<String> outOfStock;

  @override
  Widget build(BuildContext context) {
    final names = outOfStock.join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Vibe.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Vibe.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Vibe.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'routes.flow.stock_insight'.tr.replaceAll('{names}', names),
              style: const TextStyle(color: Vibe.amber, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.item, required this.onStep});
  final _ShelfItem item;
  final void Function(double delta) onStep;

  @override
  Widget build(BuildContext context) {
    final isOut = item.count == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isOut ? Vibe.amber.withValues(alpha: 0.5) : Vibe.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    isOut
                        ? '${'routes.flow.on_shelf'.tr} · ${'routes.flow.out_of_stock'.tr}'
                        : 'routes.flow.on_shelf'.tr,
                    style: TextStyle(color: isOut ? Vibe.amber : Vibe.muted, fontSize: 11)),
              ],
            ),
          ),
          _StepButton(icon: Icons.remove_rounded, sign: -1, onDelta: onStep),
          Container(
            width: 46,
            alignment: Alignment.center,
            child: Text(item.count.toStringAsFixed(0),
                style: const TextStyle(color: Vibe.text, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          _StepButton(icon: Icons.add_rounded, sign: 1, onDelta: onStep),
        ],
      ),
    );
  }
}

/// Large hit-target stepper button. Tap = ±1, long-press = repeat ±10 while held
/// so a rep can rack up big counts without hundreds of taps.
class _StepButton extends StatefulWidget {
  const _StepButton({required this.icon, required this.sign, required this.onDelta});
  final IconData icon;
  final double sign;
  final void Function(double delta) onDelta;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;

  void _startHold() {
    HapticFeedback.selectionClick();
    widget.onDelta(widget.sign * 10);
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      HapticFeedback.selectionClick();
      widget.onDelta(widget.sign * 10);
    });
  }

  void _endHold() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onDelta(widget.sign),
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _endHold(),
      onLongPressCancel: _endHold,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vibe.violet.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(widget.icon, color: Vibe.violet, size: 24),
      ),
    );
  }
}

class _StockCountBar extends StatelessWidget {
  const _StockCountBar({required this.submitting, required this.onBack, required this.onDone});
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Vibe.bg,
        border: Border(top: BorderSide(color: Vibe.stroke)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            TextButton(
              onPressed: submitting ? null : onBack,
              child: Text('routes.flow.back'.tr,
                  style: const TextStyle(color: Vibe.muted, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: submitting ? null : onDone,
                icon: submitting
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.request_quote_rounded, size: 20),
                label: Text('routes.flow.done_build_quote'.tr,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Vibe.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
