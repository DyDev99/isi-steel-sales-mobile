import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/resume_workflow_dispatcher.dart';

/// Visit-flow "Continue Previous Work" card — the check-in twin of
/// [ContinueWorkingCard]. Appears in the Home continue section when the rep has
/// an in-progress route; **Continue** resumes the exact check-in (and refreshes
/// state on return), **dismiss** clears it. Never auto-navigates.
class ContinueVisitCard extends StatelessWidget {
  const ContinueVisitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResumableVisitCubit, ResumableVisitState>(
      builder: (context, state) {
        final route = state.route;
        if (!state.loaded || route == null) return const SizedBox.shrink();
        return _VisitCard(route: route, workflow: state.workflow);
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.route, this.workflow});
  final RoutePlan route;

  /// The persisted navigation pointer, used to restore the exact screen the rep
  /// stopped on (Route Count Stock, etc.). Null → guided route resume.
  final ActiveWorkflow? workflow;

  Future<void> _continue(BuildContext context) async {
    final cubit = context.read<ResumableVisitCubit>();
    // Single source of restore truth: map the persisted workflow → the exact
    // screen (falls back to Choose Stop when nothing is restorable).
    await resumeActiveWorkflow(context, route, workflow);
    // Coming back from the flow: re-resolve so a finished route drops off the
    // card and progress updates.
    await cubit.refresh();
  }

  Future<void> _dismiss(BuildContext context) async {
    final cubit = context.read<ResumableVisitCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dismiss check-in?'),
        content: Text(
            'You can still reopen "${route.name}" from the Visits tab later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Dismiss',
                style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.dismiss();
  }

  /// Explicit end of the visit. Check-out is deferred now that Stock Count no
  /// longer auto-checks-out, so this is how the rep closes the stop when the
  /// Quotation/Sales Order task is done.
  Future<void> _checkOut(BuildContext context) async {
    final cubit = context.read<ResumableVisitCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check out of this visit?'),
        content:
            const Text('This completes the visit and closes the current stop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Check out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.checkOut();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final total = route.stops.length;
    final done = route.completedStops;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.info.withValues(alpha: 0.4)),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pin_drop_rounded, size: 18, color: colors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Continue Previous Work',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface)),
              ),
              InkWell(
                onTap: () => _dismiss(context),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            route.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.info),
          ),
          const SizedBox(height: 2),
          Text(
            'Check-in in progress · $done of $total stops done',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: done / total,
                minHeight: 5,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation(colors.info),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _checkOut(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.info,
                    side: BorderSide(color: colors.info),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Check out'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _continue(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.info,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
