import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_option.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/filter_flow_transition.dart';

/// The family step (Palm 50 / Palm 70 / Palm 100), rendered as rows rather than
/// chips.
///
/// Families are the level a rep thinks in and the level with the longest names,
/// so they get a full-width row with its SKU count and an affordance that reads
/// as "drill in" — visually distinct from the specification steps that follow,
/// which are terse values.
class ProductFamilySelector extends StatelessWidget {
  const ProductFamilySelector({
    super.key,
    required this.options,
    required this.onSelect,
    this.selectedValue,
    this.countLabelBuilder,
  });

  final List<FilterOption> options;
  final ValueChanged<FilterOption> onSelect;
  final String? selectedValue;

  /// Localised "{count} items" formatter. Kept injectable so this widget stays
  /// free of a localisation dependency and remains trivially golden-testable.
  final String Function(int count)? countLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++)
          FilterFlowStaggeredItem(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FamilyRow(
                option: options[i],
                selected: options[i].value == selectedValue,
                countLabel: countLabelBuilder?.call(options[i].matchCount),
                onTap: () => onSelect(options[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _FamilyRow extends StatelessWidget {
  const _FamilyRow({
    required this.option,
    required this.selected,
    required this.countLabel,
    required this.onTap,
  });

  final FilterOption option;
  final bool selected;
  final String? countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: FilterFlowTransition.duration,
      curve: FilterFlowTransition.curve,
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? scheme.primary : colors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? scheme.primary : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (countLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          countLabel!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  size: selected ? 20 : 22,
                  color: selected ? scheme.primary : colors.iconMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
