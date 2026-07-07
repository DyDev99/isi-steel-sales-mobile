import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/interactive.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

/// Discount Card — selectable discount preset chips.
class DiscountCard extends StatelessWidget {
  const DiscountCard({super.key, required this.options, required this.onSelected});

  final List<DiscountChipViewModel> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.discount_outlined, color: Vibe.violet, size: 18),
              const SizedBox(width: 6),
              Text('revenue.discount.title'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Vibe.text, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _DiscountChip(
                  label: option.label,
                  selected: option.selected,
                  onTap: () => onSelected(option.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscountChip extends StatelessWidget {
  const _DiscountChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveScale(
      onTap: onTap,
      builder: (context, isHovered, isPressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Vibe.violet : (isHovered ? Vibe.primaryLight.withValues(alpha: 0.4) : Vibe.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected || isHovered ? Vibe.violet : Vibe.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Vibe.text,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
