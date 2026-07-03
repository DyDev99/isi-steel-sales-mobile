import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';

/// A single entry on a customer's timeline — merges rep-logged activity
/// (calls, visits, notes) with system-generated events (opportunity
/// created, order placed) into one chronological feed.
class CustomerActivity extends Equatable {
  const CustomerActivity({
    required this.id,
    required this.customerId,
    required this.type,
    required this.summary,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String customerId;
  final CustomerActivityType type;
  final String summary;
  final DateTime createdAt;
  final bool synced;

  @override
  List<Object?> get props => [id, customerId, type, summary, createdAt, synced];
}
