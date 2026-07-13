import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_route_dispatch.dart';

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
        return _VisitCard(route: route);
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.route});
  final RoutePlan route;

  Future<void> _continue(BuildContext context) async {
    final cubit = context.read<ResumableVisitCubit>();
    await openRouteDispatch(context, route.id);
    // Coming back from the check-in flow: re-resolve so a finished route drops
    // off the card and progress updates.
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
                fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.info),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _continue(context),
              style: FilledButton.styleFrom(
                backgroundColor: colors.info,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Continue check-in'),
            ),
          ),
        ],
      ),
    );
  }
}
