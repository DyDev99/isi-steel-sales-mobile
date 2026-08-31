import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/promotion_detail_screen.dart.dart';

class PromotionSectionWidget extends StatelessWidget {
  const PromotionSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Depot Discount (On Invoice) Section
        _buildSectionHeader(
          context,
          title: 'Depot Discount (On Invoice)',
          count: 4,
          onSeeAll: () => _navigateToDetail(context, 'Depot Discount (On Invoice)'),
        ),
        SizedBox(height: context.rh(8)),
        _buildInvoiceDiscountCard(
          context,
          badgeText: 'ON INVOICE',
          discount: '2.00%',
          title: 'On-Invoice Discount – Rebar',
          status: 'Active',
          subtitle: 'Get 2.00% discount on all Rebar items on invoice.',
          dateRange: '01 Jun – 31 Aug 2025',
          depots: 'All Depots',
          category: 'Rebar',
          badgeColor: const Color(0xFFE8F5E9),
          accentColor: const Color(0xFF2E7D32),
        ),

        SizedBox(height: context.rh(16)),

        // 2. Invoice COD / Pickup Discount Section
        _buildSectionHeader(
          context,
          title: 'Invoice COD / Pickup Discount',
          count: 3,
          onSeeAll: () => _navigateToDetail(context, 'Invoice COD / Pickup Discount'),
        ),
        SizedBox(height: context.rh(8)),
        _buildInvoiceDiscountCard(
          context,
          badgeText: 'COD DISCOUNT',
          discount: '1.00%',
          title: 'COD / Pickup Discount – All Category',
          status: 'Active',
          subtitle: 'Get 1.00% discount for COD or Pickup payment.',
          dateRange: '01 Jun – 31 Aug 2025',
          depots: 'All Depots',
          category: 'All Categories',
          badgeColor: const Color(0xEFE3F2FD),
          accentColor: const Color(0xFF1565C0),
        ),

        SizedBox(height: context.rh(16)),

        // 3. Depot Promotion Requests Section
        _buildSectionHeader(
          context,
          title: 'Depot Promotion Requests',
          count: 4,
          onSeeAll: () => _navigateToDetail(context, 'Depot Promotion Requests'),
        ),
        SizedBox(height: context.rh(8)),
        SizedBox(
          height: context.rh(190),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDepotRequestCard(
                context,
                title: 'Pipe Discount\nRequest',
                category: 'PIPE',
                categoryColor: Colors.blue.shade100,
                categoryTextColor: Colors.blue.shade900,
                discount: '1.50%',
                dateRange: '01 Jun – 31 Aug 2025',
                depots: 'PP, ST, KPS Depots',
                status: 'Approved',
              ),
              _buildDepotRequestCard(
                context,
                title: 'K Pipe Discount\nRequest',
                category: 'K PIPE',
                categoryColor: Colors.blue.shade100,
                categoryTextColor: Colors.blue.shade900,
                discount: '1.50%',
                dateRange: '01 Jun – 31 Aug 2025',
                depots: 'PP, ST, KPS Depots',
                status: 'Approved',
              ),
              _buildDepotRequestCard(
                context,
                title: 'Coil Discount\nRequest',
                category: 'COIL',
                categoryColor: Colors.indigo.shade100,
                categoryTextColor: Colors.indigo.shade900,
                discount: '1.00%',
                dateRange: '01 Jun – 31 Aug 2025',
                depots: 'PP, ST, KPS Depots',
                status: 'Approved',
              ),
              _buildDepotRequestCard(
                context,
                title: 'Profile Discount\nRequest',
                category: 'PROFILE',
                categoryColor: Colors.blue.shade100,
                categoryTextColor: Colors.blue.shade900,
                discount: '2.00%',
                dateRange: '01 Jun – 31 Aug 2025',
                depots: 'PP, ST, KPS Depots',
                status: 'Approved',
              ),
            ],
          ),
        ),

        SizedBox(height: context.rh(16)),

        // 4. Camstar Promotions (Buy X Get Y) Section
        _buildSectionHeader(
          context,
          title: 'Camstar Promotions (Buy X Get Y)',
          count: 2,
          onSeeAll: () => _navigateToDetail(context, 'Camstar Promotions'),
        ),
        SizedBox(height: context.rh(8)),
        _buildBuyXGetYCard(
          context,
          buyQty: '40',
          getQty: '3',
          unit: 'BAGS',
          title: 'Camstar – Cement Promotion',
          status: 'Active',
          subtitle: 'Buy 40 bags of Camstar Cement, get 3 bags free.',
          dateRange: '01 Jun – 31 Aug 2025',
          depots: 'All Depots',
          leftBgColor: const Color(0xFFF3E5F5),
          leftTextColor: const Color(0xFF7B1FA2),
        ),
        SizedBox(height: context.rh(8)),
        _buildBuyXGetYCard(
          context,
          buyQty: '100',
          getQty: '10',
          unit: 'BAGS',
          title: 'Camstar – Cement Promotion',
          status: 'Active',
          subtitle: 'Buy 100 bags of Camstar Cement, get 10 bags free.',
          dateRange: '01 Jun – 31 Aug 2025',
          depots: 'All Depots',
          leftBgColor: const Color(0xFFFFF3E0),
          leftTextColor: const Color(0xFFE65100),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, String categoryTitle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PromotionDetailScreen(categoryTitle: categoryTitle),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.rsp(15),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See All ($count)',
            style: TextStyle(
              fontSize: context.rsp(13),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceDiscountCard(
    BuildContext context, {
    required String badgeText,
    required String discount,
    required String title,
    required String status,
    required String subtitle,
    required String dateRange,
    required String depots,
    required String category,
    required Color badgeColor,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(context.rw(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: context.rw(90),
            padding: EdgeInsets.symmetric(vertical: context.rh(12)),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: context.rsp(8),
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: context.rh(4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      discount.replaceAll('%', ''),
                      style: TextStyle(
                        fontSize: context.rsp(18),
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: context.rsp(12),
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  'DISCOUNT',
                  style: TextStyle(
                    fontSize: context.rsp(8),
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: context.rsp(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(6),
                        vertical: context.rh(2),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: context.rsp(10),
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rh(4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.rsp(12),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: context.rh(8)),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: Colors.grey.shade600),
                    SizedBox(width: context.rw(4)),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: context.rsp(11),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: context.rw(8)),
                    Icon(Icons.sell_outlined,
                        size: 12, color: Colors.grey.shade600),
                    SizedBox(width: context.rw(4)),
                    Text(
                      depots,
                      style: TextStyle(
                        fontSize: context.rsp(11),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildDepotRequestCard(
    BuildContext context, {
    required String title,
    required String category,
    required Color categoryColor,
    required Color categoryTextColor,
    required String discount,
    required String dateRange,
    required String depots,
    required String status,
  }) {
    return Container(
      width: context.rw(140),
      margin: EdgeInsets.only(right: context.rw(10)),
      padding: EdgeInsets.all(context.rw(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            style: TextStyle(
              fontSize: context.rsp(12),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.rw(6),
              vertical: context.rh(2),
            ),
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: context.rsp(9),
                fontWeight: FontWeight.bold,
                color: categoryTextColor,
              ),
            ),
          ),
          SizedBox(height: context.rh(6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                discount.replaceAll('%', ''),
                style: TextStyle(
                  fontSize: context.rsp(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              Text(
                '% DISCOUNT',
                style: TextStyle(
                  fontSize: context.rsp(9),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(6)),
          Text(
            dateRange,
            style: TextStyle(
              fontSize: context.rsp(9),
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            depots,
            style: TextStyle(
              fontSize: context.rsp(9),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: context.rh(4)),
          Text(
            status,
            style: TextStyle(
              fontSize: context.rsp(10),
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyXGetYCard(
    BuildContext context, {
    required String buyQty,
    required String getQty,
    required String unit,
    required String title,
    required String status,
    required String subtitle,
    required String dateRange,
    required String depots,
    required Color leftBgColor,
    required Color leftTextColor,
  }) {
    return Container(
      padding: EdgeInsets.all(context.rw(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: context.rw(110),
            padding: EdgeInsets.all(context.rw(8)),
            decoration: BoxDecoration(
              color: leftBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'BUY',
                      style: TextStyle(
                        fontSize: context.rsp(8),
                        color: leftTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      buyQty,
                      style: TextStyle(
                        fontSize: context.rsp(16),
                        fontWeight: FontWeight.bold,
                        color: leftTextColor,
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: context.rsp(8),
                        color: leftTextColor,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, size: 14, color: leftTextColor),
                Column(
                  children: [
                    Text(
                      'GET',
                      style: TextStyle(
                        fontSize: context.rsp(8),
                        color: leftTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      getQty,
                      style: TextStyle(
                        fontSize: context.rsp(16),
                        fontWeight: FontWeight.bold,
                        color: leftTextColor,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(3),
                        vertical: context.rh(1),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'FREE',
                        style: TextStyle(
                          fontSize: context.rsp(7),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: context.rsp(13),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(6),
                        vertical: context.rh(2),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: context.rsp(10),
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rh(4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.rsp(11),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: context.rh(6)),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: Colors.grey.shade600),
                    SizedBox(width: context.rw(4)),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: context.rsp(10),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}