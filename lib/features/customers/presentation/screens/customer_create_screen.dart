import 'package:flutter/material.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary,
              scheme.primary.withValues(alpha: 0.2), // Fades down
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: AddCustomerBottomSheet(
            isTablet: isTablet,
            isFullScreen: true,
          ),
        ),
      ),
    );
  }
}
