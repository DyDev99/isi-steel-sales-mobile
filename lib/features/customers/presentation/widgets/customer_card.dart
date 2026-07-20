import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_status_badge.dart';

/// One row in the customer list. 
/// Swipe functionalities have been disabled, returning a clean GlassCard.
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    // Note: onCall and onCreateOpportunity can be removed from parameters 
    // if they are no longer needed anywhere else in the parent widget.
  });

  final Customer customer;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CustomerStatusBadge(status: customer.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${customer.customerCode} · ${customer.ownerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.call_outlined,
                        size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(customer.phone,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 11.5)),
                    const SizedBox(width: 10),
                    Icon(Icons.storefront_outlined,
                        size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      customer.lastOrderDate == null
                          ? 'customers.no_orders'.tr
                          : _formatDate(customer.lastOrderDate!),
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onFavoriteToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? colors.warning : colors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}