import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// One removable summary chip describing an active filter facet.
class FilterChipData {
  const FilterChipData({required this.label, required this.onClear});

  /// Human-readable summary, e.g. "Size: 12mm" or "Grade: SD390".
  final String label;

  /// Removes just this facet from the active filter.
  final VoidCallback onClear;
}

/// Horizontal, scrollable summary of the active filters with a leading
/// counter badge and a trailing "Clear all". Each chip clears exactly one
/// facet. Renders nothing when there are no active filters, so callers can
/// drop it into a column unconditionally.
class ActiveFilterChipsBar extends StatelessWidget {
  const ActiveFilterChipsBar({
    super.key,
    required this.chips,
    required this.onClearAll,
  });

  final List<FilterChipData> chips;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          _CounterBadge(count: chips.length),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) =>
                  _RemovableChip(data: chips[index]),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Clear all',
                style: TextStyle(
                    color: Vibe.danger,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration:
          const BoxDecoration(color: Vibe.violet, shape: BoxShape.circle),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.data});
  final FilterChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: Vibe.surfaceStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Vibe.violet.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: const TextStyle(
                color: Vibe.violet,
                fontSize: 12.5,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: data.onClear,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: Vibe.violet),
            ),
          ),
        ],
      ),
    );
  }
}
