import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/interactive.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

/// Category Card — horizontal scroll of category quick-filter chips.
class CategoryChipList extends StatelessWidget {
  const CategoryChipList(
      {super.key, required this.categories, required this.onSelect});

  final List<CategoryChipViewModel> categories;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryChip(
            label: category.label,
            selected: category.selected,
            onTap: () => onSelect(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveScale(
      onTap: onTap,
      builder: (context, isHovered, isPressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Vibe.violet
              : (isHovered
                  ? Vibe.primaryLight.withValues(alpha: 0.4)
                  : Vibe.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected || isHovered ? Vibe.violet : Vibe.stroke),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Vibe.text,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
