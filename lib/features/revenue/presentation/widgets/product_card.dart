import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/interactive.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

/// A single product tile inside the Product Grid — name, price, stock and a
/// quantity stepper. Pure UI + callbacks, no bloc/data access.
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
    // HoverLift (not InteractiveScale) — the card hosts its own tap targets
    // (the +/- stepper below), so only mouse hover is handled here; taps
    // are left entirely to the stepper's own gesture detectors.
    return HoverLift(
      liftScale: 1.02,
      builder: (context, isHovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Vibe.radius),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                      color: Vibe.violet.withValues(alpha: 0.16),
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
                    color: Vibe.bgSoft,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.inventory_2_outlined,
                    color: Vibe.muted, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Vibe.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15),
              ),
              const SizedBox(height: 2),
              Text(
                viewModel.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Vibe.muted, fontSize: 10.5),
              ),
              const SizedBox(height: 4),
              Text(
                viewModel.stockLabel,
                style: TextStyle(
                  color: viewModel.inStock ? Vibe.success : Vibe.danger,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                viewModel.formattedPrice,
                style: const TextStyle(
                    color: Vibe.violet,
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
    return Row(
      children: [
        _StepperButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 0 ? onDecrement : null),
        Expanded(
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w800),
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
    final active = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: Vibe.violet.withValues(alpha: 0.12),
      splashColor: Vibe.violet.withValues(alpha: 0.16),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Vibe.primaryLight : Vibe.bgSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16, color: active ? Vibe.violet : Vibe.disabledText),
      ),
    );
  }
}
