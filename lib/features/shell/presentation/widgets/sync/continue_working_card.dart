import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/continue_work_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_work_resolver.dart';

/// The floating "Continue Previous Work" card. Surfaces the most recent draft
/// (or a "Continue Working (N)" opener for several). **Never auto-navigates** —
/// resuming, submitting or discarding is always an explicit tap.
///
/// Drafts that belong to the rep's active visit's shop are folded into the
/// visit's own Continue card ([ContinueVisitCard]) and hidden here, so one
/// journey never shows two "Continue" cards (see [standaloneDrafts]).
class ContinueWorkingCard extends StatelessWidget {
  const ContinueWorkingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final activeShopId =
        context.watch<ResumableVisitCubit>().state.activeShopId;
    return BlocBuilder<ContinueWorkCubit, ContinueWorkState>(
      builder: (context, state) {
        final drafts = standaloneDrafts(state.drafts, activeShopId);
        if (!state.loaded || drafts.isEmpty) {
          return const SizedBox.shrink();
        }
        if (drafts.length > 1) {
          return _MultiDraftCard(count: drafts.length);
        }
        return _DraftCard(draft: drafts.first);
      },
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});
  final Quotation draft;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Continue Previous Work',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface)),
              ),
              _DiscardButton(draft: draft),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quotation #${draft.id}',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.primary),
          ),
          const SizedBox(height: 2),
          Text(
            _subtitle(draft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submit(context, draft),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Submit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _continue(context, draft),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultiDraftCard extends StatelessWidget {
  const _MultiDraftCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return _CardShell(
      child: InkWell(
        onTap: () => _openDraftsSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Continue Working ($count)',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text('You have unfinished drafts',
                      style:
                          TextStyle(fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DiscardButton extends StatelessWidget {
  const _DiscardButton({required this.draft});
  final Quotation draft;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _confirmDiscard(context, draft),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(Icons.close_rounded,
            size: 18, color: context.appColors.textSecondary),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        boxShadow: colors.cardShadow,
      ),
      child: child,
    );
  }
}

String _subtitle(Quotation q) {
  final who = q.shopName?.isNotEmpty == true
      ? q.shopName!
      : (q.leadDisplayName ?? 'Walk-in customer');
  return '$who · ${q.lines.length} products · ${_timeAgo(q.updatedAt)}';
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

void _continue(BuildContext context, Quotation draft) {
  Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: QuotationDetailScreen.routeName),
    builder: (_) => QuotationDetailScreen(quotation: draft),
  ));
}

void _submit(BuildContext context, Quotation draft) {
  context.read<PendingSyncCubit>().enqueue(draft.id);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Quotation #${draft.id} queued for SAP sync.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _confirmDiscard(BuildContext context, Quotation draft) async {
  final cubit = context.read<ContinueWorkCubit>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Discard draft?'),
      content: Text('Quotation #${draft.id} will be permanently deleted.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Discard',
              style:
                  TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await cubit.discard(draft.id);
}

void _openDraftsSheet(BuildContext context) {
  final continueCubit = context.read<ContinueWorkCubit>();
  final pendingCubit = context.read<PendingSyncCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.surfaceSoft,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: continueCubit),
        BlocProvider.value(value: pendingCubit),
      ],
      child: const _DraftsSheet(),
    ),
  );
}

class _DraftsSheet extends StatelessWidget {
  const _DraftsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: BlocBuilder<ContinueWorkCubit, ContinueWorkState>(
          builder: (context, state) {
            final scheme = Theme.of(context).colorScheme;
            final colors = context.appColors;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Continue Working (${state.drafts.length})',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  if (state.drafts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text('No drafts left',
                            style: TextStyle(color: colors.textSecondary)),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.drafts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _DraftRow(draft: state.drafts[i]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.draft});
  final Quotation draft;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quotation #${draft.id}',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: scheme.primary)),
          const SizedBox(height: 2),
          Text(_subtitle(draft),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _confirmDiscard(context, draft),
                child: Text('Discard',
                    style: TextStyle(color: colors.textSecondary)),
              ),
              const SizedBox(width: 4),
              OutlinedButton(
                onPressed: () => _submit(context, draft),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.primary),
                child: const Text('Submit'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _continue(context, draft);
                },
                style: FilledButton.styleFrom(backgroundColor: scheme.primary),
                child: const Text('Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
