import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

const discountPresets = [0.0, 5.0, 10.0, 15.0];

class DiscountPresetChips extends StatelessWidget {
  const DiscountPresetChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final double selected;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Wrap(
      spacing: 6,
      children: [
        for (final preset in discountPresets)
          ChoiceChip(
            label: Text(
              '${preset.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11),
            ),
            selected: selected == preset,
            visualDensity: VisualDensity.compact,
            selectedColor: colors.surfaceSoft,
            labelStyle: TextStyle(
              color: selected == preset ? colors.accentPurple : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => onSelected(preset),
          ),
      ],
    );
  }
}