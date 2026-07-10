import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/pending_sync_sheet.dart';

/// A compact "🔄 Pending Sync (N)" pill that opens the Sync Center. Rendered
/// only when there's outstanding work; tapping never navigates away — it opens
/// a bottom sheet the user can dismiss.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PendingSyncCubit, PendingSyncState>(
      builder: (context, state) {
        final outstanding = state.counts.outstanding;
        if (outstanding == 0) return const SizedBox.shrink();
        final hasProblems =
            state.counts.failed > 0 || state.counts.conflict > 0;
        final accent = hasProblems ? Vibe.danger : Vibe.violet;
        return InkWell(
          onTap: () => showPendingSyncSheet(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Vibe.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
              boxShadow: Vibe.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isSyncing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent),
                  )
                else
                  Icon(Icons.sync_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Pending Sync ($outstanding)',
                  style: TextStyle(
                      color: accent, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                if (hasProblems) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.error_rounded, size: 15, color: Vibe.danger),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
