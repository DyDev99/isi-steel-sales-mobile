import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/shop/shop_order_entry_screen.dart'; // Adjust path if needed

// Static fallback values used whenever real customer data is missing,
// mirroring the pattern used in StopCard.
const String _fallbackCustomerCode = 'CUS-00000';
const String _fallbackTerritory = 'Phnom Penh';
const String _fallbackChannel = 'Wholesale';
const String _fallbackTier = 'Silver'; // Fallback / mock field from customer entity

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

  /// Helper to get tier badge colors (Diamond/Gold/Silver/Bronze), same
  /// palette as StopCard so tier badges look identical across screens.
  ({Color bg, Color text}) _getTierColors(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond':
        return (bg: const Color(0xFFE0F7FA), text: const Color(0xFF006064));
      case 'gold':
        return (bg: const Color(0xFFFFF8E1), text: const Color(0xFFF57F17));
      case 'silver':
        return (bg: const Color(0xFFF5F5F5), text: const Color(0xFF616161));
      case 'bronze':
        return (bg: const Color(0xFFEFEBE9), text: const Color(0xFF4E342E));
      default:
        return (bg: const Color(0xFFF5F5F5), text: const Color(0xFF616161));
    }
  }

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

    final customerCode =
        customer.customerCode.isNotEmpty ? customer.customerCode : _fallbackCustomerCode;
    final territory =
        customer.territory.isNotEmpty ? customer.territory : _fallbackTerritory;
    final tierColors = _getTierColors(_fallbackTier);

    return Padding(
      padding: EdgeInsets.only(bottom: context.rh(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.rr(16)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.rw(16),
            vertical: context.rh(14),
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(context.rr(16)),
            border: Border.all(color: colors.border),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Customer Code, Name & Favorite Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Text(
                          // Both languages are already on the entity, so a
                          // language switch re-resolves this line on the
                          // next rebuild — no re-query, no re-sync.
                          context.localized(customer.displayName),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: context.rsp(15),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                 
                ],
              ),
              SizedBox(height: context.rh(10)),

              // Address / Territory line
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
                      territory,
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
              SizedBox(height: context.rh(10)),

              // Middle Row: Territory + Channel + Tier Tags + Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tagging Section: Territory, Wholesale/Retail, Tier
                  Expanded(
                    child: Wrap(
                      spacing: context.rw(6),
                      runSpacing: context.rh(4),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TagChip(
                          label: territory,
                          color: colors.border,
                        ),
                        _TagChip(
                          label: _fallbackChannel,
                          color: Colors.amber.shade100,
                          textColor: Colors.amber.shade900,
                        ),
                        _TagChip(
                          label: _fallbackTier,
                          color: tierColors.bg,
                          textColor: tierColors.text,
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons Section — kept as the two labeled
                  // customer actions (Create Quotation / Add HC Visit)
                  // instead of StopCard's basket/skip icon buttons.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuickActionButton(
                        icon: Icons.request_quote_rounded,
                        label: 'Quotation',
                        color: scheme.primary,
                        onTap: () => _handleCreateQuotationTap(context),
                      ),
                      SizedBox(width: context.rw(8)),
                      _QuickActionButton(
                        icon: Icons.add_location_alt_rounded,
                        label: 'HC Visit',
                        color: scheme.secondary,
                        onTap: () => _handleAddHcVisitTap(context),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color, this.textColor});
  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(4),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.rr(6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? context.appColors.textPrimary,
          fontSize: context.rsp(10.5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact icon-in-circle action button, styled like StopCard's
/// `_ActionButton`, with a short label underneath so "Create Quotation"
/// and "Add HC Visit" stay identifiable even without the old side panel.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(context.rr(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(context.rr(6)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: context.rr(20),
              color: color,
            ),
          ),
          SizedBox(height: context.rh(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.rsp(9),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}