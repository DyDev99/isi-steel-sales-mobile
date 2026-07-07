import 'package:equatable/equatable.dart';

sealed class RevenueEvent extends Equatable {
  const RevenueEvent();

  @override
  List<Object?> get props => [];
}

/// Loads products, categories, discount options and the customer credit
/// summary in one shot. Dispatched once when the screen mounts.
class RevenueStarted extends RevenueEvent {
  const RevenueStarted();
}

/// Re-runs [RevenueStarted] after a load failure.
class RevenueRetryRequested extends RevenueEvent {
  const RevenueRetryRequested();
}

class RevenueSearchChanged extends RevenueEvent {
  const RevenueSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// `null` clears the category filter (selects "All").
class RevenueCategorySelected extends RevenueEvent {
  const RevenueCategorySelected(this.categoryId);
  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class RevenueDiscountSelected extends RevenueEvent {
  const RevenueDiscountSelected(this.discountId);
  final String discountId;

  @override
  List<Object?> get props => [discountId];
}

/// `delta` is `+1`/`-1` from the product card's quantity stepper. Quantity
/// is clamped to `0` (removes the line) and to the product's stock.
class RevenueCartQuantityChanged extends RevenueEvent {
  const RevenueCartQuantityChanged({required this.productId, required this.delta});
  final String productId;
  final int delta;

  @override
  List<Object?> get props => [productId, delta];
}
