import 'package:equatable/equatable.dart';

class VisitStockUpdate extends Equatable {
  const VisitStockUpdate({
    required this.id,
    required this.stopId,
    required this.productId,
    required this.productName,
    required this.countedQuantity,
    required this.notes,
  });

  final String id;
  final String stopId;
  final String productId;
  final String productName;
  final double countedQuantity;
  final String notes;

  @override
  List<Object?> get props => [id, stopId, productId, countedQuantity];
}
