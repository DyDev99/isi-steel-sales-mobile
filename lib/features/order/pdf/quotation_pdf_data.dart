import 'dart:io';
import 'dart:typed_data';

import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';

/// One priced row on the quotation PDF. Deliberately a flat, Flutter-free value
/// object rather than a [CartItem]: the generator must not depend on the cart
/// domain model (or on `Product`), so mapping happens once here and the PDF
/// layer stays isolated from catalog/cart refactors.
class QuotationPdfLine {
  const QuotationPdfLine({
    required this.name,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercent,
    required this.lineTotal,
    this.isCustomized = false,
    this.specs,
    this.appearance,
    this.drawingImageBytes,
  });

  final String name;
  final String description;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double lineTotal;

  // ── Customization (empty/false for a plain catalog line) ──────────────
  final bool isCustomized;

  /// Measurements summary, e.g. "L: 6000mm × Ø: 12mm".
  final String? specs;

  /// Surface finish / colour / coating.
  final String? appearance;

  /// Decoded bytes of the attached technical drawing, ready for the PDF's
  /// `MemoryImage`. Null when there is no drawing (or it couldn't be read).
  final Uint8List? drawingImageBytes;
}

/// The immutable input to [QuotationPdfGenerator].
///
/// This is the boundary the prompt calls out: **never pass widget state** into
/// the generator. The presentation layer assembles one of these from domain
/// entities ([CartItem], the session's rep, the customer) and hands it over;
/// the generator only ever sees plain data.
class QuotationPdfData {
  const QuotationPdfData({
    required this.quotationNumber,
    required this.customerName,
    required this.salesRepName,
    required this.createdDate,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    this.customerPhone,
    this.customerAddress,
    this.salesRepContact,
    this.validUntil,
    this.notes,
    this.currencySymbol = r'$',
  });

  final String quotationNumber;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String salesRepName;
  final String? salesRepContact;
  final DateTime createdDate;
  final DateTime? validUntil;
  final List<QuotationPdfLine> lines;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String? notes;
  final String currencySymbol;

  /// Builds the PDF payload from live cart data. This is the single place cart
  /// entities cross into the PDF layer, so any product-shape change touches
  /// exactly one mapping.
  factory QuotationPdfData.fromCart({
    required String quotationNumber,
    required String customerName,
    required String salesRepName,
    required DateTime createdDate,
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    String? customerPhone,
    String? customerAddress,
    String? salesRepContact,
    DateTime? validUntil,
    String? notes,
    String currencySymbol = r'$',
  }) {
    final lines = items.map((item) {
      final product = item.product;
      final description = '${product.size} ${product.grade}'.trim();

      String? specs;
      String? appearance;
      Uint8List? drawingBytes;
      if (item.isCustomized) {
        final m = item.measurements;
        if (m != null && !m.isEmpty) specs = m.toSummaryString();
        final finish = item.appearance?.trim();
        if (finish != null && finish.isNotEmpty) appearance = finish;
        drawingBytes = _readDrawing(item.drawingImagePath);
      }

      return QuotationPdfLine(
        name: product.name.isNotEmpty ? product.name : 'Structural Item',
        description: description,
        unit: item.unit,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountPercent: item.discountPercent,
        lineTotal: item.lineTotal,
        isCustomized: item.isCustomized,
        specs: specs,
        appearance: appearance,
        drawingImageBytes: drawingBytes,
      );
    }).toList(growable: false);

    return QuotationPdfData(
      quotationNumber: quotationNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      salesRepName: salesRepName,
      salesRepContact: salesRepContact,
      createdDate: createdDate,
      validUntil: validUntil,
      lines: lines,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      notes: notes,
      currencySymbol: currencySymbol,
    );
  }

  /// Reads the drawing file into bytes for the PDF, or null when the path is
  /// empty/missing/unreadable — a missing drawing must never fail the export.
  static Uint8List? _readDrawing(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return file.readAsBytesSync();
    } catch (_) {
      return null;
    }
  }
}
