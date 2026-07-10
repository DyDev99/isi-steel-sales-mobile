import 'package:equatable/equatable.dart';

enum NotificationKind {
  creditApproved,
  leadAssigned,
  opportunityMoved,
  creditPending,
  followUpDue
}

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        kind: kind,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );

  @override
  List<Object?> get props => [id, kind, title, body, timestamp, isRead];
}
