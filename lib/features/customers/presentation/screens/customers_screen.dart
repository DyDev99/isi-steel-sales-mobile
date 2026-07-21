import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/add_customer_bottom_sheet.dart';
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
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_state.dart';

/// How the directory is presented.
///
/// The first four are SAP-shaped views of the same result set: they group the
/// list rather than narrowing it, so a rep can scan the directory by account
/// code or by sales area without losing rows. Actual narrowing stays in the
/// filter sheet, which is why selecting a view never hides a customer.
///
/// `recent` / `favorites` are retained alongside them — both are backed by real
/// DAO tables and usecases, and dropping the chips would have orphaned working
/// features (and the `favorite` / `lastVisit` fields).
enum _QuickAccess {
  all,
  customer,
  salesOrg,
  division,
  recent,
  favorites;

  /// Views that group into sections instead of rendering one flat list.
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

/// One rendered row: either a section header or a customer.
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

/// Directory of approved SAP customers — deliberately not another pipeline
/// board. Every row here already passed Won -> Submitted -> HQ Approved ->
/// SAP-created; there is no create/edit affordance on this screen.
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
        // Added PipelineBloc provider to retrieve won leads similarly to the Home view
        BlocProvider(
          create: (_) => sl<PipelineBloc>()..add(const PipelineLoadRequested()),
        ),
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
              CustomersError(:final message) => Center(
                  child: Text(message,
                      style:
                          TextStyle(color: context.appColors.textSecondary))),
              _ => Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary)),
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
        _QuickAccess.all ||
        _QuickAccess.customer ||
        _QuickAccess.salesOrg ||
        _QuickAccess.division =>
          state.items,
        _QuickAccess.recent => state.recent,
        _QuickAccess.favorites =>
          state.items.where((c) => state.favoriteIds.contains(c.id)).toList(),
      };

  /// Flattens the visible customers into headers + rows for the current view.
  ///
  /// Grouping is done here rather than in the bloc because it is a pure
  /// presentation concern — the same result set, re-sectioned. Keeping it out
  /// of the bloc means switching views costs no query and no state emission.
  List<_Row> _buildRows(List<Customer> customers) {
    if (!quickAccess.isGrouped) {
      return customers.map<_Row>(_CustomerRow.new).toList(growable: false);
    }

    String keyFor(Customer c) => switch (quickAccess) {
          // Group by the account-code prefix so a directory of thousands
          // collapses into scannable buckets rather than one header per row.
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

    // Sort keys alphabetically, but always sink the "unassigned" bucket to the
    // bottom — an unassigned sales area is noise, not a heading a rep wants
    // first.
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
    // Both option lists are derived from the loaded rows, so the sheet needs no
    // network call. Caveat: `state.items` is the currently-paged slice, so a
    // territory or category that exists only on an unloaded page won't appear
    // until it is scrolled in — see the note in the customer-filter section of
    // ADR-009's open questions.
    //
    // `whereType<String>()` is load-bearing, not defensive: `Customer.territory`
    // is nullable because customers synced from SAP carry no territory, so the
    // filter offers only the territories actually present rather than surfacing
    // an "unknown" bucket.
    final territories = state.items
        .map((c) => c.territory)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final productCategories =
        state.items.expand((c) => c.productsPurchased).toSet().toList()..sort();

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const CustomerSyncStatusBanner(),
                  CustomerSearchBar(
                    onSearchChanged: (q) => context
                        .read<CustomersBloc>()
                        .add(CustomersSearchChanged(q)),
                    hasActiveFilters: !state.filter.isEmpty,
                    onFilterTap: () => showCustomerFilterSheet(
                      context: context,
                      filter: state.filter,
                      territories: territories,
                      productCategories: productCategories,
                      onApply: (f) => context
                          .read<CustomersBloc>()
                          .add(CustomersFilterChanged(f)),
                    ),
                    onAddTap: () {
                      // Obtains the PipelineBloc state exactly like QuickActionsSection
                      final pipelineState = context.read<PipelineBloc>().state;
                      if (pipelineState is PipelineLoaded) {
                        final wonLeads =
                            pipelineState.columns[PipelineStage.won] ?? [];

                        showModalBottomSheet(
                          context: context,
                          backgroundColor: context.appColors.surfaceSoft,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(22)),
                          ),
                          builder: (_) =>
                              AddCustomerBottomSheet(wonLeads: wonLeads),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickAccessRow(
                      selected: quickAccess, onChanged: onQuickAccessChanged),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  quickAccess == _QuickAccess.all
                      ? 'customers.no_customers'.tr
                      : 'customers.nothing_here'.tr,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return switch (row) {
                    _HeaderRow(:final title, :final count) => _GroupHeader(
                        // Keyed so a view switch animates headers in/out
                        // instead of recycling one into another's text.
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
                      ),
                  };
                },
              ),
            ),
          if (state.isLoadingMore && quickAccess == _QuickAccess.all)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
    // Six chips no longer fit a phone width, so the row scrolls horizontally
    // rather than overflowing or shrinking the labels to unreadable sizes.
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _QuickAccess.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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

/// Section heading for the grouped views (Customer / Sales Org / Division).
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
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
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
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? scheme.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : colors.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
