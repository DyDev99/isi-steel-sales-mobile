import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/pending_sync_sheet.dart';

/// A gold-framed "Pending Sync" pill badge with dual-ring avatar styling.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key});

  static const Color _goldBorderColor = Color(0xFFCBA135);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PendingSyncCubit, PendingSyncState>(
      builder: (context, state) {
        final outstanding = state.counts.outstanding;
        if (outstanding == 0) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final hasProblems =
            state.counts.failed > 0 || state.counts.conflict > 0;
        final accent = hasProblems ? scheme.error : scheme.primary;

        return InkWell(
          onTap: () => showPendingSyncSheet(context),
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: _goldBorderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dual-Bordered Icon Container
                Container(
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _goldBorderColor.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: state.isSyncing
                      ? SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: accent),
                        )
                      : Icon(Icons.sync_rounded, size: 14.sp, color: accent),
                ),
                SizedBox(width: 8.w),
                Text(
                  'sync.pending_badge'.trParams({'count': outstanding}),
                  style: TextStyle(
                    color: accent,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasProblems) ...[
                  SizedBox(width: 6.w),
                  Icon(Icons.error_rounded, size: 15.sp, color: scheme.error),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
