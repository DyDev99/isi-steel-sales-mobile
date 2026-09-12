import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_filter_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_filter_state.dart';

void main() {
  group('CustomerFilterCubit', () {
    test('starts with the passed filter as both draft and baseline', () {
      const initial = CustomerFilter(territory: 'North');
      final cubit = CustomerFilterCubit(initial);

      expect(cubit.state.draft, initial);
      expect(cubit.state.initial, initial);
      expect(cubit.state.hasChanges, isFalse);
      addTearDown(cubit.close);
    });

    blocTest<CustomerFilterCubit, CustomerFilterState>(
      'selecting a status marks the draft as changed',
      build: () => CustomerFilterCubit(const CustomerFilter()),
      act: (cubit) => cubit.selectStatus(CustomerStatus.active),
      verify: (cubit) {
        expect(cubit.state.draft.status, CustomerStatus.active);
        expect(cubit.state.hasChanges, isTrue);
        expect(cubit.state.activeCount, 1);
      },
    );

    blocTest<CustomerFilterCubit, CustomerFilterState>(
      'selecting null clears a criterion rather than being ignored',
      build: () =>
          CustomerFilterCubit(const CustomerFilter(territory: 'North')),
      act: (cubit) => cubit.selectTerritory(null),
      verify: (cubit) {
        expect(cubit.state.draft.territory, isNull);
        expect(cubit.state.activeCount, 0);
      },
    );

    blocTest<CustomerFilterCubit, CustomerFilterState>(
      'toggling the open section twice collapses it',
      build: () => CustomerFilterCubit(const CustomerFilter()),
      act: (cubit) => cubit
        ..toggleSection(CustomerFilterSection.status)
        ..toggleSection(CustomerFilterSection.status),
      verify: (cubit) => expect(cubit.state.openSection, isNull),
    );

    blocTest<CustomerFilterCubit, CustomerFilterState>(
      'opening a second section replaces the first',
      build: () => CustomerFilterCubit(const CustomerFilter()),
      act: (cubit) => cubit
        ..toggleSection(CustomerFilterSection.status)
        ..toggleSection(CustomerFilterSection.territory),
      verify: (cubit) => expect(
        cubit.state.openSection,
        CustomerFilterSection.territory,
      ),
    );

    blocTest<CustomerFilterCubit, CustomerFilterState>(
      'reset clears every criterion but preserves the chosen sort order',
      build: () => CustomerFilterCubit(
        const CustomerFilter(
          territory: 'North',
          status: CustomerStatus.active,
          productCategory: 'Rebar',
          sortBy: CustomerSortBy.nameAsc,
        ),
      ),
      act: (cubit) => cubit.reset(),
      verify: (cubit) {
        expect(cubit.state.draft.isEmpty, isTrue);
        expect(cubit.state.activeCount, 0);
        // Resetting filters is not a request to re-sort.
        expect(cubit.state.draft.sortBy, CustomerSortBy.nameAsc);
        expect(cubit.state.territoryQuery, '');
        expect(cubit.state.openSection, isNull);
      },
    );

    blocTest<CustomerFilterCubit, CustomerFilterState>(
      'sort selection alone does not count as an active filter',
      build: () => CustomerFilterCubit(const CustomerFilter()),
      act: (cubit) => cubit.selectSort(CustomerSortBy.valueDesc),
      verify: (cubit) {
        expect(cubit.state.hasChanges, isTrue);
        expect(cubit.state.activeCount, 0);
        expect(cubit.state.hasActiveFilters, isFalse);
      },
    );

    blocTest<CustomerFilterCubit, CustomerFilterState>(
      'searching territory does not alter the draft filter',
      build: () => CustomerFilterCubit(const CustomerFilter()),
      act: (cubit) => cubit.searchTerritory('nor'),
      verify: (cubit) {
        expect(cubit.state.territoryQuery, 'nor');
        expect(cubit.state.hasChanges, isFalse);
      },
    );
  });
}
