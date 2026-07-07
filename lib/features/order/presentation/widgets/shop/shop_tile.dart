import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_status_badge.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';

/// Shop selection card for the Territory -> Shop flow. Deliberately a new,
/// lighter widget rather than reusing `CustomerCard` (shared with the live
/// Customers list) — this needs credit limit + CN/DN badge, which
/// `CustomerCard` doesn't show, and needs a disabled visual state for
/// non-active shops.
class ShopTile extends StatelessWidget {
  const ShopTile({super.key, required this.customer, required this.onTap, this.creditSummary});

  final Customer customer;
  final VoidCallback? onTap;
  final CreditSummary? creditSummary;

  bool get _isActive => customer.status == CustomerStatus.active;

  @override
  Widget build(BuildContext context) {
    final hasNotes = creditSummary?.notes.isNotEmpty ?? false;
    return Opacity(
      opacity: _isActive ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Vibe.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _isActive ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Vibe.stroke)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Vibe.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.storefront_rounded, color: Vibe.violet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(customer.shopName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 6),
                            CustomerStatusBadge(status: customer.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${customer.address}, ${customer.district}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Vibe.muted, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('\$${customer.creditLimit.toStringAsFixed(0)} limit',
                                style: const TextStyle(color: Vibe.text, fontSize: 12, fontWeight: FontWeight.w700)),
                            if (hasNotes) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Vibe.amber.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
                                child: Text('${creditSummary!.notes.length} CN/DN',
                                    style: const TextStyle(color: Vibe.amber, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isActive) const Icon(Icons.chevron_right_rounded, color: Vibe.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
