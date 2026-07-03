import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/pending_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_pending_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/catalog_screen.dart';

/// Entry point into the product catalog for a general (not-lead-scoped) order.
/// 
/// We wrap this entire tab in a local `Navigator`. This ensures that when we 
/// push the CatalogScreen, ProductDetailScreen, or CartScreen, they stay 
/// strictly INSIDE this tab, keeping the MainShell's bottom nav and top bar visible!
// Update your OrderScreen class in order_screen.dart

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
          // 2. If we are back at the Order Dashboard root, let the main app handle the back press
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
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
  late Future<List<PendingOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<PendingOrder>> _loadOrders() async {
    final result = await sl<FetchPendingOrders>()(const NoParams());
    return result.when(success: (o) => o, failure: (_) => const []);
  }

  void _openCatalog() {
    // Because we are now inside the Nested Navigator, this push will NOT 
    // cover the MainShell!
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<CatalogBloc>()..add(const CatalogLoadRequested())),
          BlocProvider(create: (_) => sl<CartCubit>()..load()),
          BlocProvider(create: (_) => sl<SyncCubit>()),
        ],
        child: const CatalogScreen(),
      ),
    )).then((_) => setState(() => _ordersFuture = _loadOrders()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            const Text('Orders', style: TextStyle(color: Vibe.text, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Browse the product catalog and place offline orders.',
                style: TextStyle(color: Vibe.muted, fontSize: 12.5)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCatalog,
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Vibe.violet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Orders', style: TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            FutureBuilder<List<PendingOrder>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                final orders = snapshot.data ?? const [];
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: Vibe.violet)),
                  );
                }
                if (orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No orders yet', style: TextStyle(color: Vibe.muted))),
                  );
                }
                return Column(
                  children: [for (final order in orders) _OrderTile(order: order)],
                );
              },
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
                  Text('${order.items.length} item${order.items.length == 1 ? '' : 's'}',
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
              child: const Text('Pending Sync', style: TextStyle(color: Vibe.amber, fontSize: 10.5, fontWeight: FontWeight.w700)),
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