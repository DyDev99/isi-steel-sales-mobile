import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class CustomerSearchBar extends StatelessWidget {
  const CustomerSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilters,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

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
                      hintText: 'Search shop, code, owner, phone…',
                      hintStyle: TextStyle(color: Vibe.muted, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasActiveFilters ? Vibe.violet.withValues(alpha: 0.18) : Vibe.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hasActiveFilters ? Vibe.violet : Vibe.stroke),
            ),
            child: Icon(Icons.tune_rounded, color: hasActiveFilters ? Vibe.violet : Vibe.text, size: 20),
          ),
        ),
      ],
    );
  }
}
