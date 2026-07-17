import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_filter.dart';

/// Top bar for the pipeline: optional back button · title · filter · sort · add.
///
/// **The back button is conditional on purpose.** `PipelineScreen` is mounted
/// three ways — as a `MainShell` tab (an `IndexedStack` page with nothing to
/// pop), pushed from the customer detail screen, and as a `/lead` route. An
/// unconditional back arrow would be a dead control in the tab. It therefore
/// renders only when [Navigator.canPop] is true.
///
/// Sort is surfaced here as its own control (the design asks for it) but
/// dispatches the **existing** `SortChanged` event with the existing [SortBy]
/// values — it adds a UI affordance, not a new sorting mechanism. The filter
/// sheet still applies sort too; both paths converge on the same event.
class LeadPipelineHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const LeadPipelineHeader({
    super.key,
    required this.title,
    required this.sortBy,
    required this.hasActiveFilters,
    required this.onFilterTap,
    required this.onSortChanged,
    required this.onAddLead,
  });

  final String title;
  final SortBy sortBy;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;
  final ValueChanged<SortBy> onSortChanged;
  final VoidCallback onAddLead;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.chevron_left_rounded),
              color: scheme.primary,
              iconSize: 30,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _HeaderButton(
            icon: Icons.filter_alt_outlined,
            tooltip: 'Filter leads',
            onTap: onFilterTap,
            // The only signal that a filter is hiding rows — without it a rep
            // can't tell an empty board from a filtered one.
            highlighted: hasActiveFilters,
          ),
          const SizedBox(width: 8),
          _SortButton(sortBy: sortBy, onSortChanged: onSortChanged),
          const SizedBox(width: 8),
          _HeaderButton(
            icon: Icons.add_rounded,
            tooltip: 'Add lead',
            onTap: onAddLead,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sortBy, required this.onSortChanged});

  final SortBy sortBy;
  final ValueChanged<SortBy> onSortChanged;

  String _label(SortBy value) => switch (value) {
        SortBy.newest => 'Newest first',
        SortBy.oldest => 'Oldest first',
        SortBy.revenue => 'Highest value',
        SortBy.priority => 'Priority',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return PopupMenuButton<SortBy>(
      onSelected: onSortChanged,
      tooltip: 'Sort leads',
      initialValue: sortBy,
      color: colors.surfaceSoft,
      itemBuilder: (_) => [
        for (final value in SortBy.values)
          PopupMenuItem(value: value, child: Text(_label(value))),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.swap_vert_rounded, color: scheme.onPrimary, size: 20),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
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

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: filled || highlighted ? scheme.primary : colors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: filled || highlighted ? scheme.primary : colors.border,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
                  filled || highlighted ? scheme.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
