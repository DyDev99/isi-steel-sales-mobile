import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_document_builder.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_shaped_text.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_theme.dart';
import 'package:isi_steel_sales_mobile/features/order/pdf/quotation_pdf_data.dart';

/// Lays out the enterprise quotation document.
///
/// Pure layout: it takes a [QuotationPdfData] and the shared [PdfBuildContext]
/// and returns a [pw.Document]. It imports no Flutter widgets, no BLoC, and no
/// cart/product entity — swapping it for an `InvoicePdfGenerator` later means
/// implementing the same [PdfDocumentBuilder] contract against the same
/// [PdfService], nothing more.
///
/// Uses [pw.MultiPage] so a 100+ line quotation paginates automatically, with
/// the table header repeated and page numbers in the footer.
///
/// ## Khmer rendering
///
/// Every text site goes through [PdfShapedText]: Latin strings render as
/// normal vector text; strings containing Khmer are shaped by Flutter's text
/// engine and embedded as print-resolution images, so a Khmer session
/// produces a **correctly written** Khmer document (proper subscript
/// consonants and vowel order — the raw PDF engine cannot do this). The
/// [build] method runs the layout twice: pass 1 collects every string that
/// needs shaping, [PdfShapedText.warmPending] rasterizes them, pass 2 builds
/// the real page from the warm cache.
class QuotationPdfGenerator extends PdfDocumentBuilder {
  QuotationPdfGenerator(this.data);

  final QuotationPdfData data;

  final PdfShapedText _shaped = PdfShapedText();

  @override
  String get documentName => 'ISI_Quotation';

  // Labels resolve through the app's localization singleton, so a Khmer
  // session produces a Khmer document (shaped via PdfShapedText).
  String _l(String key, String fallback) {
    final value = key.tr;
    return value == key ? fallback : value;
  }

  /// Shaping-aware replacement for `pw.Text` — identical style surface.
  pw.Widget _t(
    String text, {
    required double fontSize,
    required PdfColor color,
    bool bold = false,
    double letterSpacing = 0,
    double lineSpacing = 0,
    double? maxWidth,
  }) =>
      _shaped.text(
        text,
        fontSize: fontSize,
        color: color,
        bold: bold,
        letterSpacing: letterSpacing,
        lineSpacing: lineSpacing,
        maxWidth: maxWidth,
      );

  @override
  Future<pw.Document> build(PdfBuildContext context) async {
    final theme = context.theme;
    final logo = context.assets.logo;
    final doc = pw.Document(
      title: 'ISI Steel Quotation ${data.quotationNumber}',
      author: 'ISI Steel',
    );

    final currency = NumberFormat.currency(
      symbol: data.currencySymbol,
      decimalDigits: 2,
    );
    final dateFmt = DateFormat('dd MMM yyyy');

    // Pass 1 — build and discard every section once so PdfShapedText records
    // each string that needs Khmer shaping, then rasterize them all.
    _header(theme, logo);
    _continuationBanner(theme);
    _partiesBlock(theme, dateFmt);
    _lineItemsTable(theme, currency);
    _totalsBlock(theme, currency);
    _notesBlock(theme);
    _signatureBlock(theme);
    _footerBrand(theme);
    _pageLabel(theme);
    await _shaped.warmPending();

    // Pass 2 — the real document; every shaped string now hits the cache.
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: context.pdfTheme,
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 36),
        ),
        header: (ctx) => ctx.pageNumber == 1
            ? _header(theme, logo)
            : _continuationBanner(theme),
        footer: (ctx) => _footer(theme, ctx),
        build: (ctx) => [
          pw.SizedBox(height: theme.gapLg),
          _partiesBlock(theme, dateFmt),
          pw.SizedBox(height: theme.gapLg),
          _lineItemsTable(theme, currency),
          pw.SizedBox(height: theme.gapMd),
          _totalsBlock(theme, currency),
          pw.SizedBox(height: theme.gapLg),
          _notesBlock(theme),
          pw.SizedBox(height: theme.gapXl),
          _signatureBlock(theme),
        ],
      ),
    );

    return doc;
  }

  // ── Header ─────────────────────────────────────────────────────────────
  pw.Widget _header(PdfTheme theme, dynamic logoBytes) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: theme.gapMd),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: theme.brandNavy, width: 2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Image(pw.MemoryImage(logoBytes), height: 34)
              else
                pw.Text(
                  'ISI STEEL',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.brandNavy,
                  ),
                ),
              pw.SizedBox(height: theme.gapXs),
              _t(
                _l('orders.quotation.pdf.company_tagline',
                    'Steel Solutions for Construction'),
                fontSize: 9,
                color: theme.muted,
                maxWidth: 250,
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _t(
                _l('orders.quotation.pdf.title', 'QUOTATION'),
                fontSize: 22,
                bold: true,
                color: theme.brandNavy,
                letterSpacing: 1.5,
                maxWidth: 250,
              ),
              pw.SizedBox(height: theme.gapXs),
              pw.Text(
                '# ${data.quotationNumber}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: theme.brandAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _continuationBanner(PdfTheme theme) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: theme.gapSm),
      margin: pw.EdgeInsets.only(bottom: theme.gapSm),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: theme.hairline, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _t(
            'ISI STEEL — ${_l('orders.quotation.pdf.title', 'QUOTATION')}',
            fontSize: 9,
            color: theme.muted,
            bold: true,
            maxWidth: 300,
          ),
          pw.Text('# ${data.quotationNumber}',
              style: pw.TextStyle(fontSize: 9, color: theme.muted)),
        ],
      ),
    );
  }

  // ── Parties (customer + rep + meta) ────────────────────────────────────
  pw.Widget _partiesBlock(PdfTheme theme, DateFormat dateFmt) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: _infoCard(
            theme,
            title: _l('orders.quotation.pdf.bill_to', 'BILL TO'),
            rows: [
              _InfoRow(null, data.customerName, emphasize: true),
              if ((data.customerAddress ?? '').isNotEmpty)
                _InfoRow(null, data.customerAddress!),
              if ((data.customerPhone ?? '').isNotEmpty)
                _InfoRow(_l('orders.quotation.pdf.phone', 'Phone'),
                    data.customerPhone!),
            ],
          ),
        ),
        pw.SizedBox(width: theme.gapMd),
        pw.Expanded(
          flex: 3,
          child: _infoCard(
            theme,
            title: _l('orders.quotation.pdf.sales_rep', 'SALES REPRESENTATIVE'),
            rows: [
              _InfoRow(null, data.salesRepName, emphasize: true),
              if ((data.salesRepContact ?? '').isNotEmpty)
                _InfoRow(_l('orders.quotation.pdf.contact', 'Contact'),
                    data.salesRepContact!),
            ],
          ),
        ),
        pw.SizedBox(width: theme.gapMd),
        pw.Expanded(
          flex: 2,
          child: _infoCard(
            theme,
            title: _l('orders.quotation.pdf.details', 'DETAILS'),
            rows: [
              _InfoRow(_l('orders.quotation.pdf.date', 'Date'),
                  dateFmt.format(data.createdDate)),
              if (data.validUntil != null)
                _InfoRow(_l('orders.quotation.pdf.valid_until', 'Valid Until'),
                    dateFmt.format(data.validUntil!)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _infoCard(PdfTheme theme,
      {required String title, required List<_InfoRow> rows}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(theme.gapSm + 2),
      decoration: pw.BoxDecoration(
        color: theme.panel,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: theme.hairline, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _t(
            title,
            fontSize: 8,
            bold: true,
            color: theme.brandAccent,
            letterSpacing: 0.6,
            maxWidth: 165,
          ),
          pw.SizedBox(height: theme.gapSm),
          for (final row in rows) ...[
            if (row.label != null)
              _t(row.label!, fontSize: 7.5, color: theme.muted, maxWidth: 165),
            _t(
              row.value,
              fontSize: row.emphasize ? 11 : 9,
              bold: row.emphasize,
              color: theme.ink,
              maxWidth: 165,
            ),
            pw.SizedBox(height: theme.gapXs),
          ],
        ],
      ),
    );
  }

  // ── Line-items table ───────────────────────────────────────────────────
  pw.Widget _lineItemsTable(PdfTheme theme, NumberFormat currency) {
    const cols = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(0.6),
      1: pw.FlexColumnWidth(3.4),
      2: pw.FlexColumnWidth(1.0),
      3: pw.FlexColumnWidth(0.9),
      4: pw.FlexColumnWidth(1.4),
      5: pw.FlexColumnWidth(1.5),
    };

    return pw.Table(
      columnWidths: cols,
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: theme.hairline, width: 0.5),
      ),
      children: [
        _tableHeaderRow(theme),
        for (var i = 0; i < data.lines.length; i++)
          _tableDataRow(theme, currency, data.lines[i], i + 1, i.isOdd),
      ],
    );
  }

  pw.TableRow _tableHeaderRow(PdfTheme theme) {
    pw.Widget cell(String text,
        {pw.Alignment align = pw.Alignment.centerLeft}) {
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: _t(
          text,
          fontSize: 8,
          bold: true,
          color: theme.onBrand,
          letterSpacing: 0.4,
          maxWidth: 190,
        ),
      );
    }

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: theme.brandNavy),
      children: [
        cell(_l('orders.quotation.pdf.col_no', '#')),
        cell(_l('orders.quotation.pdf.col_product', 'PRODUCT')),
        cell(_l('orders.quotation.pdf.col_unit', 'UNIT')),
        cell(_l('orders.quotation.pdf.col_qty', 'QTY'),
            align: pw.Alignment.centerRight),
        cell(_l('orders.quotation.pdf.col_unit_price', 'UNIT PRICE'),
            align: pw.Alignment.centerRight),
        cell(_l('orders.quotation.pdf.col_total', 'TOTAL'),
            align: pw.Alignment.centerRight),
      ],
    );
  }

  pw.TableRow _tableDataRow(PdfTheme theme, NumberFormat currency,
      QuotationPdfLine line, int number, bool zebra) {
    pw.Widget cell(pw.Widget child,
        {pw.Alignment align = pw.Alignment.centerLeft}) {
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: child,
      );
    }

    final qty = line.quantity == line.quantity.roundToDouble()
        ? line.quantity.toStringAsFixed(0)
        : line.quantity.toStringAsFixed(2);

    return pw.TableRow(
      decoration: zebra
          ? pw.BoxDecoration(color: theme.zebra)
          : const pw.BoxDecoration(),
      children: [
        cell(pw.Text('$number',
            style: pw.TextStyle(fontSize: 8.5, color: theme.muted))),
        cell(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Flexible(
                    child: _t(line.name,
                        fontSize: 9,
                        bold: true,
                        color: theme.ink,
                        maxWidth: 170),
                  ),
                  if (line.isCustomized)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(left: 4),
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: pw.BoxDecoration(
                        color: theme.panel,
                        borderRadius: pw.BorderRadius.circular(3),
                        border: pw.Border.all(color: theme.brandAccent, width: 0.5),
                      ),
                      child: _t(
                        _l('orders.quotation.pdf.customized', 'CUSTOMIZED'),
                        fontSize: 6,
                        bold: true,
                        color: theme.brandAccent,
                        letterSpacing: 0.3,
                        maxWidth: 60,
                      ),
                    ),
                ],
              ),
              if (line.description.isNotEmpty)
                _t(line.description,
                    fontSize: 7.5, color: theme.muted, maxWidth: 190),
              if (line.specs != null)
                _t(
                  '${_l('orders.quotation.pdf.specs', 'Specs')}: ${line.specs}',
                  fontSize: 7.5,
                  bold: true,
                  color: theme.brandNavy,
                  maxWidth: 190,
                ),
              if (line.appearance != null)
                _t(
                  '${_l('orders.quotation.pdf.finish', 'Finish')}: ${line.appearance}',
                  fontSize: 7.5,
                  color: theme.ink,
                  maxWidth: 190,
                ),
              if (line.discountPercent > 0)
                _t(
                  '${_l('orders.quotation.pdf.line_discount', 'Line discount')}: '
                  '${line.discountPercent.toStringAsFixed(0)}%',
                  fontSize: 7,
                  color: theme.success,
                  maxWidth: 190,
                ),
              if (line.drawingImageBytes != null) ...[
                pw.SizedBox(height: 4),
                pw.ClipRRect(
                  horizontalRadius: 3,
                  verticalRadius: 3,
                  child: pw.Image(
                    pw.MemoryImage(line.drawingImageBytes!),
                    height: 54,
                    width: 78,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
        cell(_t(line.unit, fontSize: 8.5, color: theme.ink, maxWidth: 55)),
        cell(pw.Text(qty, style: pw.TextStyle(fontSize: 8.5, color: theme.ink)),
            align: pw.Alignment.centerRight),
        cell(
            pw.Text(currency.format(line.unitPrice),
                style: pw.TextStyle(fontSize: 8.5, color: theme.ink)),
            align: pw.Alignment.centerRight),
        cell(
            pw.Text(currency.format(line.lineTotal),
                style: pw.TextStyle(
                    fontSize: 8.5,
                    color: theme.ink,
                    fontWeight: pw.FontWeight.bold)),
            align: pw.Alignment.centerRight),
      ],
    );
  }

  // ── Totals ─────────────────────────────────────────────────────────────
  pw.Widget _totalsBlock(PdfTheme theme, NumberFormat currency) {
    pw.Widget row(String label, String value,
        {bool grand = false, PdfColor? valueColor}) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: grand ? 6 : 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _t(label,
                fontSize: grand ? 12 : 9.5,
                bold: grand,
                color: grand ? theme.brandNavy : theme.muted,
                maxWidth: 130),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: grand ? 13 : 9.5,
                    color: valueColor ?? (grand ? theme.brandNavy : theme.ink),
                    fontWeight:
                        grand ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 230,
          padding: pw.EdgeInsets.all(theme.gapMd),
          decoration: pw.BoxDecoration(
            color: theme.panel,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: theme.hairline, width: 0.5),
          ),
          child: pw.Column(
            children: [
              row(_l('orders.quotation.pdf.subtotal', 'Subtotal'),
                  currency.format(data.subtotal)),
              row(_l('orders.quotation.pdf.discount', 'Discount'),
                  '- ${currency.format(data.discount)}',
                  valueColor: data.discount > 0 ? theme.success : null),
              row(_l('orders.quotation.pdf.tax', 'Tax (VAT 10%)'),
                  currency.format(data.tax)),
              pw.Divider(color: theme.hairline, height: theme.gapMd),
              row(_l('orders.quotation.pdf.grand_total', 'GRAND TOTAL'),
                  currency.format(data.total),
                  grand: true),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notes ──────────────────────────────────────────────────────────────
  pw.Widget _notesBlock(PdfTheme theme) {
    final notes = (data.notes ?? '').trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _t(_l('orders.quotation.pdf.notes', 'NOTES'),
            fontSize: 8,
            bold: true,
            color: theme.brandAccent,
            letterSpacing: 0.6,
            maxWidth: 200),
        pw.SizedBox(height: theme.gapXs),
        _t(
          notes.isNotEmpty
              ? notes
              : _l('orders.quotation.pdf.notes_default',
                  'Prices are held for 7 days from the quotation date. This is a quotation only and not a final invoice. Delivery lead times are confirmed on order.'),
          fontSize: 8.5,
          color: theme.muted,
          lineSpacing: 2,
          maxWidth: 525,
        ),
      ],
    );
  }

  // ── Approval / signatures ──────────────────────────────────────────────
  pw.Widget _signatureBlock(PdfTheme theme) {
    pw.Widget slot(String label) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 34),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: theme.ink, width: 0.7),
                ),
              ),
              padding: pw.EdgeInsets.only(top: theme.gapXs),
              child:
                  _t(label, fontSize: 8.5, color: theme.muted, maxWidth: 150),
            ),
          ],
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        slot(_l('orders.quotation.pdf.prepared_by', 'Prepared by (Sales Rep)')),
        pw.SizedBox(width: theme.gapXl),
        slot(_l('orders.quotation.pdf.approved_by', 'Approved by')),
        pw.SizedBox(width: theme.gapXl),
        slot(_l(
            'orders.quotation.pdf.customer_signature', 'Customer signature')),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────
  //
  // Split so the localizable parts ([_footerBrand], [_pageLabel]) can be
  // warmed in pass 1 without a real `pw.Context`; only the page numbers are
  // per-page dynamic, and digits never need shaping.
  pw.Widget _footerBrand(PdfTheme theme) => _t(
        _l('orders.quotation.pdf.footer',
            'ISI Steel · Generated by ISI Sales Mobile'),
        fontSize: 7.5,
        color: theme.muted,
        maxWidth: 350,
      );

  pw.Widget _pageLabel(PdfTheme theme) => _t(
        _l('orders.quotation.pdf.page', 'Page'),
        fontSize: 7.5,
        color: theme.muted,
        maxWidth: 80,
      );

  pw.Widget _footer(PdfTheme theme, pw.Context ctx) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: theme.gapSm),
      padding: pw.EdgeInsets.only(top: theme.gapSm),
      decoration: pw.BoxDecoration(
        border:
            pw.Border(top: pw.BorderSide(color: theme.hairline, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _footerBrand(theme),
          pw.Row(children: [
            _pageLabel(theme),
            pw.Text(
              ' ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7.5, color: theme.muted),
            ),
          ]),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value, {this.emphasize = false});
  final String? label;
  final String value;
  final bool emphasize;
}
