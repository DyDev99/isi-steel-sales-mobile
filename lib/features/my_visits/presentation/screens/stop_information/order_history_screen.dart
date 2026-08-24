import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

enum OrderStatus { completed, inDelivery, pending, cancelled }

class SalesOrder {
  const SalesOrder({
    required this.orderId,
    required this.sapDocNum,
    required this.orderDate,
    required this.totalAmount,
    required this.itemCount,
    required this.status,
    required this.paymentTerm,
    required this.itemsSummary,
  });

  final String orderId;
  final String sapDocNum;
  final String orderDate;
  final double totalAmount;
  final int itemCount;
  final OrderStatus status;
  final String paymentTerm;
  final String itemsSummary;
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    super.key,
    this.outletName,
  });

  static const String routeName = 'order_history';
  final String? outletName;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  OrderStatus? _selectedStatusFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<SalesOrder> _orders = [
    SalesOrder(
      orderId: 'ORD-2026-8891',
      sapDocNum: '30018923',
      orderDate: '12 Aug 2026',
      totalAmount: 14250.00,
      itemCount: 4,
      status: OrderStatus.completed,
      paymentTerm: '30 Days Net',
      itemsSummary: 'ISI Wave Tile (Red) x 1,200 Sheets, Square Box Pipe x 3 Tons',
    ),
    SalesOrder(
      orderId: 'ORD-2026-8710',
      sapDocNum: '30018804',
      orderDate: '28 Jul 2026',
      totalAmount: 9800.50,
      itemCount: 2,
      status: OrderStatus.inDelivery,
      paymentTerm: 'Cash on Delivery',
      itemsSummary: 'Galvanized C-Purlin 100x50 x 500 Pcs',
    ),
    SalesOrder(
      orderId: 'ORD-2026-8540',
      sapDocNum: '30018610',
      orderDate: '15 Jul 2026',
      totalAmount: 22100.00,
      itemCount: 6,
      status: OrderStatus.completed,
      paymentTerm: '30 Days Net',
      itemsSummary: 'Deformed Bar DB12 x 15 Tons, Wire Mesh 6mm x 20 Rolls',
    ),
    SalesOrder(
      orderId: 'ORD-2026-8230',
      sapDocNum: '30018300',
      orderDate: '02 Jul 2026',
      totalAmount: 5400.00,
      itemCount: 1,
      status: OrderStatus.pending,
      paymentTerm: 'Prepayment',
      itemsSummary: 'ISI Roofing Panel Blue x 450 Sheets',
    ),
    SalesOrder(
      orderId: 'ORD-2026-7990',
      sapDocNum: '30017992',
      orderDate: '18 Jun 2026',
      totalAmount: 11000.00,
      itemCount: 3,
      status: OrderStatus.completed,
      paymentTerm: '30 Days Net',
      itemsSummary: 'H-Beam 150x150 x 10 Tons',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _buildContent);

  Widget _buildContent(BuildContext context) {
    final colors = context.appColors;

    final filteredOrders = _orders.where((o) {
      final matchesStatus = _selectedStatusFilter == null || o.status == _selectedStatusFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          o.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.sapDocNum.contains(_searchQuery) ||
          o.itemsSummary.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    final totalSpent = _orders.fold<double>(0, (sum, item) => sum + item.totalAmount);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: context.rh(56),
        iconTheme: IconThemeData(
          color: colors.textPrimary,
          size: context.rr(24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order History (SAP)',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(17),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.outletName != null) ...[
              SizedBox(height: context.rh(2)),
              Text(
                widget.outletName!,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: context.rsp(11.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentFrame(
          child: Column(
            children: [
              // Summary Banner
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.pagePadding,
                  context.rh(8),
                  context.pagePadding,
                  context.rh(12),
                ),
                child: _OrderSummaryBanner(
                  totalOrders: _orders.length,
                  totalRevenue: totalSpent,
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(13.5),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Order ID or SAP Doc No...',
                    hintStyle: TextStyle(
                      color: colors.textHint,
                      fontSize: context.rsp(13),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textSecondary,
                      size: context.rr(20),
                    ),
                    filled: true,
                    fillColor: colors.card,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: context.rh(12),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.rr(12)),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.rr(12)),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.rr(12)),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Tabs
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.pagePadding,
                  vertical: context.rh(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'All (${_orders.length})',
                        isSelected: _selectedStatusFilter == null,
                        onTap: () => setState(() => _selectedStatusFilter = null),
                      ),
                      SizedBox(width: context.rw(8)),
                      _FilterTab(
                        label: 'Completed',
                        isSelected: _selectedStatusFilter == OrderStatus.completed,
                        onTap: () => setState(() => _selectedStatusFilter = OrderStatus.completed),
                      ),
                      SizedBox(width: context.rw(8)),
                      _FilterTab(
                        label: 'In Delivery',
                        isSelected: _selectedStatusFilter == OrderStatus.inDelivery,
                        onTap: () => setState(() => _selectedStatusFilter = OrderStatus.inDelivery),
                      ),
                      SizedBox(width: context.rw(8)),
                      _FilterTab(
                        label: 'Pending',
                        isSelected: _selectedStatusFilter == OrderStatus.pending,
                        onTap: () => setState(() => _selectedStatusFilter = OrderStatus.pending),
                      ),
                    ],
                  ),
                ),
              ),

              // Orders List
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Text(
                          'No orders found',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: context.rsp(14),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          context.pagePadding,
                          context.rh(4),
                          context.pagePadding,
                          context.rh(24),
                        ),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => SizedBox(height: context.rh(12)),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _OrderCard(order: order);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryBanner extends StatelessWidget {
  const _OrderSummaryBanner({
    required this.totalOrders,
    required this.totalRevenue,
  });

  final int totalOrders;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.rr(16)),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.rr(10)),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: scheme.primary,
                    size: context.rr(22),
                  ),
                ),
                SizedBox(width: context.rw(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Orders',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: context.rsp(11.5),
                      ),
                    ),
                    SizedBox(height: context.rh(2)),
                    Text(
                      '$totalOrders Orders',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: context.rsp(15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: context.rh(32),
            width: 1,
            color: colors.border,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: context.rw(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Sales Value',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(11.5),
                    ),
                  ),
                  SizedBox(height: context.rh(2)),
                  Text(
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: context.rsp(15),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(context.rr(8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(12),
          vertical: context.rh(6),
        ),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : colors.card,
          borderRadius: BorderRadius.circular(context.rr(8)),
          border: Border.all(
            color: isSelected ? scheme.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? scheme.onPrimary : colors.textPrimary,
            fontSize: context.rsp(11.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final SalesOrder order;

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.inDelivery:
        return Colors.blue;
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.inDelivery:
        return 'IN DELIVERY';
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.rr(16)),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderId,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(14.5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.rh(2)),
                  Text(
                    'SAP DOC: ${order.sapDocNum}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(11.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rw(8),
                  vertical: context.rh(4),
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.rr(6)),
                ),
                child: Text(
                  _statusText(order.status),
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontSize: context.rsp(10.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(12)),

          // Order Items Description
          Text(
            order.itemsSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: context.rsp(12.5),
              height: 1.35,
            ),
          ),
          SizedBox(height: context.rh(12)),
          Divider(color: colors.border, height: 1),
          SizedBox(height: context.rh(12)),

          // Footer Details & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.orderDate} · ${order.paymentTerm}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(11.5),
                    ),
                  ),
                  SizedBox(height: context.rh(2)),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: context.rsp(16),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Re-ordering items from ${order.orderId}...'),
                    ),
                  );
                },
                icon: Icon(Icons.refresh_rounded, size: context.rr(16)),
                label: const Text('Re-order'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  textStyle: TextStyle(
                    fontSize: context.rsp(12.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}