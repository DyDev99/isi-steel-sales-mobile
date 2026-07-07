import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart'; // ShellTabController, ShellTab
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_quotations.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_sales_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/territory/territory_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/order_skeletons.dart';

/// Entry point into the order flow for a general (not-lead-scoped) order.
///
/// We wrap this entire tab in a local `Navigator`. This ensures that when we
/// push Territory/Shop/Quotation/SalesOrder screens, they stay strictly
/// INSIDE this tab, keeping the MainShell's bottom nav and top bar visible!
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // We attach a key to the Nested Navigator to control it directly
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent the default app exit
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final navigator = _navigatorKey.currentState;
        if (navigator != null && navigator.canPop()) {
          // 1. If Territory, Shop, Quotation, or Sales Order are open, pop them!
          navigator.pop();
        } else {
          // 2. If we are back at the Order Dashboard root, switch MainShell back to Home
          sl<ShellTabController>().goTo(ShellTab.home);
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const _OrderDashboard(),
          );
        },
      ),
    );
  }
}

/// This is your original OrderScreen, just renamed so it can live inside
/// the Nested Navigator above.
class _OrderDashboard extends StatefulWidget {
  const _OrderDashboard();

  @override
  State<_OrderDashboard> createState() => _OrderDashboardState();
}

class _OrderDashboardState extends State<_OrderDashboard> {
  // Live streams — re-emit the moment a quotation is saved/converted or a
  // sales order is created, so this list stays current without a reload.
  late final Stream<List<Quotation>> _quotationsStream = sl<WatchQuotations>()(const NoParams());
  late final Stream<List<SalesOrder>> _salesOrdersStream = sl<WatchSalesOrders>()(const NoParams());

  void _startNewOrder() {
    // Because we are now inside the Nested Navigator, this push will NOT
    // cover the MainShell!
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: TerritoryScreen.routeName),
      builder: (_) => const TerritoryScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header — outside the ListView below, so it stays
            // pinned in place while Recent Orders scrolls underneath.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _startNewOrder,
                    icon: const Icon(Icons.storefront_rounded, color: Colors.white),
                    label: Text('orders.new_order'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Vibe.violet,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Text('orders.recent'.tr,
                      style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Quotation>>(
                    stream: _quotationsStream,
                    builder: (context, quotationSnapshot) {
                      return StreamBuilder<List<SalesOrder>>(
                        stream: _salesOrdersStream,
                        builder: (context, salesOrderSnapshot) {
                          if (quotationSnapshot.connectionState == ConnectionState.waiting &&
                              salesOrderSnapshot.connectionState == ConnectionState.waiting) {
                            return const PendingOrdersSkeleton();
                          }
                          if (quotationSnapshot.hasError || salesOrderSnapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: Text('common.generic_error'.tr, style: const TextStyle(color: Vibe.muted))),
                            );
                          }
                          final entries = <_OrderEntry>[
                            for (final q in quotationSnapshot.data ?? const <Quotation>[])
                              _OrderEntry.quotation(q),
                            for (final o in salesOrderSnapshot.data ?? const <SalesOrder>[])
                              _OrderEntry.salesOrder(o),
                          ]..sort((a, b) => b.date.compareTo(a.date));

                          if (entries.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: Text('orders.no_orders'.tr, style: const TextStyle(color: Vibe.muted))),
                            );
                          }
                          return Column(children: [for (final entry in entries) _OrderTile(entry: entry)]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight display union so the dashboard can render Quotations and
/// Sales Orders in one merged, date-sorted list without a shared entity.
class _OrderEntry {
  _OrderEntry.quotation(Quotation q)
      : id = q.id,
        itemCount = q.lines.length,
        total = q.total,
        date = q.updatedAt,
        statusLabel = q.status == QuotationStatus.converted ? 'orders.quotation.builder_title'.tr : 'orders.pending_sync'.tr,
        onTap = ((context) => Navigator.of(context).push(MaterialPageRoute(
              settings: const RouteSettings(name: QuotationDetailScreen.routeName),
              builder: (_) => QuotationDetailScreen(quotation: q),
            )));

  _OrderEntry.salesOrder(SalesOrder o)
      : id = o.id,
        itemCount = o.lines.length,
        total = o.total,
        date = o.createdAt,
        statusLabel = 'orders.sales_order.title'.tr,
        onTap = null;

  final String id;
  final int itemCount;
  final double total;
  final DateTime date;
  final String statusLabel;
  final void Function(BuildContext context)? onTap;
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.entry});
  final _OrderEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: entry.onTap == null ? null : () => entry.onTap!(context),
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('orders.items_count'.tr.replaceAll('{count}', '${entry.itemCount}'),
                        style: const TextStyle(color: Vibe.text, fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(_formatDate(entry.date), style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Vibe.amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(entry.statusLabel,
                    style: const TextStyle(color: Vibe.amber, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text('\$${entry.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Vibe.violet, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
