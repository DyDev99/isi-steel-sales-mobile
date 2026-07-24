import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';

class QuotationPdfService {
  Future<pw.Document> generateQuotationDocument({
    required String quotationNumber,
    required String customerName,
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          _buildHeader(quotationNumber, customerName),
          pw.SizedBox(height: 16),
          _buildItemsTable(items),
          pw.SizedBox(height: 16),
          _buildSummary(subtotal, discount, tax, total),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String quotationNumber, String customerName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ISI STEEL SALES QUOTATION',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Customer: $customerName'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Quotation #: $quotationNumber',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<CartItem> items) {
    final headers = [
      'Image / Drawing',
      'Product Details',
      'Qty',
      'Unit Price',
      'Total'
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      cellHeight: 50,
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      data: items.map((item) {
        // Image resolution logic
        pw.Widget imageCell;
        if (item.isCustomized &&
            item.drawingImagePath != null &&
            File(item.drawingImagePath!).existsSync()) {
          try {
            final imageBytes =
                File(item.drawingImagePath!).readAsBytesSync();
            imageCell = pw.Container(
              height: 45,
              width: 70,
              alignment: pw.Alignment.center,
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
              ),
            );
          } catch (_) {
            imageCell = pw.Text('[Drawing Error]');
          }
        } else {
          imageCell = pw.Text('[Standard]');
        }

        // Details column formatting
        final detailText = StringBuffer(item.product.name);
        if (item.isCustomized) {
          detailText.write('\n(Customized Request)');
          if (item.measurements != null) {
            detailText.write('\nSpecs: ${item.measurements!.toSummaryString()}');
          }
          if (item.appearance != null && item.appearance!.isNotEmpty) {
            detailText.write('\nFinish: ${item.appearance}');
          }
          if (item.customizationDescription != null &&
              item.customizationDescription!.isNotEmpty) {
            detailText.write('\nNotes: ${item.customizationDescription}');
          }
        }

        return [
          imageCell,
          pw.Text(detailText.toString(), style: const pw.TextStyle(fontSize: 9)),
          pw.Text('${item.quantity.toStringAsFixed(0)} ${item.unit}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text('\$${item.unitPrice.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text('\$${item.lineTotal.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 9)),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildSummary(
      double subtotal, double discount, double tax, double total) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _summaryRow('Subtotal', subtotal),
            _summaryRow('Discount', -discount),
            _summaryRow('Tax (10%)', tax),
            pw.Divider(),
            _summaryRow('Total Amount', total, isBold: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        // Fixed typo here: replaced mainpw with mainAxisAlignment
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '\$${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}