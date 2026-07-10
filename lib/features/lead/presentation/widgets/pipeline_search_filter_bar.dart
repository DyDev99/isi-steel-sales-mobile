import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

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
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Vibe.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Vibe.stroke),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Vibe.muted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(color: Vibe.text, fontSize: 13.5),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search company or owner…',
                      hintStyle: TextStyle(color: Vibe.muted, fontSize: 13.5),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient ? Vibe.cta : null,
          color: gradient
              ? null
              : (highlighted
                  ? Vibe.violet.withValues(alpha: 0.18)
                  : Vibe.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: highlighted ? Vibe.violet : Vibe.stroke),
        ),
        child: Icon(icon,
            color: gradient
                ? Colors.white
                : (highlighted ? Vibe.violet : Vibe.text),
            size: 20),
      ),
    );
  }
}
