import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';

enum DepotSelectionStatus { initial, loading, loaded, empty, error }

/// State for the Depot/Shop selection screen. Single immutable class with a
/// status enum (same style as `PendingSyncState`) — the shop list and the
/// current selection live alongside the status so the Continue button and the
/// selected indicator update without extra rebuilds.
class DepotSelectionState extends Equatable {
  const DepotSelectionState({
    this.status = DepotSelectionStatus.initial,
    this.shops = const [],
    this.query = '',
    this.selectedId,
    this.message,
  });

  final DepotSelectionStatus status;
  final List<Customer> shops;
  final String query;
  final String? selectedId;
  final String? message;

  bool get hasSelection => selectedId != null;

  DepotSelectionState copyWith({
    DepotSelectionStatus? status,
    List<Customer>? shops,
    String? query,
    String? Function()? selectedId,
    String? message,
  }) {
    return DepotSelectionState(
      status: status ?? this.status,
      shops: shops ?? this.shops,
      query: query ?? this.query,
      selectedId: selectedId != null ? selectedId() : this.selectedId,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, shops, query, selectedId, message];
}
