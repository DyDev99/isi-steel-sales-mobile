import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_filter.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

Future<void> showPipelineFilterSheet({
  required BuildContext context,
  required PipelineFilter filter,
  required List<String> territories,
  required List<String> reps,
  required void Function(PipelineFilter filter) onApply,
}) {
  // Surface, shape, isScrollControlled, keyboard insets and safe area all come
  // from the shared wrapper now.
  return showAppBottomSheet<void>(
    context: context,
    builder: (_) => _PipelineFilterSheet(
      filter: filter,
      territories: territories,
      reps: reps,
      onApply: onApply,
    ),
  );
}

class _PipelineFilterSheet extends StatefulWidget {
  const _PipelineFilterSheet({
    required this.filter,
    required this.territories,
    required this.reps,
    required this.onApply,
  });

  final PipelineFilter filter;
  final List<String> territories;
  final List<String> reps;
  final void Function(PipelineFilter filter) onApply;

  @override
  State<_PipelineFilterSheet> createState() => _PipelineFilterSheetState();
}

class _PipelineFilterSheetState extends State<_PipelineFilterSheet> {
  late String? _territory = widget.filter.territory;
  late String? _rep = widget.filter.assignedRepName;
  late Priority? _priority = widget.filter.priority;
  late SortBy _sortBy = widget.filter.sortBy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    // Keyboard inset + SafeArea now live in AppBottomSheet; this keeps only its
    // own content padding.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Filter & sort',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _territory = null;
                  _rep = null;
                  _priority = null;
                  _sortBy = SortBy.newest;
                }),
                child: Text('Clear',
                    style: TextStyle(color: colors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _Label('Sort by'),
          _ChipGroup<SortBy>(
            options: const {
              SortBy.newest: 'Newest',
              SortBy.oldest: 'Oldest',
              SortBy.revenue: 'Revenue',
              SortBy.priority: 'Priority',
            },
            selected: _sortBy,
            onSelected: (v) => setState(() => _sortBy = v),
          ),
          const SizedBox(height: 16),
          const _Label('Priority'),
          _ChipGroup<Priority?>(
            options: const {
              null: 'Any',
              Priority.high: 'High',
              Priority.medium: 'Medium',
              Priority.low: 'Low'
            },
            selected: _priority,
            onSelected: (v) => setState(() => _priority = v),
          ),
          const SizedBox(height: 16),
          const _Label('Territory'),
          _ChipGroup<String?>(
            options: {null: 'Any', for (final t in widget.territories) t: t},
            selected: _territory,
            onSelected: (v) => setState(() => _territory = v),
          ),
          const SizedBox(height: 16),
          const _Label('Sales rep'),
          _ChipGroup<String?>(
            options: {null: 'Any', for (final r in widget.reps) r: r},
            selected: _rep,
            onSelected: (v) => setState(() => _rep = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(widget.filter.copyWith(
                  territory: () => _territory,
                  assignedRepName: () => _rep,
                  priority: () => _priority,
                  sortBy: _sortBy,
                ));
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
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
            style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
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
                  ? scheme.primary.withValues(alpha: 0.2)
                  : colors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: isSelected ? scheme.primary : colors.border),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: isSelected ? scheme.primary : colors.textPrimary,
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
