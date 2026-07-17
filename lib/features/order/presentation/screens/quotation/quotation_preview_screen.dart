import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/pdf/pdf_generation_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/pdf/pdf_generation_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_preview_section.dart';

/// Full-screen quotation preview + PDF export entry point.
///
/// Owns a [PdfGenerationCubit] (from DI) so the "Download PDF" action runs
/// through the enterprise PDF pipeline — no PDF logic lives in this widget.
class QuotationScreen extends StatelessWidget {
  const QuotationScreen({
    super.key,
    this.shopName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.items,
    this.quotationNumber,
    this.createdDate,
    this.validUntil,
    this.customerPhone,
    this.customerAddress,
    this.notes,
    this.onPDFDownload,
  });

  final String? shopName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final List<CartItem> items;

  /// Optional PDF metadata. Sensible defaults are derived when omitted, so
  /// existing callers keep working.
  final String? quotationNumber;
  final DateTime? createdDate;
  final DateTime? validUntil;
  final String? customerPhone;
  final String? customerAddress;
  final String? notes;

  /// Legacy hook kept for backward compatibility; the button now drives the
  /// [PdfGenerationCubit] directly, but if a caller still passes this it is
  /// invoked after a successful export.
  final VoidCallback? onPDFDownload;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PdfGenerationCubit>(
      create: (_) => sl<PdfGenerationCubit>(),
      child: _QuotationView(
        shopName: shopName,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        items: items,
        quotationNumber: quotationNumber,
        createdDate: createdDate,
        validUntil: validUntil,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        notes: notes,
        onPDFDownload: onPDFDownload,
      ),
    );
  }
}

class _QuotationView extends StatelessWidget {
  const _QuotationView({
    required this.shopName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.items,
    required this.quotationNumber,
    required this.createdDate,
    required this.validUntil,
    required this.customerPhone,
    required this.customerAddress,
    required this.notes,
    required this.onPDFDownload,
  });

  final String? shopName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final List<CartItem> items;
  final String? quotationNumber;
  final DateTime? createdDate;
  final DateTime? validUntil;
  final String? customerPhone;
  final String? customerAddress;
  final String? notes;
  final VoidCallback? onPDFDownload;

  String _resolvedQuotationNumber() {
    if (quotationNumber != null && quotationNumber!.isNotEmpty) {
      return quotationNumber!;
    }
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'QT-${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  void _download(BuildContext context) {
    context.read<PdfGenerationCubit>().generateQuotationPdf(
          quotationNumber: _resolvedQuotationNumber(),
          customerName: shopName ?? 'Walk-in Customer',
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          createdDate: createdDate ?? DateTime.now(),
          validUntil:
              validUntil ?? DateTime.now().add(const Duration(days: 7)),
          items: items,
          subtotal: subtotal,
          discount: discount,
          tax: tax,
          total: total,
          notes: notes,
        );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: themeColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Column(
                  children: [
                    QuotationPreviewSection(
                      shopName: shopName,
                      subtotal: subtotal,
                      discount: discount,
                      tax: tax,
                      total: total,
                      items: items,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: BlocConsumer<PdfGenerationCubit, PdfGenerationState>(
                listener: (context, state) {
                  if (state is PdfGenerated) {
                    onPDFDownload?.call();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          backgroundColor: themeColors.success,
                          content:
                              Text('orders.quotation.pdf.success'.tr),
                        ),
                      );
                  } else if (state is PdfGenerationFailed) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          backgroundColor: colorScheme.error,
                          content: Text(state.messageKey.tr),
                        ),
                      );
                  }
                },
                builder: (context, state) {
                  final isGenerating = state is PdfGenerating;
                  return Row(
                    children: [
                      OutlinedButton(
                        onPressed: isGenerating
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 14.h, horizontal: 24.w),
                          side: BorderSide(
                              color: themeColors.border, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'common.back'.tr,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: themeColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: InkWell(
                          onTap:
                              isGenerating ? null : () => _download(context),
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: isGenerating
                                  ? colorScheme.primary
                                      .withValues(alpha: 0.7)
                                  : colorScheme.primary,
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: isGenerating
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18.w,
                                        height: 18.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'orders.quotation.pdf.generating'.tr,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'orders.quotation.pdf.download'.tr,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
