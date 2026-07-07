import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';

/// Horizontal quick-access row of top-level categories, shown directly
/// under the search bar on the Quotation Builder screen.
///
/// This *complements*, rather than replaces, the existing `CategorySidebar`
/// (still available via the wide-layout side rail and the drawer) — it's a
/// fast one-tap shortcut for the handful of top-level categories, echoing
/// the icon-tile category grid from the updated design reference, while the
/// sidebar/drawer still covers the full parent/child hierarchy.
class CategoryQuickFilterRow extends StatelessWidget {
  const CategoryQuickFilterRow({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedCategoryId;

  /// Same contract as `CategorySidebar.onSelect` — `null` clears the filter.
  final ValueChanged<String?> onSelect;

  static const _fallbackIcon = Icons.category_rounded;

  // Lightweight keyword -> icon mapping so top-level categories get a
  // recognizable glyph without requiring any change to the `Category`
  // entity or backend data.
  static const Map<String, IconData> _iconKeywords = {
    'rebar': Icons.horizontal_rule_rounded,
    'pipe': Icons.plumbing_rounded,
    'tube': Icons.circle_outlined,
    'sheet': Icons.crop_square_rounded,
    'plate': Icons.crop_square_rounded,
    'coil': Icons.data_usage_rounded,
    'wire': Icons.cable_rounded,
    'mesh': Icons.grid_on_rounded,
    'beam': Icons.view_column_rounded,
    'angle': Icons.change_history_rounded,
    'tool': Icons.build_rounded,
    'fastener': Icons.hardware_rounded,
    'bolt': Icons.hardware_rounded,
    'nail': Icons.hardware_rounded,
    'roof': Icons.roofing_rounded,
  };

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _iconKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return _fallbackIcon;
  }

  @override
  Widget build(BuildContext context) {
    final topLevel = categories.where((c) => c.isTopLevel).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Nothing to filter by yet (categories still loading) — take no space
    // rather than showing an empty strip.
    if (topLevel.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: topLevel.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryQuickChip(
              // NOTE: new localization key — add
              // "orders.catalog.all_categories" alongside the other
              // `orders.catalog.*` keys already used in this feature.
              label: 'orders.catalog.all_categories'.tr,
              icon: Icons.grid_view_rounded,
              selected: selectedCategoryId == null,
              onTap: () => onSelect(null),
            );
          }
          final category = topLevel[index - 1];
          return _CategoryQuickChip(
            label: category.name,
            icon: _iconFor(category.name),
            selected: selectedCategoryId == category.id,
            onTap: () => onSelect(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryQuickChip extends StatelessWidget {
  const _CategoryQuickChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? Vibe.violet.withValues(alpha: 0.12) : Vibe.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Vibe.violet : Vibe.stroke),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? Vibe.violet : Vibe.muted),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Vibe.violet : Vibe.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
