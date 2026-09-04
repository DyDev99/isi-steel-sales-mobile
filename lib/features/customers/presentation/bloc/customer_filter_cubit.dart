import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_filter_state.dart';

/// Owns the filter sheet's draft state.
///
/// A cubit rather than `setState` for three reasons: the draft survives the
/// sheet's internal rebuilds, `BlocSelector` lets each group subscribe to only
/// the slice it renders (so selecting a status does not rebuild the territory
/// list), and the apply/reset transitions become unit-testable without pumping
/// a widget.
///
/// Scope note: this cubit holds **no** SAP master data. Per ADR-009 the filter
/// applies only criteria the local Drift database can satisfy — `status`,
/// `territory`, `productCategory` and sort order, all of which reach
/// `CustomerDao.browse`. SAP Helper lists are cached by `MasterDataRepository`
/// for customer create/update; wiring them here would render controls that
/// cannot change the result set.
class CustomerFilterCubit extends Cubit<CustomerFilterState> {
  CustomerFilterCubit(CustomerFilter initial)
      : super(CustomerFilterState.from(initial));

  /// Opens [section], or collapses it when it is already open.
  void toggleSection(CustomerFilterSection section) {
    final next = state.openSection == section ? null : section;
    emit(state.copyWith(openSection: () => next));
  }

  void selectStatus(CustomerStatus? status) {
    emit(state.copyWith(draft: state.draft.copyWith(status: () => status)));
  }

  void selectTerritory(String? territory) {
    emit(state.copyWith(
      draft: state.draft.copyWith(territory: () => territory),
    ));
  }

  void selectProductCategory(String? category) {
    emit(state.copyWith(
      draft: state.draft.copyWith(productCategory: () => category),
    ));
  }

  void selectSort(CustomerSortBy sort) {
    emit(state.copyWith(draft: state.draft.copyWith(sortBy: sort)));
  }

  void searchTerritory(String query) {
    emit(state.copyWith(territoryQuery: query));
  }

  /// Clears every criterion but keeps the chosen sort order — resetting filters
  /// is not a request to re-sort, and silently changing sort here would look
  /// like a bug to the user.
  void reset() {
    emit(state.copyWith(
      draft: CustomerFilter(sortBy: state.draft.sortBy),
      openSection: () => null,
      territoryQuery: '',
    ));
  }
}
