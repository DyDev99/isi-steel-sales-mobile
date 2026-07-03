import 'package:equatable/equatable.dart';

/// Rep-owned, offline-first. Never touched by sync from SAP.
class CustomerNote extends Equatable {
  const CustomerNote({
    required this.id,
    required this.customerId,
    required this.body,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String customerId;
  final String body;
  final DateTime createdAt;
  final bool synced;

  @override
  List<Object?> get props => [id, customerId, body, createdAt, synced];
}
