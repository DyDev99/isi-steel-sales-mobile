import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/interactive.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.viewModel,
    required this.onIncrement,
    required this.onDecrement,
  });

  final ProductViewModel viewModel;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final errorColor = Theme.of(context).colorScheme.error;

    return HoverLift(
      liftScale: 1.02,
      builder: (context, isHovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // Native radius value or Theme based
          boxShadow: isHovered
              ? [
                  BoxShadow(
                      color: colors.accentPurple.withValues(alpha: 0.16), // Replaced Vibe.violet
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]
              : const [],
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: colors.surfaceSoft, // Replaced Vibe.bgSoft
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(Icons.inventory_2_outlined,
                    color: colors.textSecondary, size: 28), // Replaced Vibe.muted
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: colors.textPrimary, // Replaced Vibe.text
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15),
              ),
              const SizedBox(height: 2),
              Text(
                viewModel.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 10.5), // Replaced Vibe.muted
              ),
              const SizedBox(height: 4),
              Text(
                viewModel.stockLabel,
                style: TextStyle(
                  color: viewModel.inStock ? colors.success : errorColor, // Replaced Vibe.success/danger
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                viewModel.formattedPrice,
                style: TextStyle(
                    color: colors.accentPurple, // Replaced Vibe.violet
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _QuantityStepper(
                quantity: viewModel.quantityInCart,
                enabled: viewModel.inStock,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.enabled,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        _StepperButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 0 ? onDecrement : null),
        Expanded(
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800), // Replaced Vibe.text
          ),
        ),
        _StepperButton(
            icon: Icons.add_rounded, onTap: enabled ? onIncrement : null),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final active = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: colors.accentPurple.withValues(alpha: 0.12), // Replaced Vibe.violet
      splashColor: colors.accentPurple.withValues(alpha: 0.16), // Replaced Vibe.violet
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colors.primaryHover.withValues(alpha: 0.16) : colors.surfaceSoft, // Replaced Vibe.primaryLight/bgSoft
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16, color: active ? colors.accentPurple : colors.textDisabled), // Replaced Vibe.violet/disabledText
      ),
    );
  }
}