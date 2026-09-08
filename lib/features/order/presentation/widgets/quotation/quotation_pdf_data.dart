import 'package:isi_steel_sales_mobile/core/platform/local_files.dart';
import 'dart:typed_data';

import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/promotion/demo_cart_promotions.dart';

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
    this.discountSource,
    this.freeQuantity = 0,
    this.freeRule,
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

  /// Who granted the reduction on this line — "Rep discount", "Promotion ·
  /// Roofing Sheet Free Goods".
  ///
  /// The quotation is a document the customer keeps and argues from, and
  /// "-10%" with no attribution is the line a rep gets challenged on three
  /// weeks later: who gave me that, and does it still apply? A rep discount
  /// expires with the quotation; a campaign has dates and will lapse. Printing
  /// both as an undifferentiated "Discount" tells the customer they got a
  /// number, not what they can rely on next time.
  ///
  /// Null prints nothing, which is right for a line that got no reduction.
  final String? discountSource;

  /// Units given free. Never folded into [quantity] — "300, and 15 come free"
  /// is a checkable promise in a way that "about 5% off" is not.
  final int freeQuantity;

  /// The rule that produced [freeQuantity], e.g. "Buy 40 Free 1". Printed so
  /// the entitlement can be verified rather than taken on trust.
  final String? freeRule;
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

        // Static while the shape is being reviewed. The real source is the
        // promotion evaluation already resolved for the cart; this reads the
        // same demo the cart badge does, so the printed page and the screen
        // agree rather than telling the customer two different things.
        discountSource: _sourceFor(item),
        freeQuantity: DemoCartPromotions.freeQuantityFor(item),
        freeRule: DemoCartPromotions.freeRuleFor(item),
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

  /// Where this line's reduction came from.
  ///
  /// A promotion wins the attribution when the line earned one, because that
  /// is the claim the customer will check. A bare percentage with no promotion
  /// behind it is a rep discount by definition on this platform — it is the
  /// only kind the app lets anybody type by hand.
  static String? _sourceFor(CartItem item) {
    final promotion = DemoCartPromotions.promotionNameFor(item);
    if (promotion != null) return 'Promotion · $promotion';
    if (item.discountPercent > 0) return 'Rep discount';
    return null;
  }

  /// Reads the drawing file into bytes for the PDF, or null when the path is
  /// empty/missing/unreadable — a missing drawing must never fail the export.
  static Uint8List? _readDrawing(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      // Always null on web — there is no local drawing file to read there. That
      // takes the same "missing drawing" branch this method already had, so the
      // export still succeeds without the image (see `local_files_web.dart`).
      return readLocalFileSync(path);
    } catch (_) {
      return null;
    }
  }
}
