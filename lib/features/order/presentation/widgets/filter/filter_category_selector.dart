import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';

/// Horizontal, single-select category rail with icon tiles, an animated
/// active state, a ripple, and — the reason it's a dedicated widget rather
/// than the shared `CategoryQuickFilterRow` — automatic scroll-to-reveal of
/// the selected tile (e.g. when a persisted category is restored off-screen).
///
/// A leading "All" tile clears the category (`onSelect(null)`).
class FilterCategorySelector extends StatefulWidget {
  const FilterCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  @override
  State<FilterCategorySelector> createState() => _FilterCategorySelectorState();
}

class _FilterCategorySelectorState extends State<FilterCategorySelector> {
  static const _allKey = '__all__';
  final _controller = ScrollController();
  final _tileKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(FilterCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _revealSelected() {
    final key = _tileKeys[widget.selectedCategoryId ?? _allKey];
    final ctx = key?.currentContext;
    if (ctx == null || !_controller.hasClients) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  static const _fallbackIcon = Icons.category_rounded;
  static const Map<String, IconData> _iconKeywords = {
    'rebar': Icons.horizontal_rule_rounded,
    'pipe': Icons.plumbing_rounded,
    'tube': Icons.circle_outlined,
    'sheet': Icons.crop_square_rounded,
    'plate': Icons.crop_square_rounded,
    'coil': Icons.data_usage_rounded,
    'flat': Icons.crop_16_9_rounded,
    'wire': Icons.cable_rounded,
    'mesh': Icons.grid_on_rounded,
    'beam': Icons.view_column_rounded,
    'structural': Icons.view_column_rounded,
    'angle': Icons.change_history_rounded,
    'billet': Icons.view_in_ar_rounded,
    'tool': Icons.build_rounded,
    'hardware': Icons.hardware_rounded,
    'fastener': Icons.hardware_rounded,
    'bolt': Icons.hardware_rounded,
    'nut': Icons.hardware_rounded,
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
    final topLevel = widget.categories.where((c) => c.isTopLevel).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (topLevel.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 82,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: topLevel.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryTile(
              key: _tileKeys.putIfAbsent(_allKey, GlobalKey.new),
              label: 'All',
              icon: Icons.grid_view_rounded,
              selected: widget.selectedCategoryId == null,
              onTap: () => widget.onSelect(null),
            );
          }
          final category = topLevel[index - 1];
          return _CategoryTile(
            key: _tileKeys.putIfAbsent(category.id, GlobalKey.new),
            label: category.name,
            icon: _iconFor(category.name),
            selected: widget.selectedCategoryId == category.id,
            onTap: () => widget.onSelect(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? Vibe.violet : Vibe.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Vibe.violet : Vibe.stroke),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Vibe.violet.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : Vibe.muted),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : Vibe.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
