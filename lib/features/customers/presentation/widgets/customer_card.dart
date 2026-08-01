import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/shop/shop_order_entry_screen.dart'; // Adjust path if needed

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onCreateQuotationTap,
    this.skipOffVisitCheck = false,
    this.seedSearchTerm,
  });

  final Customer customer;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onCreateQuotationTap;
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Code & Favorite Toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (customer.customerCode.isNotEmpty)
                            Text(
                              customer.customerCode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            customer.shopName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isFavorite ? Colors.amber : colors.textSecondary,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onFavoriteToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Bottom Row: Territory / Sub-info
                if (customer.territory.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.territory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
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
      ),
    );

    // 80% Customer Card + 20% Create Quotation Layout
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 80% Width: Customer Card
          Expanded(
            flex: 8,
            child: cardContent,
          ),
          const SizedBox(width: 8),
          // 20% Width: Vertical "Create Quotation" Button
          Expanded(
            flex: 2,
            child: _CreateQuotationButton(
              onTap: () => _navigateToOrderEntry(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateQuotationButton extends StatefulWidget {
  const _CreateQuotationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CreateQuotationButton> createState() => _CreateQuotationButtonState();
}

class _CreateQuotationButtonState extends State<_CreateQuotationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.decelerate,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.request_quote_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create\nQuotation',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
