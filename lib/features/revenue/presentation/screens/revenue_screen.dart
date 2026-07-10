import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_bloc.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_event.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_state.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/cart_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/category_chip_list.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/customer_credit_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/discount_card.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/product_grid.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/revenue_bottom_action_bar.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/revenue_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/revenue_status_views.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/main_app_bar.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  static const routeName = '/revenue';

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: LocalizedBuilder(builder: (_) => const ProfileScreen()),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Column(
        children: [
          MainAppBar(
            title: 'revenue.title'.tr,
            currentTabIndex:
                1, // any non-zero index renders the standard (non-home) bar style
            onBackToHomeTap: () => Navigator.of(context).maybePop(),
            onAvatarTap: () => _openProfile(context),
          ),
          Expanded(
            child: BlocBuilder<RevenueBloc, RevenueState>(
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(
                        child: _RevenueBody(
                            state: state, searchController: _searchController)),
                    if (state.status == RevenueStatus.loaded)
                      RevenueBottomActionBar(
                        subtotal: state.cartSubtotal,
                        discountAmount: state.discountAmount,
                        total: state.cartTotal,
                        enabled: state.cartItemCount > 0,
                        onCreateOrder: () => _showCreateOrderSnackbar(context),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateOrderSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('revenue.cart.order_created'.tr)),
    );
  }
}

class _RevenueBody extends StatelessWidget {
  const _RevenueBody({required this.state, required this.searchController});

  final RevenueState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    if (state.status == RevenueStatus.error) {
      return RevenueErrorView(
        message: state.errorMessage,
        onRetry: () =>
            context.read<RevenueBloc>().add(const RevenueRetryRequested()),
      );
    }

    final isLoading = state.status == RevenueStatus.initial ||
        state.status == RevenueStatus.loading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        RevenueSearchBar(
          controller: searchController,
          onChanged: (query) =>
              context.read<RevenueBloc>().add(RevenueSearchChanged(query)),
        ),
        const SizedBox(height: 14),
        if (state.customerCredit != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CustomerCreditSummaryCard(
              viewModel: RevenueViewModelMapper.toCreditSummaryViewModel(
                  state.customerCredit!),
            ),
          ),
        CategoryChipList(
          categories: RevenueViewModelMapper.toCategoryChips(state.categories,
              selectedId: state.selectedCategoryId),
          onSelect: (categoryId) => context
              .read<RevenueBloc>()
              .add(RevenueCategorySelected(categoryId)),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const RevenueLoadingView()
        else if (state.isEmpty)
          const RevenueEmptyView()
        else
          ProductGrid(
            products: [
              for (final product in state.filteredProducts)
                RevenueViewModelMapper.toProductViewModel(
                  product,
                  quantityInCart: state.cartQuantities[product.id] ?? 0,
                ),
            ],
            onIncrement: (productId) => context.read<RevenueBloc>().add(
                RevenueCartQuantityChanged(productId: productId, delta: 1)),
            onDecrement: (productId) => context.read<RevenueBloc>().add(
                RevenueCartQuantityChanged(productId: productId, delta: -1)),
          ),
        if (!isLoading) ...[
          const SizedBox(height: 20),
          DiscountCard(
            options: RevenueViewModelMapper.toDiscountChips(
                state.discountOptions,
                selectedId: state.selectedDiscountId),
            onSelected: (discountId) => context
                .read<RevenueBloc>()
                .add(RevenueDiscountSelected(discountId)),
          ),
          const SizedBox(height: 14),
          CartSummaryCard(
              itemCount: state.cartItemCount, subtotal: state.cartSubtotal),
        ],
      ],
    );
  }
}
