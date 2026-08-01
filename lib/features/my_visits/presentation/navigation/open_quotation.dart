import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_builder_screen.dart';

/// Opens the Quotation Builder **for a specific customer**, wired with the
/// catalog/cart/sync blocs it needs.
///
/// This is the single construction path for "quote this shop" so the guided
/// visit flow, the Route Information basket action, and the "Continue Working"
/// resume all build the quotation screen identically — with the checked-in
/// customer as context, instead of sending the rep back to a shop picker they
/// already implicitly chose by checking in.
Future<void> openQuotationForCustomer(
  BuildContext context, {
  required String customerId,
  required String customerName,
}) {
  return Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: QuotationBuilderScreen.routeName),
    builder: (_) => MultiBlocProvider(
      providers: [
        // No catalog pre-load: the builder opens on the guided product
        // configurator, which fetches categories only.
        BlocProvider(create: (_) => sl<CartCubit>()..load()),
        BlocProvider(create: (_) => sl<SyncCubit>()),
      ],
      child: LocalizedBuilder(
        builder: (_) => QuotationBuilderScreen(
          leadId: customerId,
          leadDisplayName: customerName,
        ),
      ),
    ),
  ));
}
