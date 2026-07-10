import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_preview_section.dart';

class QuotationScreen extends StatelessWidget {
  const QuotationScreen({
    super.key,
    this.shopName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.items, // CHANGED: Expecting the full list of items from the cart state
    this.onSavePressed,
  });

  final String? shopName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final List<CartItem> items;
  final VoidCallback? onSavePressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Scrollable Preview Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: QuotationPreviewSection(
                  shopName: shopName,
                  subtotal: subtotal,
                  discount: discount,
                  tax: tax,
                  total: total,
                  items:
                      items, // CHANGED: Passing down the real product array directly
                  onEnlargeTap: null,
                ),
              ),
            ),

            // 2. Bottom Persistent Action Buttons Layout
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // "Back" Button
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      height: 52.h,
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // "Save Quotation to SAP" Primary Button
                  Expanded(
                    child: InkWell(
                      onTap: onSavePressed,
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF94A3B8)
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Save Quotation to SAP',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
