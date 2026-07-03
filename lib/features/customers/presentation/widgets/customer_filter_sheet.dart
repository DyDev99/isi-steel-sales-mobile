import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

void showCustomerFilterSheet({
  required BuildContext context,
  required CustomerFilter filter,
  required List<String> territories,
  required ValueChanged<CustomerFilter> onApply,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CustomerFilterSheet(filter: filter, territories: territories, onApply: onApply),
  );
}

class _CustomerFilterSheet extends StatefulWidget {
  const _CustomerFilterSheet({required this.filter, required this.territories, required this.onApply});
  final CustomerFilter filter;
  final List<String> territories;
  final ValueChanged<CustomerFilter> onApply;

  @override
  State<_CustomerFilterSheet> createState() => _CustomerFilterSheetState();
}

class _CustomerFilterSheetState extends State<_CustomerFilterSheet> {
  late CustomerFilter _draft = widget.filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Vibe.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter & Sort', style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text('Status', style: TextStyle(color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip('All', _draft.status == null, () => setState(() => _draft = _draft.copyWith(status: () => null))),
              for (final status in CustomerStatus.values)
                _chip(
                  status.label,
                  _draft.status == status,
                  () => setState(() => _draft = _draft.copyWith(status: () => status)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.territories.isNotEmpty) ...[
            const Text('Territory', style: TextStyle(color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('All', _draft.territory == null, () => setState(() => _draft = _draft.copyWith(territory: () => null))),
                for (final territory in widget.territories)
                  _chip(
                    territory,
                    _draft.territory == territory,
                    () => setState(() => _draft = _draft.copyWith(territory: () => territory)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const Text('Sort by', style: TextStyle(color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sort in CustomerSortBy.values)
                _chip(_sortLabel(sort), _draft.sortBy == sort, () => setState(() => _draft = _draft.copyWith(sortBy: sort))),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_draft);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Vibe.violet,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Vibe.violet.withValues(alpha: 0.16) : Vibe.bgSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Vibe.violet : Vibe.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Vibe.violet : Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _sortLabel(CustomerSortBy sort) => switch (sort) {
        CustomerSortBy.recentOrder => 'Recently ordered',
        CustomerSortBy.nameAsc => 'Alphabetical',
        CustomerSortBy.nearest => 'Nearest to me',
        CustomerSortBy.valueDesc => 'Highest value',
      };
}
