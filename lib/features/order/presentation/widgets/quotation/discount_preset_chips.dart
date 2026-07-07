import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

const discountPresets = [0.0, 5.0, 10.0, 15.0];

/// Per-line discount preset row (0/5/10/15%) — calls straight into
/// `CartCubit.updateDiscount`, which already existed but was never wired to
/// any widget.
class DiscountPresetChips extends StatelessWidget {
  const DiscountPresetChips({super.key, required this.selected, required this.onSelected});

  final double selected;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (final preset in discountPresets)
          ChoiceChip(
            label: Text('${preset.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
            selected: selected == preset,
            visualDensity: VisualDensity.compact,
            selectedColor: Vibe.primaryLight,
            labelStyle: TextStyle(color: selected == preset ? Vibe.violet : Vibe.muted, fontWeight: FontWeight.w700),
            onSelected: (_) => onSelected(preset),
          ),
      ],
    );
  }
}
