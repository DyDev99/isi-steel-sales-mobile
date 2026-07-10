import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// A dropdown-style filter field that opens a searchable bottom-sheet picker.
///
/// Chosen over a raw [DropdownButtonFormField] because the attribute lists
/// (sizes, grades, materials…) can be long and benefit from a search box,
/// a clear action, and proper empty/loading states — none of which the stock
/// dropdown handles well on mobile. Fully controlled: no internal selection
/// state, so it round-trips persisted filter values cleanly.
class FilterDropdown extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.hint,
    this.enabled = true,
    this.loading = false,
    this.searchable = true,
  });

  final String label;

  /// Currently selected display value, or `null` when nothing is selected.
  final String? value;
  final List<String> options;

  /// Emits the newly selected value, or `null` when the user clears it.
  final ValueChanged<String?> onChanged;

  final IconData? icon;
  final String? hint;
  final bool enabled;
  final bool loading;
  final bool searchable;

  bool get _isDisabled => !enabled || loading;

  Future<void> _open(BuildContext context) async {
    if (_isDisabled) return;
    final result = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Vibe.bgSoft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _OptionsSheet(
        label: label,
        options: options,
        selected: value,
        searchable: searchable,
      ),
    );
    if (result != null) onChanged(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Semantics(
      button: true,
      enabled: !_isDisabled,
      label: '$label filter',
      value: value ?? hint ?? 'Any',
      child: Opacity(
        opacity: _isDisabled ? 0.55 : 1,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Vibe.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValue ? Vibe.violet : Vibe.stroke,
                width: hasValue ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 18, color: hasValue ? Vibe.violet : Vibe.muted),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Vibe.muted,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value ?? hint ?? 'Any',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: hasValue ? Vibe.text : Vibe.disabledText,
                        ),
                      ),
                    ],
                  ),
                ),
                _trailing(context, hasValue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailing(BuildContext context, bool hasValue) {
    if (loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Vibe.violet),
      );
    }
    if (hasValue && enabled) {
      return InkWell(
        onTap: () => onChanged(null),
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(2),
          child: Icon(Icons.close_rounded, size: 18, color: Vibe.muted),
        ),
      );
    }
    return const Icon(Icons.keyboard_arrow_down_rounded,
        size: 22, color: Vibe.muted);
  }
}

class _PickResult {
  const _PickResult(this.value);
  final String? value;
}

class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet({
    required this.label,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final bool searchable;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Vibe.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Vibe.text,
                        ),
                      ),
                    ),
                    if (widget.selected != null)
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(const _PickResult(null)),
                        child: const Text('Clear',
                            style: TextStyle(color: Vibe.muted)),
                      ),
                  ],
                ),
                if (widget.searchable) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search ${widget.label.toLowerCase()}…',
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: Vibe.muted),
                      filled: true,
                      fillColor: Vibe.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Vibe.stroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Vibe.stroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Vibe.violet),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Flexible(
                  child: filtered.isEmpty
                      ? const _EmptyOptions()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Vibe.divider),
                          itemBuilder: (context, index) {
                            final option = filtered[index];
                            final isSelected = option == widget.selected;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSelected ? Vibe.violet : Vibe.text,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: Vibe.violet, size: 20)
                                  : null,
                              onTap: () => Navigator.of(context)
                                  .pop(_PickResult(option)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOptions extends StatelessWidget {
  const _EmptyOptions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 36, color: Vibe.muted),
            SizedBox(height: 8),
            Text('No matching options',
                style: TextStyle(color: Vibe.muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
