import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_quotations.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_sales_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/catalog/product_filter_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/sales_order/sales_order_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/territory/territory_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/order_skeletons.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

enum _OrderStatusFilter {
  all,
  salesOrder,
  quotations,
  pendingSyncing,
  completed
}

/// Entry point into the order flow[cite: 6].
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // Live streams for quotations and sales orders[cite: 6]
  late final Stream<List<Quotation>> _quotationsStream =
      sl<WatchQuotations>()(const NoParams());
  late final Stream<List<SalesOrder>> _salesOrdersStream =
      sl<WatchSalesOrders>()(const NoParams());

  // Track active filter state[cite: 6]
  _OrderStatusFilter _selectedFilter = _OrderStatusFilter.all;

  void _openProductFilter() {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: ProductFilterScreen.routeName),
      builder: (_) => ProductFilterScreen.provider(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    // Determine screen width for responsive columns
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return PopScope(
      canPop:
          false, // Prevent default exit to handle custom tab switching[cite: 6]
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // When the system back button is pressed on the root of this tab,
        // cleanly switch back to the Home tab[cite: 6].
        sl<ShellTabController>().goTo(ShellTab.home);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Fixed Filter Toolbar Header[cite: 6]
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _FilterSegment(
                              label: 'orders.tabs.all'.tr,
                              selected:
                                  _selectedFilter == _OrderStatusFilter.all,
                              onTap: () => setState(() =>
                                  _selectedFilter = _OrderStatusFilter.all),
                            ),
                            SizedBox(width: context.rw(8)),
                            _FilterSegment(
                              label: 'orders.sales_order.title'.tr,
                              selected: _selectedFilter ==
                                  _OrderStatusFilter.salesOrder,
                              onTap: () => setState(() => _selectedFilter =
                                  _OrderStatusFilter.salesOrder),
                            ),
                            SizedBox(width: context.rw(8)),
                            _FilterSegment(
                              label: 'orders.tabs.quotations'.tr,
                              selected: _selectedFilter ==
                                  _OrderStatusFilter.quotations,
                              onTap: () => setState(() => _selectedFilter =
                                  _OrderStatusFilter.quotations),
                            ),
                            SizedBox(width: context.rw(8)),
                            _FilterSegment(
                              label: 'orders.pending_sync'.tr,
                              selected: _selectedFilter ==
                                  _OrderStatusFilter.pendingSyncing,
                              onTap: () => setState(() => _selectedFilter =
                                  _OrderStatusFilter.pendingSyncing),
                            ),
                            SizedBox(width: context.rw(8)),
                            _FilterSegment(
                              label: 'orders.status.completed'.tr,
                              selected: _selectedFilter ==
                                  _OrderStatusFilter.completed,
                              onTap: () => setState(() => _selectedFilter =
                                  _OrderStatusFilter.completed),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: context.rw(10)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Text('orders.recent'.tr,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: context.rsp(15),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rh(14)),
                    StreamBuilder<List<Quotation>>(
                      stream: _quotationsStream,
                      builder: (context, quotationSnapshot) {
                        return StreamBuilder<List<SalesOrder>>(
                          stream: _salesOrdersStream,
                          builder: (context, salesOrderSnapshot) {
                            if (quotationSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                salesOrderSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return const PendingOrdersSkeleton();
                            }
                            if (quotationSnapshot.hasError ||
                                salesOrderSnapshot.hasError) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                    child: Text('common.generic_error'.tr,
                                        style: TextStyle(
                                            color: colors.textSecondary))),
                              );
                            }

                            // Map source arrays to UI abstraction union[cite: 6]
                            var entries = <_OrderEntry>[
                              for (final q in quotationSnapshot.data ??
                                  const <Quotation>[])
                                _OrderEntry.quotation(q),
                              for (final o in salesOrderSnapshot.data ??
                                  const <SalesOrder>[])
                                _OrderEntry.salesOrder(o),
                            ]..sort((a, b) => b.date.compareTo(a.date));

                            // Filter client-side based on horizontal selector selection[cite: 6]
                            if (_selectedFilter != _OrderStatusFilter.all) {
                              entries = entries.where((entry) {
                                switch (_selectedFilter) {
                                  case _OrderStatusFilter.salesOrder:
                                    return entry.isSalesOrder;
                                  case _OrderStatusFilter.quotations:
                                    return !entry.isSalesOrder &&
                                        entry.isQuotationConverted;
                                  case _OrderStatusFilter.pendingSyncing:
                                    return !entry.isSalesOrder &&
                                        !entry.isQuotationConverted;
                                  case _OrderStatusFilter.completed:
                                    // Complete states match items cleanly synced to a backend record (e.g. Sales Orders)[cite: 6]
                                    return entry.isSalesOrder;
                                  default:
                                    return true;
                                }
                              }).toList();
                            }

                            if (entries.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                    child: Text('orders.no_orders'.tr,
                                        style: TextStyle(
                                            color: colors.textSecondary))),
                              );
                            }

                            // Replaced Column with responsive GridView for square layout
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    isTablet ? 4 : 2, // Responsive columns
                                crossAxisSpacing: context.rw(12),
                                mainAxisSpacing: context.rh(12),
                                childAspectRatio:
                                    1.0, // Strictly square proportion
                              ),
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                return _OrderTile(entry: entries[index]);
                              },
                            );
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
      ),
    );
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? scheme.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : colors.textPrimary,
            fontSize: context.rsp(12.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Lightweight display union so the dashboard can render Quotations and
/// Sales Orders in one merged, date-sorted list without a shared entity[cite: 6].
class _OrderEntry {
  _OrderEntry.quotation(Quotation q)
      : id = q.id,
        itemCount = q.lines.length,
        total = q.total,
        date = q.updatedAt,
        isSalesOrder = false,
        isQuotationConverted = q.status == QuotationStatus.converted,
        statusLabel = q.status == QuotationStatus.converted
            ? 'orders.quotation.builder_title'.tr
            : 'orders.pending_sync'.tr,
        onTap = ((context) => Navigator.of(context).push(MaterialPageRoute(
              settings:
                  const RouteSettings(name: QuotationDetailScreen.routeName),
              builder: (_) => QuotationDetailScreen(quotation: q),
            )));

  _OrderEntry.salesOrder(SalesOrder o)
      : id = o.id,
        itemCount = o.lines.length,
        total = o.total,
        date = o.createdAt,
        isSalesOrder = true,
        isQuotationConverted = false,
        statusLabel = 'orders.sales_order.title'.tr,
        onTap = ((context) => SalesOrderDetailScreen.open(context, o));

  final String id;
  final int itemCount;
  final double total;
  final DateTime date;
  final String statusLabel;
  final bool isSalesOrder;
  final bool isQuotationConverted;
  final void Function(BuildContext context)? onTap;
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.entry});
  final _OrderEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    // Determine icon and color based on whether it is a sales order or quotation
    final isSO = entry.isSalesOrder;
    final iconData = isSO ? Icons.local_mall_rounded : Icons.assignment_rounded;
    final iconColor = isSO ? scheme.primary : colors.warning;
    final iconBgColor = isSO
        ? scheme.primary.withValues(alpha: 0.1)
        : colors.warning.withValues(alpha: 0.1);

    return InkWell(
      onTap: entry.onTap == null ? null : () => entry.onTap!(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(context.rr(12)),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: colors.border.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon and Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(context.rr(8)),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: context.rr(18)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.statusLabel,
                    style: TextStyle(
                      color: colors.warning,
                      fontSize: context.rsp(10),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Middle: Items count and Date
            Text(
              'orders.items_count'
                  .tr
                  .replaceAll('{count}', '${entry.itemCount}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(13),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: context.rh(2)),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: context.rr(10), color: colors.textSecondary),
                SizedBox(width: context.rw(4)),
                Text(
                  _formatDate(entry.date),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(11),
                  ),
                ),
              ],
            ),

            SizedBox(height: context.rh(8)),
            Divider(height: 1, color: colors.divider.withValues(alpha: 0.5)),
            SizedBox(height: context.rh(8)),

            // Bottom: Total Price
            Text(
              '\$${entry.total.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.accentPurple, // Utilizing accent for modern feel
                fontSize: context.rsp(15.5),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
