import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_by_id.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/depot_stock_count_state.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/browse_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

/// Loads the inventory to count for a selected depot/shop and owns the live
/// counts (counting is business state, so it lives here — never `setState`).
///
/// Shop == customer (per the chosen data model): the shop is resolved via
/// [GetCustomerById] for display/validation, and the SKUs to count come from
/// the offline product catalog via [BrowseProducts]. A missing/invalid shop id
/// resolves to a proper error state rather than a crash.
class DepotStockCountCubit extends Cubit<DepotStockCountState> {
  DepotStockCountCubit({
    required GetCustomerById getCustomerById,
    required BrowseProducts browseProducts,
  })  : _getCustomerById = getCustomerById,
        _browseProducts = browseProducts,
        super(const DepotStockCountState());

  final GetCustomerById _getCustomerById;
  final BrowseProducts _browseProducts;

  static const _pageSize = 40;

  Future<void> load(String? shopId) async {
    if (shopId == null || shopId.isEmpty) {
      emit(state.copyWith(
        status: DepotStockCountStatus.error,
        message: 'No depot or shop was selected.',
      ));
      return;
    }

    emit(state.copyWith(status: DepotStockCountStatus.loading));

    final customerResult = await _getCustomerById(CustomerIdParams(shopId));
    final shopName =
        customerResult.when(success: (c) => c.shopName, failure: (_) => null);
    if (shopName == null) {
      emit(state.copyWith(
        status: DepotStockCountStatus.error,
        message: 'Could not load the selected depot/shop.',
      ));
      return;
    }

    final productsResult = await _browseProducts(
      const BrowseProductsParams(page: 0, pageSize: _pageSize),
    );
    productsResult.when(
      success: (paged) {
        final lines = paged.items.map(_lineOf).toList();
        emit(state.copyWith(
          status: lines.isEmpty
              ? DepotStockCountStatus.empty
              : DepotStockCountStatus.loaded,
          shopName: shopName,
          lines: lines,
        ));
      },
      failure: (f) => emit(state.copyWith(
        status: DepotStockCountStatus.error,
        shopName: shopName,
        message: f.message,
      )),
    );
  }

  /// Adjusts a line's counted quantity, clamped to a sane range. [delta] is
  /// typically ±1 (tap) or ±10 (long-press).
  void step(String productId, int delta) {
    final lines = [
      for (final line in state.lines)
        if (line.productId == productId)
          line.copyWith(count: (line.count + delta).clamp(0, 99999))
        else
          line,
    ];
    emit(state.copyWith(lines: lines));
  }

  StockCountLine _lineOf(Product p) => StockCountLine(
        productId: p.id,
        name: p.name,
        subtitle: [p.brand, p.sku].where((s) => s.isNotEmpty).join(' · '),
      );
}
