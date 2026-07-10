import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Animated segmented control for the sales unit (Pc / Ton / Kg / Bundle).
///
/// Purely presentational: it owns no state, takes the [selected] value and
/// reports changes via [onChanged], so it can be driven equally by a Cubit,
/// a `StatefulWidget`, or restored persisted state. A single sliding pill
/// animates between segments for a premium, Material-3 feel.
class UnitSelector extends StatelessWidget {
  const UnitSelector({
    super.key,
    required this.units,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  /// Ordered, de-duplicated segment labels. Defaults to the standard steel
  /// selling units when constructed via [UnitSelector.standard].
  final List<String> units;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  static const standardUnits = ['Pc', 'Ton', 'Kg', 'Bundle'];

  /// Convenience constructor for the standard steel selling units.
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
    final selectedIndex =
        units.indexOf(selected).clamp(0, units.length - 1).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / units.length;
        return Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Vibe.bgSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Vibe.stroke),
            ),
            child: Stack(
              children: [
                // Sliding selection pill.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * segmentWidth + 3,
                  top: 3,
                  bottom: 3,
                  width: segmentWidth - 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Vibe.violet,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: Vibe.violet.withValues(alpha: 0.25),
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
            ),
          ),
        );
      },
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : Vibe.muted,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
