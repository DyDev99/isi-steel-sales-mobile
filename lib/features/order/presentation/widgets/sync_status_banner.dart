import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync_state.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        return switch (state) {
          SyncInProgress(:final isInitial) => _Banner(
              color: Vibe.violet,
              icon: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Vibe.violet),
              ),
              text: isInitial ? 'Downloading product catalog…' : 'Syncing latest changes…',
            ),
          SyncFailed(:final message) =>
            _Banner(color: Vibe.danger, icon: const Icon(Icons.cloud_off_rounded, size: 16, color: Vibe.danger), text: message),
          SyncSucceeded(:final upserted, :final deleted) when upserted > 0 || deleted > 0 => _Banner(
              color: Vibe.success,
              icon: const Icon(Icons.check_circle_rounded, size: 16, color: Vibe.success),
              text: '$upserted updated${deleted > 0 ? ', $deleted removed' : ''}',
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});
  final Color color;
  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
