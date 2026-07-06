import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_event.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_state.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_sync_status_banner.dart';

enum _QuickAccess { all, recent, favorites }

/// Directory of approved SAP customers — deliberately not another pipeline
/// board. Every row here already passed Won -> Submitted -> HQ Approved ->
/// SAP-created; there is no create/edit affordance on this screen.
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CustomersBloc>()..add(const CustomersLoadRequested())),
        BlocProvider(create: (_) => sl<CustomerSyncCubit>()..syncIfNeeded()),
      ],
      child: const _CustomersView(),
    );
  }
}

class _CustomersView extends StatefulWidget {
  const _CustomersView();

  @override
  State<_CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<_CustomersView> {
  final _scrollController = ScrollController();
  _QuickAccess _quickAccess = _QuickAccess.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      context.read<CustomersBloc>().add(const CustomersLoadMoreRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, String customerId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CustomerDetailScreen(customerId: customerId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LocalizedBuilder(
      builder: (context) => Scaffold(
        backgroundColor: Vibe.bg,
        body: BlocBuilder<CustomersBloc, CustomersState>(
          builder: (context, state) {
            return switch (state) {
              CustomersLoaded() => _Loaded(
                  state: state,
                  quickAccess: _quickAccess,
                  onQuickAccessChanged: (q) => setState(() => _quickAccess = q),
                  scrollController: _scrollController,
                  onOpenDetail: (id) => _openDetail(context, id),
                ),
              CustomersError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
              _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
            };
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.quickAccess,
    required this.onQuickAccessChanged,
    required this.scrollController,
    required this.onOpenDetail,
  });

  final CustomersLoaded state;
  final _QuickAccess quickAccess;
  final ValueChanged<_QuickAccess> onQuickAccessChanged;
  final ScrollController scrollController;
  final ValueChanged<String> onOpenDetail;

  List<Customer> get _visibleItems => switch (quickAccess) {
        _QuickAccess.all => state.items,
        _QuickAccess.recent => state.recent,
        _QuickAccess.favorites => state.items.where((c) => state.favoriteIds.contains(c.id)).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final territories = state.items.map((c) => c.territory).toSet().toList()..sort();

    return RefreshIndicator(
      color: Vibe.violet,
      backgroundColor: Vibe.bgSoft,
      onRefresh: () async {
        await context.read<CustomerSyncCubit>().refresh();
        if (context.mounted) context.read<CustomersBloc>().add(const CustomersRefreshRequested());
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomerSyncStatusBanner(),
                  CustomerSearchBar(
                    onSearchChanged: (q) => context.read<CustomersBloc>().add(CustomersSearchChanged(q)),
                    hasActiveFilters: !state.filter.isEmpty,
                    onFilterTap: () => showCustomerFilterSheet(
                      context: context,
                      filter: state.filter,
                      territories: territories,
                      onApply: (f) => context.read<CustomersBloc>().add(CustomersFilterChanged(f)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuickAccessRow(selected: quickAccess, onChanged: onQuickAccessChanged),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  quickAccess == _QuickAccess.all ? 'customers.no_customers'.tr : 'customers.nothing_here'.tr,
                  style: const TextStyle(color: Vibe.muted),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final customer = items[index];
                  return CustomerCard(
                    customer: customer,
                    isFavorite: state.favoriteIds.contains(customer.id),
                    onTap: () => onOpenDetail(customer.id),
                    onCall: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('customers.calling'.tr.replaceAll('{phone}', customer.phone)),
                          duration: const Duration(seconds: 1)),
                    ),
                    onCreateOpportunity: () => onOpenDetail(customer.id),
                    onFavoriteToggle: () => context.read<CustomersBloc>().add(CustomersFavoriteToggled(customer.id)),
                  );
                },
              ),
            ),
          if (state.isLoadingMore && quickAccess == _QuickAccess.all)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: Vibe.violet)),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({required this.selected, required this.onChanged});
  final _QuickAccess selected;
  final ValueChanged<_QuickAccess> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Segment(label: 'customers.all'.tr, selected: selected == _QuickAccess.all, onTap: () => onChanged(_QuickAccess.all)),
        const SizedBox(width: 8),
        _Segment(
            label: 'customers.recent'.tr,
            selected: selected == _QuickAccess.recent,
            onTap: () => onChanged(_QuickAccess.recent)),
        const SizedBox(width: 8),
        _Segment(
          label: 'customers.favorites'.tr,
          selected: selected == _QuickAccess.favorites,
          onTap: () => onChanged(_QuickAccess.favorites),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Vibe.violet : Vibe.bgSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Vibe.violet : Vibe.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Vibe.text,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
