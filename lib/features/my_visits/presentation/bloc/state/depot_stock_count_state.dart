import 'package:equatable/equatable.dart';

enum DepotStockCountStatus { initial, loading, loaded, empty, error }

/// One SKU being counted at the selected depot/shop.
class StockCountLine extends Equatable {
  const StockCountLine({
    required this.productId,
    required this.name,
    required this.subtitle,
    this.count = 0,
  });

  final String productId;
  final String name;
  final String subtitle;
  final int count;

  bool get isOutOfStock => count == 0;

  StockCountLine copyWith({int? count}) => StockCountLine(
        productId: productId,
        name: name,
        subtitle: subtitle,
        count: count ?? this.count,
      );

  @override
  List<Object?> get props => [productId, name, subtitle, count];
}

class DepotStockCountState extends Equatable {
  const DepotStockCountState({
    this.status = DepotStockCountStatus.initial,
    this.shopName,
    this.lines = const [],
    this.message,
  });

  final DepotStockCountStatus status;
  final String? shopName;
  final List<StockCountLine> lines;
  final String? message;

  int get countedSkus => lines.where((l) => l.count > 0).length;

  DepotStockCountState copyWith({
    DepotStockCountStatus? status,
    String? shopName,
    List<StockCountLine>? lines,
    String? message,
  }) {
    return DepotStockCountState(
      status: status ?? this.status,
      shopName: shopName ?? this.shopName,
      lines: lines ?? this.lines,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, shopName, lines, message];
}
