import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';

sealed class CatalogEvent extends Equatable {
  const CatalogEvent();
  @override
  List<Object?> get props => [];
}

final class CatalogLoadRequested extends CatalogEvent {
  const CatalogLoadRequested();
}

final class CatalogRefreshRequested extends CatalogEvent {
  const CatalogRefreshRequested();
}

final class CatalogLoadMoreRequested extends CatalogEvent {
  const CatalogLoadMoreRequested();
}

final class CatalogSearchChanged extends CatalogEvent {
  const CatalogSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class CatalogFilterChanged extends CatalogEvent {
  const CatalogFilterChanged(this.filter);
  final ProductFilter filter;
  @override
  List<Object?> get props => [filter];
}
