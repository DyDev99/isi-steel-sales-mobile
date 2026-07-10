import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/pipeline_rules.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/convert_to_opportunity_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/won_sheet.dart';

/// Result of a stage move: the target stage, plus whichever conversion
/// payload that target required (if any).
typedef StageMoveResult = ({
  PipelineStage toStage,
  OpportunityInfo? opportunityInfo,
  WonInfo? wonInfo,
});

/// Shows the valid next stages for [lead] (per [canMoveStage]). If there's
/// exactly one valid target it's resolved directly (skipping the picker
/// list); otherwise the rep picks from the list first. Either way, moving
/// into Opportunities or Won chains into the matching conversion sheet.
Future<StageMoveResult?> showMoveStageSheet({
  required BuildContext context,
  required Lead lead,
  required bool isAdmin,
}) async {
  final targets = PipelineStage.values
      .where((s) => canMoveStage(lead.stage, s, isAdmin: isAdmin))
      .toList();

  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              moveBlockedReason(lead.stage, lead.stage, isAdmin: isAdmin))),
    );
    return null;
  }

  if (targets.length == 1) {
    return resolveStageMove(
        context: context, lead: lead, toStage: targets.first);
  }

  final chosen = await showModalBottomSheet<PipelineStage>(
    context: context,
    backgroundColor: Vibe.bgSoft,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Move ${lead.companyName}',
                style: const TextStyle(
                    color: Vibe.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Currently in ${lead.stage.label}',
                style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
            const SizedBox(height: 16),
            ...targets.map(
              (stage) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(stage),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Vibe.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Vibe.stroke),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_forward_rounded,
                            color: Vibe.violet, size: 18),
                        const SizedBox(width: 10),
                        Text(stage.label,
                            style: const TextStyle(
                                color: Vibe.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (chosen == null || !context.mounted) return null;
  return resolveStageMove(context: context, lead: lead, toStage: chosen);
}

/// Public entry point used directly by drag-and-drop, where the target
/// stage is already known and the picker list should be skipped entirely.
Future<StageMoveResult?> resolveStageMove({
  required BuildContext context,
  required Lead lead,
  required PipelineStage toStage,
}) async {
  if (toStage == PipelineStage.opportunities &&
      lead.stage == PipelineStage.leads) {
    final info =
        await showConvertToOpportunitySheet(context: context, lead: lead);
    if (info == null) return null;
    return (toStage: toStage, opportunityInfo: info, wonInfo: null);
  }
  if (toStage == PipelineStage.won &&
      lead.stage == PipelineStage.opportunities) {
    if (!context.mounted) return null;
    final info = await showWonSheet(context: context, lead: lead);
    if (info == null) return null;
    return (toStage: toStage, opportunityInfo: null, wonInfo: info);
  }
  return (toStage: toStage, opportunityInfo: null, wonInfo: null);
}
