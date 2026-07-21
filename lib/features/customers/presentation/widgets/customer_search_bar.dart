import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class CustomerSearchBar extends StatelessWidget {
  const CustomerSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilters,
    required this.onAddTap, // 1. Added the required callback parameter
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final VoidCallback onAddTap; // 2. Declared the parameter

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors; //[cite: 3]
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.card, //[cite: 3]
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border), //[cite: 3]
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: colors.textSecondary, size: 20), //[cite: 3]
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged, //[cite: 3]
                    style: TextStyle(
                        color: colors.textPrimary, fontSize: 13.5), //[cite: 3]
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'customers.search_hint'.tr, //[cite: 3]
                      hintStyle: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13.5), //[cite: 3]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap, //[cite: 3]
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? scheme.primary.withValues(alpha: 0.18) //[cite: 3]
                  : colors.card, //[cite: 3]
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: hasActiveFilters
                      ? scheme.primary
                      : colors.border), //[cite: 3]
            ),
            child: Icon(Icons.tune_rounded,
                color: hasActiveFilters
                    ? scheme.primary
                    : colors.textPrimary, //[cite: 3]
                size: 20),
          ),
        ),
        const SizedBox(width: 10), // Space between filter and add button

        // 3. New Add Customer Button on the right of filter
        InkWell(
          onTap: onAddTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
