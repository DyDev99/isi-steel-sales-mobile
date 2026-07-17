import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_filter.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/lead_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/lead_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_card.dart'
    show LeadCardAction;
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_form_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/move_stage_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/pipeline_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/send_to_hq_sheet.dart';

/// What a pipeline card's actions actually *do* — open detail, edit, delete,
/// move stage, send to HQ, filter, add.
///
/// Extracted from `pipeline_screen.dart` so the screen is about layout and this
/// is about intent. Every method below is the behaviour that already existed;
/// none of it changed in the redesign. Sheets and bloc events are the originals.
class LeadPipelineActions {
  const LeadPipelineActions({required this.isAdmin});

  /// Gates the "Send to HQ" menu entry, exactly as before.
  final bool isAdmin;

  /// Pushes the lead detail screen, re-providing the existing [PipelineBloc]
  /// so an edit made in detail is reflected on the board when it pops.
  void openDetail(BuildContext context, Lead lead) {
    final pipelineBloc = context.read<PipelineBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: pipelineBloc),
            BlocProvider(create: (_) => sl<LeadDetailCubit>()..load(lead.id)),
          ],
          child: LeadDetailScreen(leadId: lead.id),
        ),
      ),
    );
  }

  Future<void> handle(
      BuildContext context, Lead lead, LeadCardAction action) async {
    final bloc = context.read<PipelineBloc>();
    switch (action) {
      case LeadCardAction.view:
        openDetail(context, lead);
      case LeadCardAction.edit:
        final updated =
            await showLeadFormSheet(context: context, existing: lead);
        if (updated != null) bloc.add(LeadUpdated(updated));
      case LeadCardAction.delete:
        if (await _confirmDelete(context, lead) == true) {
          bloc.add(LeadDeleted(lead.id));
        }
      case LeadCardAction.move:
        final result = await showMoveStageSheet(
            context: context, lead: lead, isAdmin: isAdmin);
        if (result != null) {
          bloc.add(LeadMoved(
            leadId: lead.id,
            toStage: result.toStage,
            opportunityInfo: result.opportunityInfo,
            wonInfo: result.wonInfo,
          ));
        }
      case LeadCardAction.sendToHq:
        final updated = await showSendToHqSheet(context: context, lead: lead);
        if (updated != null) bloc.add(LeadUpdated(updated));
    }
  }

  /// Destructive and irreversible from the user's side, so it is always
  /// confirmed — and the dialog names the company rather than saying "this
  /// item", so a mis-tap on a dense board is caught before it lands.
  Future<bool?> _confirmDelete(BuildContext context, Lead lead) {
    final colors = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceSoft,
        title:
            Text('Delete lead?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'This removes ${lead.companyName} from the pipeline.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  /// Opens the existing filter sheet, sourcing its territory/rep options from
  /// the unfiltered lead set so a narrow filter can't hide its own escape route.
  void openFilterSheet(
    BuildContext context, {
    required PipelineFilter filter,
    required List<Lead> allLeads,
  }) {
    final territories = allLeads.map((l) => l.territory).toSet().toList()
      ..sort();
    final reps = allLeads.map((l) => l.assignedRepName).toSet().toList()
      ..sort();

    showPipelineFilterSheet(
      context: context,
      filter: filter,
      territories: territories,
      reps: reps,
      onApply: (f) {
        final bloc = context.read<PipelineBloc>();
        bloc.add(FilterChanged(
          territory: () => f.territory,
          assignedRepName: () => f.assignedRepName,
          priority: () => f.priority,
          visibleStages: f.visibleStages,
        ));
        bloc.add(SortChanged(f.sortBy));
      },
    );
  }

  Future<void> addLead(BuildContext context) async {
    final created = await showLeadFormSheet(context: context);
    if (created != null && context.mounted) {
      context.read<PipelineBloc>().add(LeadCreated(created));
    }
  }
}
