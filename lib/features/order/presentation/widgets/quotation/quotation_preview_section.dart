import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';

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
    return CustomPaint(
      painter: _DottedBorderPainter(
        borderColor: const Color(0xFFBFDBFE),
        backgroundColor: Colors.white,
        strokeWidth: 1.5,
        radius: 16.r,
        dashLength: 4.0,
        gap: 4.0,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
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
                        'assets/logos/isi_main_screen_logo.png',
                        height: 40.h,
                        width: 120.h,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.business,
                          color: Color(0xFF0F2C7F),
                          size: 20,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'QUOTATION',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F2C7F),
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${shopName ?? "Walk-in Customer"} · today',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
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
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FF),
                          border: Border.all(color: const Color(0xFFD6E4FF)),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen_rounded,
                              size: 14.w,
                              color: const Color(0xFF1E3A8A),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Enlarge',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            const _DashedDivider(),
            SizedBox(height: 16.h),

            // --- NEW: DYNAMIC PRODUCT LIST INSIDE QUOTATION ---
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Text(
                    'No items yet',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              ...items.map((item) {
                final product = item.product;
                final int qty = item.quantity.toInt();
                final double rowTotal = item.lineSubtotal;

                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Qty
                      SizedBox(
                        width: 30.w,
                        child: Text(
                          '${qty}x',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Product Name & details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name.isNotEmpty
                                  ? product.name
                                  : 'Structural Item',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (product.size.isNotEmpty ||
                                product.grade.isNotEmpty)
                              Text(
                                '${product.size} ${product.grade}'.trim(),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Row Total
                      SizedBox(width: 8.w),
                      Text(
                        '\$${rowTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            SizedBox(height: 8.h),
            const _DashedDivider(),
            SizedBox(height: 14.h),

            // Pricing Rows Section Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Discount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '-\$${discount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: discount > 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Tax Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '\$${tax.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const _DashedDivider(),
            SizedBox(height: 12.h),

            // Total Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F2C7F),
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F2C7F),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            const _DashedDivider(),
            SizedBox(height: 12.h),

            // Bottom Disclaimer Footer Layout
            Text(
              'Quote only · prices held 7 days · not a final bill',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ... [Keep the _DottedBorderPainter and _DashedDivider classes exactly as they were]

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

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }

    // 3. Draw the dotted border cleanly on top of the background edge
    canvas.drawPath(dashedPath, borderPaint);
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
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }
}
