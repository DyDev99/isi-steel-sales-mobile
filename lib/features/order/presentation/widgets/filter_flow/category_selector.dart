import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/filter_flow_transition.dart';

/// Step 0 of the guided configurator: the only thing on screen when the rep
/// opens a quotation.
///
/// Pure presentation — it renders the categories it is handed and reports taps.
/// It has no idea where they came from, which is what lets the same widget
/// serve the standalone filter screen and the embedded quotation builder.
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.onSelect,
    this.selectedCategoryId,
  });

  final List<Category> categories;
  final ValueChanged<Category> onSelect;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on a phone, three once there's room — steel category
        // names are short, so the extra column is legible rather than cramped.
        final columns = constraints.maxWidth > 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return FilterFlowStaggeredItem(
              index: index,
              child: _CategoryTile(
                category: category,
                selected: category.id == selectedCategoryId,
                onTap: () => onSelect(category),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: FilterFlowTransition.duration,
      curve: FilterFlowTransition.curve,
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? scheme.primary : colors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _iconFor(category.name),
                  size: 20,
                  color: selected ? scheme.primary : colors.iconMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? scheme.primary : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Recognisable-at-a-glance iconography per ISI product line. Falls back to a
  /// neutral inventory icon, so a category added in SAP tomorrow still renders
  /// sensibly without a code change.
  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('palm')) return Icons.roofing_rounded;
    if (n.contains('interior')) return Icons.chair_outlined;
    if (n.contains('pipe')) return Icons.circle_outlined;
    if (n.contains('bar') || n.contains('rebar')) return Icons.straighten;
    if (n.contains('cam') || n.contains('purlin')) return Icons.view_week;
    if (n.contains('steel')) return Icons.grid_goldenratio;
    if (n.contains('flat') || n.contains('sheet')) return Icons.layers_outlined;
    if (n.contains('hardware')) return Icons.hardware_outlined;
    if (n.contains('construction')) return Icons.foundation_outlined;
    return Icons.inventory_2_outlined;
  }
}
