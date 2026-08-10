import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_status_badge.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Shop selection card for the Territory -> Shop flow. Deliberately a new,
/// lighter widget rather than reusing `CustomerCard` (shared with the live
/// Customers list) — this needs credit limit + CN/DN badge, which
/// `CustomerCard` doesn't show, and needs a disabled visual state for
/// non-active shops.
class ShopTile extends StatelessWidget {
  const ShopTile(
      {super.key,
      required this.customer,
      required this.onTap,
      this.creditSummary});

  final Customer customer;
  final VoidCallback? onTap;
  final CreditSummary? creditSummary;

  bool get _isActive => customer.status == CustomerStatus.active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final hasNotes = creditSummary?.notes.isNotEmpty ?? false;

    return Opacity(
      opacity: _isActive ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _isActive ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(context.rr(14)),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: context.rh(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.storefront_rounded,
                        color: colors.accentPurple),
                  ),
                  SizedBox(width: context.rw(12)),
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
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: context.rsp(14),
                                      fontWeight: FontWeight.w800)),
                            ),
                            SizedBox(width: context.rw(6)),
                            CustomerStatusBadge(status: customer.status),
                          ],
                        ),
                        SizedBox(height: context.rh(2)),
                        Text('${customer.address}, ${customer.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: context.rsp(12))),
                        SizedBox(height: context.rh(6)),
                        Row(
                          children: [
                            Text(
                                '\$${customer.creditLimit.toStringAsFixed(0)} limit',
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: context.rsp(12),
                                    fontWeight: FontWeight.w700)),
                            if (hasNotes) ...[
                              SizedBox(width: context.rw(8)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color:
                                        colors.warning.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                    '${creditSummary!.notes.length} CN/DN',
                                    style: TextStyle(
                                        color: colors.warning,
                                        fontSize: context.rsp(10),
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isActive)
                    Icon(Icons.chevron_right_rounded,
                        color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
