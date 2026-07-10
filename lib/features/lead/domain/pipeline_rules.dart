import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';

/// Single source of truth for which stage transitions are allowed, so the
/// drag target, the "Move" menu, and the bloc all enforce the same rule.
///
/// Leads -> Opportunities only (no skipping straight to Won).
/// Opportunities -> Won or back to Leads.
/// Won -> read-only; only an admin may move it back to Opportunities.
bool canMoveStage(PipelineStage from, PipelineStage to,
    {required bool isAdmin}) {
  if (from == to) return false;
  return switch (from) {
    PipelineStage.leads => to == PipelineStage.opportunities,
    PipelineStage.opportunities =>
      to == PipelineStage.won || to == PipelineStage.leads,
    PipelineStage.won => isAdmin && to == PipelineStage.opportunities,
  };
}

/// Number of still-pending actions for [lead] — drives the compact "N Due"
/// badge on the pipeline card. Derived entirely from data the lead already
/// carries (no new backend field), so it stays in sync automatically. Each
/// rule maps to a concrete next step the rep owes the customer:
///
/// - Leads: a first follow-up is always due, plus a second "overdue" action
///   once the lead has sat untouched for a week.
/// - Opportunities: unknown budget, no decision-maker access, a closing date
///   that has already passed, and a stale/absent last contact each count as
///   one pending action.
/// - Won: still owes a "Send to HQ" onboarding submission.
///
/// [now] is injectable so the rule stays pure and testable.
int leadDueCount(Lead lead, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var due = 0;

  switch (lead.stage) {
    case PipelineStage.leads:
      due += 1; // first follow-up
      if (today.difference(lead.createdDate).inDays >= 7) {
        due += 1; // overdue: still a raw lead after a week
      }
    case PipelineStage.opportunities:
      final info = lead.opportunityInfo;
      if (info == null) {
        due += 1;
      } else {
        if (info.budgetStatus == null) due += 1; // qualify budget
        if (info.hasDecisionMakerAccess != true) due += 1; // reach decision-maker
        final closing = info.expectedClosingDate;
        if (closing != null && !closing.isAfter(today)) {
          due += 1; // expected close date has passed
        }
        final contact = info.lastContact;
        if (contact == null || today.difference(contact).inDays >= 7) {
          due += 1; // follow-up due
        }
      }
    case PipelineStage.won:
      if (lead.wonInfo?.onboardingStatus == OnboardingStatus.notSubmitted) {
        due += 1; // send to HQ
      }
  }

  return due;
}

/// Human-readable reason a blocked move failed, for snackbars/dialogs.
String moveBlockedReason(PipelineStage from, PipelineStage to,
    {required bool isAdmin}) {
  if (from == PipelineStage.leads && to == PipelineStage.won) {
    return 'Leads must go through Opportunities before becoming Won.';
  }
  if (from == PipelineStage.won && !isAdmin) {
    return 'Won customers are read-only. Only an admin can move them back.';
  }
  return "Can't move from ${from.label} to ${to.label}.";
}
