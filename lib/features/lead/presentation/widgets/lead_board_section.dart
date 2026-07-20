import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_board_header.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_card.dart'
    show LeadCardAction;
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_pipeline_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_stage_visuals.dart';

/// One pipeline stage rendered as a tinted board section: coloured header on
/// top, then a horizontally scrolling strip of [LeadPipelineCard]s.
class LeadBoardSection extends StatelessWidget {
  const LeadBoardSection({
    super.key,
    required this.stage,
    required this.leads,
    required this.onCardTap,
    required this.onCardAction,
    this.isAdmin = false,
  });

  final PipelineStage stage;
  final List<Lead> leads;
  final void Function(Lead lead) onCardTap;
  final void Function(Lead lead, LeadCardAction action) onCardAction;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: stage.sectionTint(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stage.accent(context).withValues(alpha: 0.18),
        ),
      ),
      // Crucial: Clip.antiAlias on the outer wrapper is safe, but the children
      // layout needs inner breathing space for the floating badges to render.
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LeadBoardHeader(
            stage: stage,
            count: leads.length,
            totalValue: leadsTotalValue(leads),
          ),
          if (leads.isEmpty)
            const _EmptyBoard()
          else
            LeadBoardList(
              stage: stage,
              leads: leads,
              onCardTap: onCardTap,
              onCardAction: onCardAction,
              isAdmin: isAdmin,
            ),
        ],
      ),
    );
  }
}

/// The horizontal card strip with optimized layout boundaries.
class LeadBoardList extends StatelessWidget {
  const LeadBoardList({
    super.key,
    required this.stage,
    required this.leads,
    required this.onCardTap,
    required this.onCardAction,
    this.isAdmin = false,
  });

  final PipelineStage stage;
  final List<Lead> leads;
  final void Function(Lead lead) onCardTap;
  final void Function(Lead lead, LeadCardAction action) onCardAction;
  final bool isAdmin;

  static double cardWidthFor(double screenWidth) {
    const outerPadding = 32.0;
    const innerPadding = 20.0;
    const gap = 10.0;
    final usable = screenWidth - outerPadding - innerPadding;
    final twoUp = (usable - gap) / 2;
    return twoUp.clamp(160.0, 280.0);
  }

  @override
  Widget build(BuildContext context) {
    final width = cardWidthFor(MediaQuery.sizeOf(context).width);
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);

    // Calculated height expanded to completely absorb maximum text scaling
    // variations alongside the floating capsule badges without vertical clipping.
    final calculatedHeight = 180.0 * textScale;

    return SizedBox(
      height: calculatedHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // CRUCIAL UPGRADE: Stops the horizontal viewport from cutting off the floating badge
        clipBehavior: Clip.none,
        // Generous top padding layout accommodation for the overflowing badge canvas
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        itemCount: leads.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final lead = leads[i];
          return SizedBox(
            width: width,
            child: LeadPipelineCard(
              key: ValueKey(lead.id),
              lead: lead,
              isAdmin: isAdmin,
              onTap: () => onCardTap(lead),
              onAction: (action) => onCardAction(lead, action),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No Leads',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
