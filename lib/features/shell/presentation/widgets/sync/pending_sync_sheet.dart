import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_sync_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_queue_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_state.dart';

/// The "Sync Center" — a bottom sheet listing the outbound SAP queue with the
/// SAP response, retry state, and the only two actions the spec allows the user
/// to take: **Sync Now** (drain) and per-item **Retry**. Never auto-syncs.
Future<void> showPendingSyncSheet(BuildContext context) {
  final cubit = context.read<PendingSyncCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Vibe.bgSoft,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => BlocProvider.value(value: cubit, child: const _SyncSheet()),
  );
}

class _SyncSheet extends StatelessWidget {
  const _SyncSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: BlocBuilder<PendingSyncCubit, PendingSyncState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _grabber(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Sync Center',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Vibe.text)),
                      ),
                      if (state.counts.pending > 0)
                        _SyncNowButton(isSyncing: state.isSyncing),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.counts.pending} pending · ${state.counts.failed} failed · ${state.counts.conflict} conflict',
                    style: const TextStyle(color: Vibe.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (state.items.isEmpty)
                    const _EmptyQueue()
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _QueueTile(item: state.items[i]),
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

  Widget _grabber() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Vibe.stroke,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _SyncNowButton extends StatelessWidget {
  const _SyncNowButton({required this.isSyncing});
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed:
          isSyncing ? null : () => context.read<PendingSyncCubit>().syncNow(),
      style: FilledButton.styleFrom(
        backgroundColor: Vibe.violet,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      icon: isSyncing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.sync_rounded, size: 16),
      label: Text(isSyncing ? 'Syncing…' : 'Sync Now'),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item});
  final SyncQueueItem item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Vibe.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.shopName?.isNotEmpty == true
                      ? item.shopName!
                      : 'Quotation ${item.quotationId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: Vibe.text),
                ),
              ),
              _StatusChip(status: item.status, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (item.itemCount != null) '${item.itemCount} items',
              if (item.total != null) '\$${item.total!.toStringAsFixed(2)}',
              if (item.attemptCount > 0) 'attempt ${item.attemptCount}',
            ].join(' · '),
            style: const TextStyle(color: Vibe.muted, fontSize: 11.5),
          ),
          if (item.sapDocumentNumber != null) ...[
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.check_circle_rounded,
              color: Vibe.success,
              text: 'SAP ${item.sapDocumentNumber}'
                  '${item.syncDurationMs != null ? ' · ${item.syncDurationMs}ms' : ''}',
            ),
          ],
          if (item.status.needsUserAction && item.lastError != null) ...[
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.error_outline_rounded,
              color: Vibe.danger,
              text: item.lastError!,
            ),
          ],
          if (item.status.needsUserAction) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context
                      .read<PendingSyncCubit>()
                      .discard(item.quotationId),
                  child: const Text('Discard',
                      style: TextStyle(color: Vibe.muted)),
                ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      context.read<PendingSyncCubit>().retry(item.quotationId),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(QuotationSyncStatus status) => switch (status) {
        QuotationSyncStatus.accepted => Vibe.success,
        QuotationSyncStatus.failed ||
        QuotationSyncStatus.rejected =>
          Vibe.danger,
        QuotationSyncStatus.conflict => Vibe.amber,
        QuotationSyncStatus.syncing ||
        QuotationSyncStatus.submitted =>
          Vibe.violet,
        _ => Vibe.muted,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final QuotationSyncStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(color: color, fontSize: 11.5, height: 1.3)),
        ),
      ],
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done_rounded, size: 40, color: Vibe.success),
            SizedBox(height: 10),
            Text('Everything is synced',
                style:
                    TextStyle(color: Vibe.text, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('No quotations waiting for SAP.',
                style: TextStyle(color: Vibe.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
