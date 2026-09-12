import 'package:equatable/equatable.dart';

sealed class CustomerSyncState extends Equatable {
  const CustomerSyncState();
  @override
  List<Object?> get props => [];
}

final class CustomerSyncIdle extends CustomerSyncState {
  const CustomerSyncIdle();
}

final class CustomerSyncInProgress extends CustomerSyncState {
  const CustomerSyncInProgress({required this.isInitial});
  final bool isInitial;
  @override
  List<Object?> get props => [isInitial];
}

final class CustomerSyncSucceeded extends CustomerSyncState {
  const CustomerSyncSucceeded(
      {required this.upserted, required this.deleted, required this.syncedAt});
  final int upserted;
  final int deleted;
  final DateTime syncedAt;
  @override
  List<Object?> get props => [upserted, deleted, syncedAt];
}

final class CustomerSyncFailed extends CustomerSyncState {
  const CustomerSyncFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
