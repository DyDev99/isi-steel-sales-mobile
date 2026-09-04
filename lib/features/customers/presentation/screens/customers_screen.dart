import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_code_lookup_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_event.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_state.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customer_create_screen.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_empty_state.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_error_state.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_loading.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_sync_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_quotation.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

enum _QuickAccess {
  all,
  customer,
  salesOrg,
  division,
  recent,
  favorites;

  bool get isGrouped =>
      this == _QuickAccess.customer ||
      this == _QuickAccess.salesOrg ||
      this == _QuickAccess.division;

  String get label => switch (this) {
        _QuickAccess.all => 'customers.all'.tr,
        _QuickAccess.customer => 'customers.group.customer'.tr,
        _QuickAccess.salesOrg => 'customers.group.sales_org'.tr,
        _QuickAccess.division => 'customers.group.division'.tr,
        _QuickAccess.recent => 'customers.recent'.tr,
        _QuickAccess.favorites => 'customers.favorites'.tr,
      };
}

sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  const _HeaderRow(this.title, this.count);
  final String title;
  final int count;
}

class _CustomerRow extends _Row {
  const _CustomerRow(this.customer);
  final Customer customer;
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) =>
                sl<CustomersBloc>()..add(const CustomersLoadRequested())),
        BlocProvider(create: (_) => sl<CustomerSyncCubit>()..syncIfNeeded()),
        BlocProvider(create: (_) => sl<CustomerCodeLookupCubit>()),
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        // The by-code lookup's three outcomes are handled here, and they are
        // deliberately not interchangeable: "absent" invites a registration,
        // "unavailable" must not — offering one when the ERP merely could not
        // be reached creates a duplicate business partner in SAP.
        body: BlocListener<CustomerCodeLookupCubit, CustomerCodeLookupState>(
          listener: _onLookupResult,
          child: BlocBuilder<CustomersBloc, CustomersState>(
            builder: (context, state) {
              return switch (state) {
                CustomersLoaded() => _Loaded(
                    state: state,
                    quickAccess: _quickAccess,
                    onQuickAccessChanged: (q) =>
                        setState(() => _quickAccess = q),
                    scrollController: _scrollController,
                    onOpenDetail: (id) => _openDetail(context, id),
                  ),
                CustomersError(:final message) => CustomerErrorState(
                    message: message,
                    onRetry: () => context
                        .read<CustomersBloc>()
                        .add(const CustomersLoadRequested()),
                  ),
                _ => const CustomerLoading(),
              };
            },
          ),
        ),
      ),
    );
  }

  void _onLookupResult(BuildContext context, CustomerCodeLookupState state) {
    final messenger = ScaffoldMessenger.of(context);

    switch (state) {
      case CodeLookupFound(:final customer):
        // The portal payload carries the platform id, so the ordinary detail
        // screen can open it directly — no second resolution step.
        context.read<CustomerCodeLookupCubit>().reset();
        _openDetail(context, customer.id);

      case CodeLookupAbsent():
        // Safe to point the rep at registration: the code exists nowhere.
        messenger.showSnackBar(
          SnackBar(content: Text('customers.lookup_absent'.tr)),
        );

      case CodeLookupUnavailable():
        // Explicitly NOT an invitation to register.
        messenger.showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('customers.lookup_unavailable'.tr),
        ));

      case CodeLookupFailed(:final message):
        messenger.showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(message),
        ));

      case CodeLookupIdle():
      case CodeLookupInProgress():
        break;
    }
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
        _QuickAccess.all ||
        _QuickAccess.customer ||
        _QuickAccess.salesOrg ||
        _QuickAccess.division =>
          state.items,
        _QuickAccess.recent => state.recent,
        _QuickAccess.favorites =>
          state.items.where((c) => state.favoriteIds.contains(c.id)).toList(),
      };

  List<_Row> _buildRows(List<Customer> customers) {
    if (!quickAccess.isGrouped) {
      return customers.map<_Row>(_CustomerRow.new).toList(growable: false);
    }

    String keyFor(Customer c) => switch (quickAccess) {
          _QuickAccess.customer => c.customerCode.isEmpty
              ? 'customers.unassigned'.tr
              : c.customerCode[0].toUpperCase(),
          _QuickAccess.salesOrg =>
            c.salesOrg?.trim().isNotEmpty == true ? c.salesOrg!.trim() : '—',
          _QuickAccess.division =>
            c.division?.trim().isNotEmpty == true ? c.division!.trim() : '—',
          _ => '',
        };

    final grouped = <String, List<Customer>>{};
    for (final c in customers) {
      grouped.putIfAbsent(keyFor(c), () => <Customer>[]).add(c);
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '—') return 1;
        if (b == '—') return -1;
        return a.compareTo(b);
      });

    return [
      for (final key in keys) ...[
        _HeaderRow(
          key == '—' ? 'customers.unassigned'.tr : key,
          grouped[key]!.length,
        ),
        ...grouped[key]!.map<_Row>(_CustomerRow.new),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final items = _visibleItems;
    final rows = _buildRows(items);

    return RefreshIndicator(
      color: scheme.primary,
      backgroundColor: colors.surfaceSoft,
      onRefresh: () async {
        await context.read<CustomerSyncCubit>().refresh();
        if (context.mounted) {
          context.read<CustomersBloc>().add(const CustomersRefreshRequested());
        }
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.rh(20)),
                  const CustomerSyncStatusBanner(),
                  CustomerSearchBar(
                    query: state.query,
                    onSearchChanged: (q) => context
                        .read<CustomersBloc>()
                        .add(CustomersSearchChanged(q)),
                    // Registers a shop directly. This used to require picking
                    // a won lead first, which meant a rep standing in a shop
                    // that was never in the pipeline could not add it at all.
                    onAddTap: () async {
                      final submitted = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          settings: const RouteSettings(
                            name: CustomerCreateScreen.routeName,
                          ),
                          builder: (_) => const CustomerCreateScreen(),
                        ),
                      );
                      if (submitted == true && context.mounted) {
                        context
                            .read<CustomersBloc>()
                            .add(const CustomersRefreshRequested());
                      }
                    },
                  ),
                  SizedBox(height: context.rh(12)),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              child:
                  BlocBuilder<CustomerCodeLookupCubit, CustomerCodeLookupState>(
                builder: (context, lookup) {
                  // Offered only when the term is code-shaped. A rep typing a
                  // shop name must not be invited to spend a round trip that
                  // can reach the ERP.
                  final code = looksLikeCustomerCode(state.query)
                      ? state.query.trim()
                      : null;
                  return CustomerEmptyState(
                    hasActiveSearchOrFilter: state.query.isNotEmpty,
                    onClearSearchOrFilter: state.query.isNotEmpty
                        ? () => context
                            .read<CustomersBloc>()
                            .add(const CustomersSearchChanged(''))
                        : null,
                    lookupCode: code,
                    onLookupCode: code == null
                        ? null
                        : () => context
                            .read<CustomerCodeLookupCubit>()
                            .lookup(code),
                    isLookingUp: lookup is CodeLookupInProgress,
                  );
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => SizedBox(height: context.rh(10)),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return switch (row) {
                    _HeaderRow(:final title, :final count) => _GroupHeader(
                        key: ValueKey('hdr_$title'),
                        title: title,
                        count: count,
                      ),
                    _CustomerRow(:final customer) => CustomerCard(
                        key: ValueKey(customer.id),
                        customer: customer,
                        isFavorite: state.favoriteIds.contains(customer.id),
                        onTap: () => onOpenDetail(customer.id),
                        onFavoriteToggle: () => context
                            .read<CustomersBloc>()
                            .add(CustomersFavoriteToggled(customer.id)),
                        onCreateQuotationTap: () => openQuotationForCustomer(
                          context,
                          customerId: customer.id,
                          customerName: context.localized(customer.displayName),
                        ),
                      ),
                  };
                },
              ),
            ),
          if (state.isLoadingMore && quickAccess == _QuickAccess.all)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(context.rr(16)),
                child: Center(
                    child: CircularProgressIndicator(color: scheme.primary)),
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
    return SizedBox(
      // Must scale with the label inside it. At 36 fixed, the chips clipped on
      // tablet the moment the type scale went up: a 12.5pt label becomes ~20pt
      // at `expanded`, and with the chip's own vertical padding the row needs
      // ~41pt. A horizontal ListView has to be height-bounded, so the bound
      // scales rather than being removed (FS-A11Y-2).
      height: context.rh(36),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _QuickAccess.values.length,
        separatorBuilder: (_, __) => SizedBox(width: context.rw(8)),
        itemBuilder: (context, index) {
          final value = _QuickAccess.values[index];
          return _Segment(
            label: value.label,
            selected: selected == value,
            onTap: () => onChanged(value),
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({super.key, required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: context.rsp(12.5),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(width: context.rw(8)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: scheme.primary,
                fontSize: context.rsp(10.5),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: context.rw(10)),
          Expanded(child: Divider(color: colors.divider, height: 1)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        // Scales with the label; fixed padding around scaled type is what makes
        // a chip look cramped on tablet even once its row is tall enough.
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(14),
          vertical: context.rh(8),
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? scheme.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : colors.textPrimary,
            fontSize: context.rsp(12.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
