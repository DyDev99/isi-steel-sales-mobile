import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
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
  final VoidCallback? onBack; // Optional custom back navigation hook
  final int discount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final items = state is CartLoaded ? state.items : const [];

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Vibe.surface,
            border: Border(top: BorderSide(color: Vibe.stroke)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  // Outlined Back Button
                  OutlinedButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Vibe.stroke, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
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

                  // Expanded Primary Save Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: items.isEmpty ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Vibe.violet,
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
