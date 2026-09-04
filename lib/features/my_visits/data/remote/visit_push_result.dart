import 'package:equatable/equatable.dart';

/// Response to a [VisitPushBatch] push — which row ids the backend accepted
/// vs. rejected (kept `pending` for a future retry), and when it happened.
class VisitPushResult extends Equatable {
  const VisitPushResult(
      {required this.acceptedIds,
      required this.rejectedIds,
      required this.syncedAt});

  final List<String> acceptedIds;
  final List<String> rejectedIds;
  final DateTime syncedAt;

  @override
  List<Object?> get props => [acceptedIds, rejectedIds, syncedAt];
}
