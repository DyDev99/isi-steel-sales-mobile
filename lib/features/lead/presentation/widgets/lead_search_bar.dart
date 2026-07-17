import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// The pipeline's single action row: search field · filter · add lead.
///
/// This is now the screen's **only** top bar — the separate `LeadPipelineHeader`
/// was removed, so Add lives here rather than duplicating it in two places.
///
/// Stateful only to own its [TextEditingController]. The query itself lives in
/// `PipelineFilter.search` in the bloc — [initialValue] seeds the field so the
/// text survives a rebuild (rotation, theme change) without this widget ever
/// becoming a second source of truth for the search term.
class LeadSearchBar extends StatefulWidget {
  const LeadSearchBar({
    super.key,
    required this.onChanged,
    required this.onFilterTap,
    required this.onAddLead,
    this.initialValue = '',
    this.hasActiveFilters = false,
    this.hintText = 'Search leads...',
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  /// Opens the create-lead sheet. The primary action on this screen, hence the
  /// filled treatment to the right of the outlined filter button.
  final VoidCallback onAddLead;
  final String initialValue;
  final bool hasActiveFilters;
  final String hintText;

  @override
  State<LeadSearchBar> createState() => _LeadSearchBarState();
}

class _LeadSearchBarState extends State<LeadSearchBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.card,
                hintText: widget.hintText,
                hintStyle: TextStyle(color: colors.textHint, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: colors.textSecondary, size: 20),
                // Only offered once there's something to clear — an always-on
                // clear button on an empty field is noise.
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: colors.textSecondary),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                          setState(() {});
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SquareAction(
            icon: Icons.tune_rounded,
            tooltip: 'Filter leads',
            onTap: widget.onFilterTap,
            // The only signal that a filter is hiding rows — without it a rep
            // can't tell an empty board from a filtered one.
            highlighted: widget.hasActiveFilters,
          ),
          const SizedBox(width: 10),
          _SquareAction(
            icon: Icons.add_rounded,
            tooltip: 'Add lead',
            onTap: widget.onAddLead,
            filled: true,
          ),
        ],
      ),
    );
  }
}

/// A 46px square button matching the search field's height and radius, so the
/// row reads as one control strip rather than three unrelated shapes.
///
/// [filled] marks the primary action (Add); [highlighted] marks a secondary
/// action that is currently *active* (a filter is applied).
class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final emphasised = filled || highlighted;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            // 46px clears the 48px-ish minimum touch target once the row's
            // padding is counted, and matches the search field's height.
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: filled ? scheme.primary : colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: emphasised ? scheme.primary : colors.border,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: filled
                  ? scheme.onPrimary
                  : highlighted
                      ? scheme.primary
                      : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
