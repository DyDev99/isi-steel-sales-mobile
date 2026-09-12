import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/add_customer_bottom_sheet.dart';

/// Full-screen Create Business Partner flow.
///
/// The form itself is shared with the previous sheet implementation; keeping
/// its BLoC and validation in one place avoids diverging registration flows.
class CustomerCreateScreen extends StatelessWidget {
  const CustomerCreateScreen({super.key});

  static const routeName = 'customer-create';

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('customers.add'.tr),
      ),
      body: SafeArea(
        top: false,
        child: AddCustomerBottomSheet(
          isTablet: isTablet,
          isFullScreen: true,
        ),
      ),
    );
  }
}
