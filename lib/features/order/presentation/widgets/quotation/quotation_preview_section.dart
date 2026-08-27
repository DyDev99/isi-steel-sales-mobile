import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/platform/local_files.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/painters/dashed_rrect.dart';

class QuotationPreviewSection extends StatelessWidget {
  const QuotationPreviewSection({
    super.key,
    this.shopName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.items, // CHANGED: Accept the full list of items instead of just a count
    this.onEnlargeTap,
  });

  final String? shopName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final List<CartItem> items;
  final VoidCallback? onEnlargeTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/logos/darkmood_logo.jpg'
        : 'assets/logos/isi_main_screen_logo.png';

    return CustomPaint(
      painter: _DottedBorderPainter(
        borderColor: colors.border,
        backgroundColor: colors.card,
        strokeWidth: 1.5,
        radius: context.rr(16),
        dashLength: 4.0,
        gap: 4.0,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(context.rw(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        logoAsset,
                        height: context.rh(40),
                        width: context.rh(120),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.business,
                          color: colors.brandNavy,
                          size: context.rr(20),
                        ),
                      ),
                      SizedBox(height: context.rh(6)),
                      Text(
                        'orders.quotation.builder_title'.tr,
                        style: TextStyle(
                          fontSize: context.rsp(14),
                          fontWeight: FontWeight.w900,
                          color: colors.brandNavy,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: context.rh(2)),
                      Text(
                        '${shopName ?? 'orders.quotation_extra.walk_in'.tr} · ${'orders.quotation_extra.today'.tr}',
                        style: TextStyle(
                          fontSize: context.rsp(12),
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEnlargeTap != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: onEnlargeTap,
                      borderRadius: BorderRadius.circular(context.rr(8)),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rw(10),
                            vertical: context.rh(5)),
                        decoration: BoxDecoration(
                          color: colors.surfaceSoft,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(context.rr(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen_rounded,
                              size: context.rw(14),
                              color: colors.brandNavy,
                            ),
                            SizedBox(width: context.rw(4)),
                            Text(
                              'orders.quotation_extra.enlarge'.tr,
                              style: TextStyle(
                                fontSize: context.rsp(11),
                                fontWeight: FontWeight.w700,
                                color: colors.brandNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.rh(16)),
            const _DashedDivider(),
            SizedBox(height: context.rh(16)),

            // --- NEW: DYNAMIC PRODUCT LIST INSIDE QUOTATION ---
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.rh(4)),
                  child: Text(
                    'orders.quotation_extra.no_items'.tr,
                    style: TextStyle(
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...items.map((item) {
                final product = item.product;
                final int qty = item.quantity.toInt();
                final double rowTotal = item.lineSubtotal;

                final specParts = <String>[];
                if (item.isCustomized) {
                  final m = item.measurements;
                  if (m != null && !m.isEmpty) {
                    specParts.add(m.toSummaryString());
                  }
                  if (item.appearance != null &&
                      item.appearance!.trim().isNotEmpty) {
                    specParts.add(item.appearance!.trim());
                  }
                }
                final hasDrawing = item.drawingImagePath != null &&
                    localFileExists(item.drawingImagePath!);

                return Padding(
                  padding: EdgeInsets.only(bottom: context.rh(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Qty
                      SizedBox(
                        width: context.rw(30),
                        child: Text(
                          '${qty}x',
                          style: TextStyle(
                            fontSize: context.rsp(13),
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      // Drawing thumbnail (customized lines only)
                      if (item.isCustomized) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(context.rr(6)),
                          child: Container(
                            width: context.rw(34),
                            height: context.rw(34),
                            color: colors.surfaceSoft,
                            child: hasDrawing
                                ? localFileImage((item.drawingImagePath!),
                                    fit: BoxFit.cover)
                                : Icon(Icons.tune_rounded,
                                    size: context.rw(16),
                                    color: colors.brandNavy),
                          ),
                        ),
                        SizedBox(width: context.rw(8)),
                      ],
                      // Product Name & details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    product.displayName.isEmpty
                                        ? 'orders.quotation_extra.structural_item'
                                            .tr
                                        : context
                                            .localized(product.displayName),
                                    style: TextStyle(
                                      fontSize: context.rsp(13),
                                      fontWeight: FontWeight.w500,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (item.isCustomized)
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: context.rw(4)),
                                    child: Text('✏️',
                                        style: TextStyle(
                                            fontSize: context.rsp(11))),
                                  ),
                              ],
                            ),
                            if (item.isCustomized && specParts.isNotEmpty)
                              Text(
                                specParts.join(' · '),
                                style: TextStyle(
                                  fontSize: context.rsp(11),
                                  color: colors.brandNavy,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (product.size.isNotEmpty ||
                                product.grade.isNotEmpty)
                              Text(
                                '${product.size} ${product.grade}'.trim(),
                                style: TextStyle(
                                  fontSize: context.rsp(11),
                                  color: colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Row Total
                      SizedBox(width: context.rw(8)),
                      Text(
                        '\$${rowTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.rsp(13),
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            SizedBox(height: context.rh(8)),
            const _DashedDivider(),
            SizedBox(height: context.rh(14)),

            // Pricing Rows Section Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'orders.quotation_extra.subtotal'.tr,
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rh(8)),

            // Discount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'orders.quotation_extra.discount'.tr,
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '-\$${discount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w600,
                    color: discount > 0 ? colors.success : colors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rh(8)),

            // Tax Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'orders.quotation_extra.tax'.tr,
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '\$${tax.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rh(12)),
            const _DashedDivider(),
            SizedBox(height: context.rh(12)),

            // Total Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'orders.quotation_extra.total'.tr,
                  style: TextStyle(
                    fontSize: context.rsp(16),
                    fontWeight: FontWeight.w900,
                    color: colors.brandNavy,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.rsp(16),
                    fontWeight: FontWeight.w900,
                    color: colors.brandNavy,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rh(14)),
            const _DashedDivider(),
            SizedBox(height: context.rh(12)),

            // Bottom Disclaimer Footer Layout
            Text(
              'orders.quotation_extra.quote_disclaimer'.tr,
              style: TextStyle(
                fontSize: context.rsp(11),
                fontWeight: FontWeight.w500,
                color: colors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gap;

  _DottedBorderPainter({
    required this.borderColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final halfWidth = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      halfWidth,
      halfWidth,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(radius - halfWidth));

    // 1. Paint the solid background first
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // 2. Prepare the border stroke
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 3. Draw the dotted border cleanly on top of the background edge.
    //    Uses the polyline walker rather than PathMetrics.extractPath, which
    //    overflows the stack on web — see drawDashedRRect's doc comment.
    drawDashedRRect(canvas, rrect, borderPaint, dash: dashLength, gap: gap);
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gap != gap;
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: colors.divider),
              ),
            );
          }),
        );
      },
    );
  }
}
