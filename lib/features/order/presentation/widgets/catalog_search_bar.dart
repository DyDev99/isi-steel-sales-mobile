import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class CatalogSearchBar extends StatelessWidget {
  const CatalogSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilters,
    required this.onScanTap,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final VoidCallback onScanTap;

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
                      hintText: 'Search code, name, SKU, barcode…',
                      hintStyle: TextStyle(color: Vibe.muted, fontSize: 13.5),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onScanTap,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.qr_code_scanner_rounded, color: Vibe.muted, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SquareButton(icon: Icons.tune_rounded, highlighted: hasActiveFilters, onTap: onFilterTap),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap, this.highlighted = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

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
          color: highlighted ? Vibe.violet.withValues(alpha: 0.18) : Vibe.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: highlighted ? Vibe.violet : Vibe.stroke),
        ),
        child: Icon(icon, color: highlighted ? Vibe.violet : Vibe.text, size: 20),
      ),
    );
  }
}
