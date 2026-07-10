import 'package:equatable/equatable.dart';

sealed class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

/// No sync attempted yet this session.
final class SyncIdle extends SyncState {
  const SyncIdle();
}

final class SyncInProgress extends SyncState {
  const SyncInProgress({required this.isInitial});
  final bool isInitial;
  @override
  List<Object?> get props => [isInitial];
}

final class SyncSucceeded extends SyncState {
  const SyncSucceeded(
      {required this.upserted, required this.deleted, required this.syncedAt});
  final int upserted;
  final int deleted;
  final DateTime syncedAt;
  @override
  List<Object?> get props => [upserted, deleted, syncedAt];
}

final class SyncFailed extends SyncState {
  const SyncFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
