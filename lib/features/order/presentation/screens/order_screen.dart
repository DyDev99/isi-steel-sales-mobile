import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart'; // ShellTabController, ShellTab
import 'package:isi_steel_sales_mobile/features/order/domain/entities/pending_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_pending_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/catalog_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/order_skeletons.dart';

/// Entry point into the product catalog for a general (not-lead-scoped) order.
///
/// We wrap this entire tab in a local `Navigator`. This ensures that when we
/// push the CatalogScreen, ProductDetailScreen, or CartScreen, they stay
/// strictly INSIDE this tab, keeping the MainShell's bottom nav and top bar visible!
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
          // 1. If Catalog, Detail, or Cart are open, pop them!
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
  // Live pending-orders stream — re-emits the moment a checkout writes a new
  // order, so this list stays current without any manual reload.
  late final Stream<List<PendingOrder>> _ordersStream = sl<WatchPendingOrders>()(const NoParams());

  void _openCatalog() {
    // Because we are now inside the Nested Navigator, this push will NOT
    // cover the MainShell!
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          // Deferred fetch: keep the CatalogBloc idle (no CatalogLoadRequested)
          // so entering the catalog is instant — it only queries once the user
          // searches by text/voice/scan/photo or picks a category.
          BlocProvider(create: (_) => sl<CatalogBloc>()),
          BlocProvider(create: (_) => sl<CartCubit>()..load()),
          BlocProvider(create: (_) => sl<SyncCubit>()),
        ],
        child: LocalizedBuilder(builder: (_) => const CatalogScreen()),
      ),
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
                    onPressed: _openCatalog,
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
                  StreamBuilder<List<PendingOrder>>(
                    stream: _ordersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const PendingOrdersSkeleton();
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('common.generic_error'.tr, style: const TextStyle(color: Vibe.muted))),
                        );
                      } else {
                        final orders = snapshot.data ?? const <PendingOrder>[];
                        if (orders.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: Text('orders.no_orders'.tr, style: const TextStyle(color: Vibe.muted))),
                          );
                        }
                        return Column(children: [for (final order in orders) _OrderTile(order: order)]);
                      }
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

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final PendingOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('orders.items_count'.tr.replaceAll('{count}', '${order.items.length}'),
                      style: const TextStyle(color: Vibe.text, fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(_formatDate(order.createdAt), style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Vibe.amber.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('orders.pending_sync'.tr,
                  style: const TextStyle(color: Vibe.amber, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Text('\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(color: Vibe.violet, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}