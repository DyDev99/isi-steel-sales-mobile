import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/platform/local_files.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_material_number.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/stock_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/stock_availability_badge.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// The cart, reviewed before saving — and the one place stock is checked
/// eagerly rather than on commitment.
///
/// Everywhere else a check is spent only when a rep singles a material out,
/// because a scrolling catalog would otherwise cost a live ERP round trip per
/// card. The cart is the opposite case: every line here is already a
/// commitment, there are rarely more than a dozen, and the rep is about to
/// turn them into a quotation. Finding out at that moment that SAP will not
/// accept one of them is the entire point.
class CartPreviewSection extends StatefulWidget {
  const CartPreviewSection({super.key});

  @override
  State<CartPreviewSection> createState() => _CartPreviewSectionState();
}

class _CartPreviewSectionState extends State<CartPreviewSection> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so the read happens against a mounted tree rather
    // than mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAll(context.read<CartCubit>().state);
    });
  }

  /// `ensure` deduplicates in-flight requests and holds a verdict for five
  /// minutes, so a cart that rebuilds on every quantity tap does not re-ask.
  void _checkAll(CartState state) {
    if (state is! CartLoaded) return;
    final stock = context.read<StockCubit>();
    for (final item in state.items) {
      stock.ensure(item.product.materialNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return BlocConsumer<CartCubit, CartState>(
      // A line added after the first frame gets checked too.
      listener: (_, state) => _checkAll(state),
      builder: (context, state) {
        final items = state is CartLoaded ? state.items : const <CartItem>[];

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
                      BlocBuilder<StockCubit,
                          Map<String, MaterialAvailability>>(
                        builder: (context, stock) => ListView.separated(
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
                              stock: stock[item.product.materialNumber],
                              // Address the line by its own id — customized
                              // lines share a product id, so keying on
                              // product.id would hit the wrong line.
                              onQuantityChanged: (qty) => context
                                  .read<CartCubit>()
                                  .updateQuantity(item.id, qty),
                              onRemove: () =>
                                  context.read<CartCubit>().removeItem(item.id),
                            );
                          },
                        ),
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
    this.stock,
  });

  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;
  final MaterialAvailability? stock;

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
    // Status only. The band never gates: `Low` is a warning about how much,
    // not a refusal, and there is no on-hand figure in this API to cap against.
    final canIncrease = stock?.canOrder ?? true;

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
              Row(
                children: [
                  Text(
                    '\$${item.lineTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colors.accentPurple,
                      fontSize: context.rsp(12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (stock != null) ...[
                    SizedBox(width: context.rw(6)),
                    Flexible(
                      child: StockAvailabilityBadge(
                          availability: stock, compact: true),
                    ),
                  ],
                ],
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
              // Always live. Reducing or removing a line must survive a
              // refusal — it is the response a refusal calls for.
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
                enabled: canIncrease,
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
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
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
      ),
    );
  }
}