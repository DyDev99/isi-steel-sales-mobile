import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class PipelineSearchFilterBar extends StatelessWidget {
  const PipelineSearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilters,
    required this.onAddLead,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final VoidCallback onAddLead;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: colors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    style:
                        TextStyle(color: colors.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search company or owner…',
                      hintStyle: TextStyle(
                          color: colors.textSecondary, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SquareButton(
          icon: Icons.tune_rounded,
          highlighted: hasActiveFilters,
          onTap: onFilterTap,
        ),
        const SizedBox(width: 10),
        _SquareButton(
            icon: Icons.add_rounded, onTap: onAddLead, gradient: true),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton(
      {required this.icon,
      required this.onTap,
      this.highlighted = false,
      this.gradient = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient
              ? LinearGradient(
                  colors: [scheme.primary, colors.primaryHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradient
              ? null
              : (highlighted
                  ? scheme.primary.withValues(alpha: 0.18)
                  : colors.card),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: highlighted ? scheme.primary : colors.border),
        ),
        child: Icon(icon,
            color: gradient
                ? scheme.onPrimary
                : (highlighted ? scheme.primary : colors.textPrimary),
            size: 20),
      ),
    );
  }
}
