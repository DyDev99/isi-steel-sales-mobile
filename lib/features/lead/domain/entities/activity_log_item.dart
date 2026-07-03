import 'package:equatable/equatable.dart';

enum ActivityLogKind {
  leadCreated,
  siteVisit,
  gpsCaptured,
  photoUploaded,
  documentCollected,
  creditSubmitted,
  creditApproved,
  customerCreated,
  stageChanged,
  orderReceived,
  note,
}

class ActivityLogItem extends Equatable {
  const ActivityLogItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.actor,
  });

  final String id;
  final ActivityLogKind kind;
  final String title;
  final String description;
  final DateTime timestamp;
  final String actor;

  @override
  List<Object?> get props => [id, kind, title, description, timestamp, actor];
}
