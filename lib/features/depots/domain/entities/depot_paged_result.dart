import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot.dart';

class DepotPagedResult extends Equatable {
  const DepotPagedResult(
      {required this.items, required this.page, required this.hasMore});

  final List<Depot> items;
  final int page;
  final bool hasMore;

  @override
  List<Object?> get props => [items, page, hasMore];
}
