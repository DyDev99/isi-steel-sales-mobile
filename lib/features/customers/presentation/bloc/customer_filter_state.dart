import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';

/// Which collapsible group is currently open. Exactly one at a time, so the
/// sheet stays short and the user is guided top-to-bottom instead of scrolling
/// a wall of expanded chips.
enum CustomerFilterSection { status, territory, productCategory, sort }

/// Draft state for the filter sheet.
///
/// Deliberately separate from `CustomersState`: editing a draft must not
/// re-query the customer list on every tap. Only [CustomerFilterSheet]'s apply
/// action pushes the draft into `CustomersBloc`, which is what keeps the list
/// from rebuilding while the user is still choosing.
class CustomerFilterState extends Equatable {
  const CustomerFilterState({
    required this.draft,
    required this.initial,
    this.openSection,
    this.territoryQuery = '',
  });

  const CustomerFilterState.from(CustomerFilter filter)
      : draft = filter,
        initial = filter,
        openSection = null,
        territoryQuery = '';

  final CustomerFilter draft;

  /// The filter as it was when the sheet opened — lets the UI enable "Apply"
  /// only when something actually changed.
  final CustomerFilter initial;

  final CustomerFilterSection? openSection;
  final String territoryQuery;

  bool get hasChanges => draft != initial;
  bool get hasActiveFilters => !draft.isEmpty;

  /// Count shown on the sheet header and the list's filter button.
  int get activeCount => [
        draft.status != null,
        draft.territory != null,
        draft.productCategory != null,
      ].where((selected) => selected).length;

  CustomerFilterState copyWith({
    CustomerFilter? draft,
    CustomerFilterSection? Function()? openSection,
    String? territoryQuery,
  }) {
    return CustomerFilterState(
      draft: draft ?? this.draft,
      initial: initial,
      openSection: openSection != null ? openSection() : this.openSection,
      territoryQuery: territoryQuery ?? this.territoryQuery,
    );
  }

  @override
  List<Object?> get props => [draft, initial, openSection, territoryQuery];
}
