import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';

Future<void> showCatalogFilterSheet({
  required BuildContext context,
  required ProductFilter filter,
  required List<String> brands,
  required void Function(ProductFilter filter) onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Vibe.bgSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) =>
        _CatalogFilterSheet(filter: filter, brands: brands, onApply: onApply),
  );
}

class _CatalogFilterSheet extends StatefulWidget {
  const _CatalogFilterSheet(
      {required this.filter, required this.brands, required this.onApply});
  final ProductFilter filter;
  final List<String> brands;
  final void Function(ProductFilter filter) onApply;

  @override
  State<_CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<_CatalogFilterSheet> {
  late String? _brand = widget.filter.brand;
  late bool _availableOnly = widget.filter.availableOnly;
  late ProductSortBy _sortBy = widget.filter.sortBy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Filter & sort',
                        style: TextStyle(
                            color: Vibe.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _brand = null;
                      _availableOnly = false;
                      _sortBy = ProductSortBy.relevance;
                    }),
                    child: const Text('Clear',
                        style: TextStyle(color: Vibe.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _Label('Sort by'),
              _ChipGroup<ProductSortBy>(
                options: const {
                  ProductSortBy.relevance: 'Relevance',
                  ProductSortBy.nameAsc: 'Name A-Z',
                  ProductSortBy.priceAsc: 'Price: Low to High',
                  ProductSortBy.priceDesc: 'Price: High to Low',
                  ProductSortBy.stockDesc: 'Stock: High to Low',
                },
                selected: _sortBy,
                onSelected: (v) => setState(() => _sortBy = v),
              ),
              const SizedBox(height: 16),
              const _Label('Brand'),
              _ChipGroup<String?>(
                options: {null: 'Any', for (final b in widget.brands) b: b},
                selected: _brand,
                onSelected: (v) => setState(() => _brand = v),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _availableOnly,
                onChanged: (v) => setState(() => _availableOnly = v),
                activeThumbColor: Vibe.violet,
                title: const Text('In stock only',
                    style: TextStyle(
                        color: Vibe.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(widget.filter.copyWith(
                      brand: () => _brand,
                      availableOnly: _availableOnly,
                      sortBy: _sortBy,
                    ));
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.violet,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _ChipGroup<T> extends StatelessWidget {
  const _ChipGroup(
      {required this.options,
      required this.selected,
      required this.onSelected});
  final Map<T, String> options;
  final T selected;
  final void Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isSelected = e.key == selected;
        return InkWell(
          onTap: () => onSelected(e.key),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Vibe.violet.withValues(alpha: 0.2)
                  : Vibe.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isSelected ? Vibe.violet : Vibe.stroke),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: isSelected ? Vibe.violet : Vibe.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
