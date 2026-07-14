import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/interactive.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

class DiscountCard extends StatelessWidget {
  const DiscountCard(
      {super.key, required this.options, required this.onSelected});

  final List<DiscountChipViewModel> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.discount_outlined, color: colors.accentPurple, size: 18), // Replaced Vibe.violet
              const SizedBox(width: 6),
              Text('revenue.discount.title'.tr,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary, // Replaced Vibe.text
                      fontSize: 13)),
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
  const _DiscountChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InteractiveScale(
      onTap: onTap,
      builder: (context, isHovered, isPressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colors.accentPurple // Replaced Vibe.violet
              : (isHovered
                  ? colors.primaryHover.withValues(alpha: 0.16) // Replaced Vibe.primaryLight
                  : colors.card), // Replaced Vibe.surface
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected || isHovered ? colors.accentPurple : colors.border), // Replaced Vibe.violet/stroke
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textPrimary, // Replaced Vibe.text
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}