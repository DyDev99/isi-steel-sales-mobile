import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/shop/shop_order_entry_screen.dart'; // Adjust path if needed
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onCreateQuotationTap,
    this.onAddHcVisitTap,
    this.skipOffVisitCheck = false,
    this.seedSearchTerm,
  });

  final Customer customer;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onCreateQuotationTap;
  final VoidCallback? onAddHcVisitTap;
  final bool skipOffVisitCheck;
  final String? seedSearchTerm;

  void _navigateToOrderEntry(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: ShopOrderEntryScreen.routeName),
      builder: (_) => ShopOrderEntryScreen(
        customer: customer,
        skipOffVisitCheck: skipOffVisitCheck,
        seedSearchTerm: seedSearchTerm,
      ),
    ));
  }

  void _handleCreateQuotationTap(BuildContext context) {
    if (onCreateQuotationTap != null) {
      onCreateQuotationTap!();
    } else {
      _navigateToOrderEntry(context);
    }
  }

  void _handleAddHcVisitTap(BuildContext context) {
    // Wire this up to the actual "add HC visit" flow once the
    // corresponding screen/use case is available.
    onAddHcVisitTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final infoSection = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(context.rr(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Customer Code & Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customer.customerCode.isNotEmpty)
                    Text(
                      customer.customerCode,
                      style: TextStyle(
                        fontSize: context.rsp(11),
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  SizedBox(height: context.rh(2)),
                  Text(
                    // Both languages are already on the entity, so a
                    // language switch re-resolves this line on the next
                    // rebuild — no re-query, no re-sync.
                    context.localized(customer.displayName),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.rh(10)),
              // Bottom Row: Territory / Sub-info
              if (customer.territory.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: context.rr(13),
                      color: colors.textSecondary,
                    ),
                    SizedBox(width: context.rw(4)),
                    Expanded(
                      child: Text(
                        customer.territory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rsp(11.5),
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    // Single unified card: info section + vertical divider +
    // stacked action buttons (Create Quotation / Add HC Visit)
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Info
            Expanded(
              flex: 7,
              child: infoSection,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colors.border,
            ),
            // Stacked action buttons
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Top: Create Quotation
                  Expanded(
                    child: _StackedActionButton(
                      icon: Icons.request_quote_rounded,
                      label: 'Create Quotation',
                      color: scheme.primary,
                      onTap: () => _handleCreateQuotationTap(context),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.border,
                  ),
                  // Bottom: Add HC Visit
                  Expanded(
                    child: _StackedActionButton(
                      icon: Icons.add_location_alt_rounded,
                      label: 'Add HC Visit',
                      color: scheme.secondary,
                      onTap: () => _handleAddHcVisitTap(context),
                    ),
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

class _StackedActionButton extends StatefulWidget {
  const _StackedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_StackedActionButton> createState() => _StackedActionButtonState();
}

class _StackedActionButtonState extends State<_StackedActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed ? color.withValues(alpha: 0.08) : Colors.transparent,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(6),
          vertical: context.rh(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: context.rr(16),
              color: color,
            ),
            SizedBox(width: context.rw(6)),
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: context.rsp(10.5),
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}