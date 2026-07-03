import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';

enum PendingOrderStatus { pendingSync, synced }

class PendingOrder extends Equatable {
  const PendingOrder({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.status,
    required this.createdAt,
    this.leadId,
  });

  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final PendingOrderStatus status;
  final DateTime createdAt;
  final String? leadId;

  @override
  List<Object?> get props => [id, items, subtotal, tax, discount, total, status, createdAt, leadId];
}
