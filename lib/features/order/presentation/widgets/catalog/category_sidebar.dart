import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';

/// Hierarchical category browser — used both as a persistent left rail on
/// wide layouts and inside a `Drawer` on narrow ones (see `CatalogScreen`'s
/// `LayoutBuilder` breakpoint, the same pattern `PipelineScreen` uses).
class CategorySidebar extends StatelessWidget {
  const CategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final topLevel = categories.where((c) => c.isTopLevel).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _CategoryTile(
          label: 'All Products',
          icon: Icons.grid_view_rounded,
          selected: selectedCategoryId == null,
          onTap: () => onSelect(null),
        ),
        for (final top in topLevel)
          _CategoryGroup(
            category: top,
            children: categories.where((c) => c.parentId == top.id).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
            selectedCategoryId: selectedCategoryId,
            onSelect: onSelect,
          ),
      ],
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.category,
    required this.children,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final Category category;
  final List<Category> children;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  bool get _containsSelected =>
      category.id == selectedCategoryId ||
      children.any((c) => c.id == selectedCategoryId);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _containsSelected,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        iconColor: Vibe.violet,
        collapsedIconColor: Vibe.muted,
        title: Text(
          category.name,
          style: const TextStyle(
              color: Vibe.text, fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        children: [
          for (final child in children)
            _CategoryTile(
              label: child.name,
              selected: selectedCategoryId == child.id,
              onTap: () => onSelect(child.id),
              indent: true,
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.indent = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(indent ? 32 : 16, 10, 16, 10),
        color: selected
            ? Vibe.primaryLight.withValues(alpha: 0.5)
            : Colors.transparent,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: selected ? Vibe.violet : Vibe.muted),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Vibe.violet : Vibe.text,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
