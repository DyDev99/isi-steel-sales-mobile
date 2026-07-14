import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
                      hintText: 'customers.search_hint'.tr,
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
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? scheme.primary.withValues(alpha: 0.18)
                  : colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: hasActiveFilters ? scheme.primary : colors.border),
            ),
            child: Icon(Icons.tune_rounded,
                color: hasActiveFilters ? scheme.primary : colors.textPrimary,
                size: 20),
          ),
        ),
      ],
    );
  }
}
