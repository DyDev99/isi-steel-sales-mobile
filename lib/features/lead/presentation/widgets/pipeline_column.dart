import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_card.dart';

/// One Kanban column. Wraps the whole scrollable body in a [DragTarget] so
/// dropping a card anywhere in the column (including empty space) moves it
/// to this stage; each card is additionally wrapped in its own inner
/// [DragTarget] so dropping directly on a card either reorders it (same
/// column) or moves-and-inserts near it (different column) — Flutter hit
/// tests the innermost target first, so the per-card target wins whenever
/// the drop lands on a card.
class PipelineColumn extends StatelessWidget {
  const PipelineColumn({
    super.key,
    required this.stage,
    required this.leads,
    required this.onCardTap,
    required this.onCardAction,
    required this.onDroppedOnColumn,
    required this.onDroppedOnCard,
  });

  final PipelineStage stage;
  final List<Lead> leads;
  final void Function(Lead lead) onCardTap;
  final void Function(Lead lead, LeadCardAction action) onCardAction;
  final void Function(Lead dragged) onDroppedOnColumn;
  final void Function(Lead dragged, int targetIndex) onDroppedOnCard;

  // Every column uses the same primary blue per the CRM spec — stage is
  // already conveyed by the column title and each card's StageBadge.
  Color get _accent => Vibe.violet;

  @override
  Widget build(BuildContext context) {
    final totalRevenue = leads.fold<double>(
      0,
      (sum, l) => sum + (stage == PipelineStage.won ? l.currentRevenue : l.expectedRevenue),
    );

    return Container(
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Vibe.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _accent.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stage.label,
                    style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${leads.length}',
                      style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              '\$${totalRevenue.toStringAsFixed(0)} total',
              style: const TextStyle(color: Vibe.muted, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: DragTarget<Lead>(
              onWillAcceptWithDetails: (details) => details.data.stage != stage,
              onAcceptWithDetails: (details) => onDroppedOnColumn(details.data),
              builder: (context, candidateData, rejectedData) {
                final highlighted = candidateData.isNotEmpty;
                return Container(
                  color: highlighted ? _accent.withValues(alpha: 0.06) : Colors.transparent,
                  child: leads.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No ${stage.label.toLowerCase()} yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Vibe.muted, fontSize: 12)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            final lead = leads[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DragTarget<Lead>(
                                onWillAcceptWithDetails: (details) => details.data.id != lead.id,
                                onAcceptWithDetails: (details) =>
                                    onDroppedOnCard(details.data, index),
                                builder: (context, candidateData, rejectedData) {
                                  return AnimatedScale(
                                    scale: candidateData.isNotEmpty ? 1.03 : 1,
                                    duration: const Duration(milliseconds: 150),
                                    child: LeadCard(
                                      lead: lead,
                                      onTap: () => onCardTap(lead),
                                      onAction: (action) => onCardAction(lead, action),
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
