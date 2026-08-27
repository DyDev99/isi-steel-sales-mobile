import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/platform/local_files.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class CartPreviewSection extends StatelessWidget {
  const CartPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final items = state is CartLoaded ? state.items : const [];

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: items.isEmpty
              ? const SizedBox(width: double.infinity)
              : Container(
                  padding: EdgeInsets.all(context.rr(16)),
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border(
                      top: BorderSide(color: colors.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'orders.quotation.cart_preview_title'.tr,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: context.rsp(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.rh(12)),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          color: colors.divider,
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _CartPreviewRow(
                            item: item,
                            // Address the line by its own id — customized lines
                            // share a product id, so keying on product.id would
                            // hit the wrong line.
                            onQuantityChanged: (qty) => context
                                .read<CartCubit>()
                                .updateQuantity(item.id, qty),
                            onRemove: () =>
                                context.read<CartCubit>().removeItem(item.id),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _CartPreviewRow extends StatelessWidget {
  const _CartPreviewRow({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  bool get _hasDrawing =>
      item.drawingImagePath != null && localFileExists(item.drawingImagePath!);

  String? get _customSpecs {
    if (!item.isCustomized) return null;
    final parts = <String>[];
    final m = item.measurements;
    if (m != null && !m.isEmpty) parts.add(m.toSummaryString());
    if (item.appearance != null && item.appearance!.trim().isNotEmpty) {
      parts.add(item.appearance!.trim());
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final specs = _customSpecs;

    return Row(
      children: [
        if (item.isCustomized) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: context.rh(40),
              color: colors.surfaceSoft,
              child: _hasDrawing
                  ? localFileImage((item.drawingImagePath!), fit: BoxFit.cover)
                  : Icon(Icons.tune_rounded,
                      size: context.rr(18), color: colors.accentPurple),
            ),
          ),
          SizedBox(width: context.rw(10)),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      context.localized(item.product.displayName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: context.rsp(13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.isCustomized) ...[
                    SizedBox(width: context.rw(6)),
                    Text('✏️',
                        style: TextStyle(
                            fontSize: context.rsp(11),
                            color: colors.accentPurple)),
                  ],
                ],
              ),
              if (specs != null) ...[
                SizedBox(height: context.rh(2)),
                Text(
                  specs,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              SizedBox(height: context.rh(2)),
              Text(
                '\$${item.lineTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.accentPurple,
                  fontSize: context.rsp(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                iconColor: colors.textPrimary,
                onTap: () => onQuantityChanged(item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.quantity.toStringAsFixed(0),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                iconColor: colors.textPrimary,
                onTap: () => onQuantityChanged(item.quantity + 1),
              ),
            ],
          ),
        ),
        SizedBox(width: context.rw(8)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(context.rr(6)),
              child: Icon(
                Icons.close_rounded,
                size: context.rr(16),
                color: colors.textHint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: context.rh(24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(6),
            boxShadow: colors.cardShadow,
          ),
          child: Icon(icon, size: context.rr(14), color: iconColor),
        ),
      ),
    );
  }
}
