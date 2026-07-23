import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/l10n/lead_labels.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/pipeline_rules.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_card.dart';

/// One board column. Wraps the whole scrollable body in a [DragTarget] so
/// dropping a card anywhere in the column (including empty space) moves it
/// to this stage; each card is additionally wrapped in its own inner
/// [DragTarget] so dropping directly on a card either reorders it (same
/// column) or moves-and-inserts near it (different column) — Flutter hit
/// tests the innermost target first, so the per-card target wins whenever
/// the drop lands on a card.
///
/// [stage] is the drop/reorder target. [leads] is what actually renders —
/// usually the leads of [stage], but a column may show a merged list (e.g. the
/// Opportunities column also lists Won cards); [title]/[accent] then let the
/// header read "Opportunities" in green regardless.
class PipelineColumn extends StatelessWidget {
  const PipelineColumn({
    super.key,
    required this.stage,
    required this.leads,
    required this.onCardTap,
    required this.onCardAction,
    required this.onDroppedOnColumn,
    required this.onDroppedOnCard,
    this.title,
    this.accent,
  });

  final PipelineStage stage;
  final List<Lead> leads;
  final void Function(Lead lead) onCardTap;
  final void Function(Lead lead, LeadCardAction action) onCardAction;
  final void Function(Lead dragged) onDroppedOnColumn;
  final void Function(Lead dragged, int targetIndex) onDroppedOnCard;

  /// Header label; defaults to [stage]'s own label.
  final String? title;

  /// Header/banner colour for this board. Defaults to the theme primary.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final accentColor = accent ?? scheme.primary;
    // Revenue reads from each lead's own stage so a merged column (Opportunities
    // + Won) still totals correctly: Won uses realised revenue, the rest use
    // the expected figure.
    final totalRevenue = leads.fold<double>(
      0,
      (sum, l) =>
          sum +
          (l.stage == PipelineStage.won ? l.currentRevenue : l.expectedRevenue),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colored banner header: dot · title · count.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            color: accentColor,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: scheme.onPrimary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? stage.localizedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${leads.length}',
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          // Total sub-row on a faint tint of the accent.
          Container(
            width: double.infinity,
            color: accentColor.withValues(alpha: 0.10),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Text(
                  '\$${totalRevenue.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                Text('Total',
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<Lead>(
              onWillAcceptWithDetails: (details) => details.data.stage != stage,
              onAcceptWithDetails: (details) => onDroppedOnColumn(details.data),
              builder: (context, candidateData, rejectedData) {
                final highlighted = candidateData.isNotEmpty;
                return Container(
                  color: highlighted
                      ? accentColor.withValues(alpha: 0.06)
                      : Colors.transparent,
                  child: leads.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                                'leads.no_stage_yet'.trParams({
                                  'stage': (title ?? stage.localizedLabel)
                                      .toLowerCase()
                                }),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: colors.textSecondary, fontSize: 12)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            final lead = leads[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DragTarget<Lead>(
                                onWillAcceptWithDetails: (details) =>
                                    details.data.id != lead.id,
                                onAcceptWithDetails: (details) =>
                                    onDroppedOnCard(details.data, index),
                                builder:
                                    (context, candidateData, rejectedData) {
                                  return AnimatedScale(
                                    scale: candidateData.isNotEmpty ? 1.03 : 1,
                                    duration: const Duration(milliseconds: 150),
                                    child: LeadCard(
                                      lead: lead,
                                      dueCount: leadDueCount(lead),
                                      onTap: () => onCardTap(lead),
                                      onAction: (action) =>
                                          onCardAction(lead, action),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
