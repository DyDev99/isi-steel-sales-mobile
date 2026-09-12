import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';

sealed class QuotationListState extends Equatable {
  const QuotationListState();

  @override
  List<Object?> get props => [];
}

final class QuotationListInitial extends QuotationListState {
  const QuotationListInitial();
}

final class QuotationListLoading extends QuotationListState {
  const QuotationListLoading();
}

final class QuotationListLoaded extends QuotationListState {
  const QuotationListLoaded({
    required this.quotations,
    required this.selectedGroup,
    required this.page,
    required this.hasMore,
    this.customerId,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  final List<QuotationSummary> quotations;
  final QuotationStatusGroup? selectedGroup;
  final int page;
  final bool hasMore;
  final String? customerId;
  final bool isRefreshing;
  final bool isLoadingMore;

  QuotationListLoaded copyWith({
    List<QuotationSummary>? quotations,
    QuotationStatusGroup? Function()? selectedGroup,
    int? page,
    bool? hasMore,
    String? Function()? customerId,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return QuotationListLoaded(
      quotations: quotations ?? this.quotations,
      selectedGroup: selectedGroup != null ? selectedGroup() : this.selectedGroup,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      customerId: customerId != null ? customerId() : this.customerId,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        quotations,
        selectedGroup,
        page,
        hasMore,
        customerId,
        isRefreshing,
        isLoadingMore,
      ];
}

final class QuotationListError extends QuotationListState {
  const QuotationListError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
