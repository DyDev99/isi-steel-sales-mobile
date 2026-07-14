import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';

class QuotationBottomBar extends StatelessWidget {
  const QuotationBottomBar({
    super.key,
    required this.onSave,
    this.onBack,
    required this.discount,
  });

  final VoidCallback onSave;
  final VoidCallback? onBack;
  final int discount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final items = state is CartLoaded ? state.items : const [];

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: onBack ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: items.isEmpty ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'orders.quotation.save_to_sap'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}