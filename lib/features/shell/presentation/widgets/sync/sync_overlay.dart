import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';

/// Wraps the shell so that when connectivity is *restored* and quotations are
/// waiting, a non-intrusive "Sync Now / Later" snackbar appears. This is the
/// only reaction to reconnection — the spec forbids opening screens or
/// navigating. "Later" is simply dismissing the snackbar.
class ReconnectSyncListener extends StatelessWidget {
  const ReconnectSyncListener({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityStatus>(
      listenWhen: (prev, curr) =>
          prev == ConnectivityStatus.offline &&
          curr == ConnectivityStatus.online,
      listener: _onReconnected,
      child: child,
    );
  }

  void _onReconnected(BuildContext context, ConnectivityStatus _) {
    final pendingCubit = context.read<PendingSyncCubit>();
    final pending = pendingCubit.state.counts.pending;
    if (pending == 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          backgroundColor: Vibe.slate,
          content: Text(
            'Internet connected · $pending quotation${pending == 1 ? '' : 's'} waiting to sync',
            style: const TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Sync Now',
            textColor: Colors.white,
            onPressed: pendingCubit.syncNow,
          ),
        ),
      );
  }
}
