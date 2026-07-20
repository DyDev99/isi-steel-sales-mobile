import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Animated segmented control for the sales unit (Pc / Ton / Kg / Bundle).
class UnitSelector extends StatelessWidget {
  const UnitSelector({
    super.key,
    required this.units,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> units;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  static const standardUnits = ['Pc', 'Ton', 'Kg', 'Bundle'];

  factory UnitSelector.standard({
    Key? key,
    required String selected,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) =>
      UnitSelector(
        key: key,
        units: standardUnits,
        selected: selected,
        onChanged: onChanged,
        enabled: enabled,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = units.indexOf(selected).clamp(0, units.length - 1);

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHighest
              : context.appColors.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / units.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  left: selectedIndex * segmentWidth,
                  width: segmentWidth,
                  height: 38,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final unit in units)
                      Expanded(
                        child: _Segment(
                          label: unit,
                          selected: unit == selected,
                          onTap: enabled ? () => onChanged(unit) : null,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
