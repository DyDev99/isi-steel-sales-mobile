import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';

/// Single source of truth for which stage transitions are allowed, so the
/// drag target, the "Move" menu, and the bloc all enforce the same rule.
///
/// Leads -> Opportunities only (no skipping straight to Won).
/// Opportunities -> Won or back to Leads.
/// Won -> read-only; only an admin may move it back to Opportunities.
bool canMoveStage(PipelineStage from, PipelineStage to, {required bool isAdmin}) {
  if (from == to) return false;
  return switch (from) {
    PipelineStage.leads => to == PipelineStage.opportunities,
    PipelineStage.opportunities =>
      to == PipelineStage.won || to == PipelineStage.leads,
    PipelineStage.won => isAdmin && to == PipelineStage.opportunities,
  };
}

/// Human-readable reason a blocked move failed, for snackbars/dialogs.
String moveBlockedReason(PipelineStage from, PipelineStage to, {required bool isAdmin}) {
  if (from == PipelineStage.leads && to == PipelineStage.won) {
    return 'Leads must go through Opportunities before becoming Won.';
  }
  if (from == PipelineStage.won && !isAdmin) {
    return 'Won customers are read-only. Only an admin can move them back.';
  }
  return "Can't move from ${from.label} to ${to.label}.";
}
