import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Floating bottom action bar for the filter experience: a secondary "Reset"
/// action and a primary "Apply" button that doubles as a live result counter
/// ("Showing 245 products"). Presentational — all behaviour is delegated to
/// the two callbacks so it can sit above any result list.
class FilterActionBar extends StatelessWidget {
  const FilterActionBar({
    super.key,
    required this.resultCount,
    required this.onReset,
    required this.onApply,
    this.canReset = true,
    this.loading = false,
  });

  /// Number of products matching the current filter. When [loading] is true
  /// the count is replaced by a spinner instead of a possibly-stale number.
  final int resultCount;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final bool canReset;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Vibe.surface,
        border: const Border(top: BorderSide(color: Vibe.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: canReset ? onReset : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Vibe.text,
                side: const BorderSide(color: Vibe.stroke),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: loading ? null : onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Vibe.violet,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Vibe.violet.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _applyLabel,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _applyLabel {
    if (resultCount <= 0) return 'No products found';
    if (resultCount == 1) return 'Show 1 product';
    return 'Show $resultCount products';
  }
}
