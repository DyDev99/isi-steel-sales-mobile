import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_status_badge.dart';

/// One row in the customer list. Swipe-right calls, swipe-left creates an
/// opportunity — the two most common next-actions get zero-navigation
/// shortcuts, per the module's UX rationale (minimal taps for field reps).
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.isFavorite,
    required this.onTap,
    required this.onCall,
    required this.onCreateOpportunity,
    required this.onFavoriteToggle,
  });

  final Customer customer;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onCreateOpportunity;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(customer.id),
      background: _swipeBackground(
          alignment: Alignment.centerLeft,
          color: Vibe.success,
          icon: Icons.call_rounded,
          label: 'customers.call'.tr),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: Vibe.violet,
        icon: Icons.trending_up_rounded,
        label: 'customers.new_opportunity_label'.tr,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onCall();
        } else {
          onCreateOpportunity();
        }
        return false;
      },
      child: GlassCard(
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
                          style: const TextStyle(
                              color: Vibe.text,
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
                    style: const TextStyle(color: Vibe.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.call_outlined,
                          size: 12, color: Vibe.muted),
                      const SizedBox(width: 4),
                      Text(customer.phone,
                          style: const TextStyle(
                              color: Vibe.muted, fontSize: 11.5)),
                      const SizedBox(width: 10),
                      const Icon(Icons.storefront_outlined,
                          size: 12, color: Vibe.muted),
                      const SizedBox(width: 4),
                      Text(
                        customer.lastOrderDate == null
                            ? 'customers.no_orders'.tr
                            : _formatDate(customer.lastOrderDate!),
                        style:
                            const TextStyle(color: Vibe.muted, fontSize: 11.5),
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
                  color: isFavorite ? Vibe.amber : Vibe.muted,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Vibe.radius)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
          ],
          Icon(icon, color: color),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
