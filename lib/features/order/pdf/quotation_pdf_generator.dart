import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_document_builder.dart';
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
class QuotationPdfGenerator extends PdfDocumentBuilder {
  QuotationPdfGenerator(this.data);

  final QuotationPdfData data;

  @override
  String get documentName => 'ISI_Quotation';

  // Labels resolve through the app's localization singleton, so a Khmer session
  // produces a Khmer document (rendered via the Kantumruy font fallback).
  String _l(String key, String fallback) {
    final value = key.tr;
    return value == key ? fallback : value;
  }

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
              pw.Text(
                _l('orders.quotation.pdf.company_tagline',
                    'Steel Solutions for Construction'),
                style: pw.TextStyle(fontSize: 9, color: theme.muted),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _l('orders.quotation.pdf.title', 'QUOTATION'),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: theme.brandNavy,
                  letterSpacing: 1.5,
                ),
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
          pw.Text(
              'ISI STEEL — ${_l('orders.quotation.pdf.title', 'QUOTATION')}',
              style: pw.TextStyle(
                  fontSize: 9,
                  color: theme.muted,
                  fontWeight: pw.FontWeight.bold)),
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
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: theme.brandAccent,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: theme.gapSm),
          for (final row in rows) ...[
            if (row.label != null)
              pw.Text(row.label!,
                  style: pw.TextStyle(fontSize: 7.5, color: theme.muted)),
            pw.Text(
              row.value,
              style: pw.TextStyle(
                fontSize: row.emphasize ? 11 : 9,
                fontWeight:
                    row.emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: theme.ink,
              ),
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
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: theme.onBrand,
            letterSpacing: 0.4,
          ),
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
              pw.Text(line.name,
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: theme.ink,
                      fontWeight: pw.FontWeight.bold)),
              if (line.description.isNotEmpty)
                pw.Text(line.description,
                    style: pw.TextStyle(fontSize: 7.5, color: theme.muted)),
              if (line.discountPercent > 0)
                pw.Text(
                  '${_l('orders.quotation.pdf.line_discount', 'Line discount')}: '
                  '${line.discountPercent.toStringAsFixed(0)}%',
                  style: pw.TextStyle(fontSize: 7, color: theme.success),
                ),
            ],
          ),
        ),
        cell(pw.Text(line.unit,
            style: pw.TextStyle(fontSize: 8.5, color: theme.ink))),
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
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: grand ? 12 : 9.5,
                    color: grand ? theme.brandNavy : theme.muted,
                    fontWeight:
                        grand ? pw.FontWeight.bold : pw.FontWeight.normal)),
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
        pw.Text(_l('orders.quotation.pdf.notes', 'NOTES'),
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: theme.brandAccent,
                letterSpacing: 0.6)),
        pw.SizedBox(height: theme.gapXs),
        pw.Text(
          notes.isNotEmpty
              ? notes
              : _l('orders.quotation.pdf.notes_default',
                  'Prices are held for 7 days from the quotation date. This is a quotation only and not a final invoice. Delivery lead times are confirmed on order.'),
          style:
              pw.TextStyle(fontSize: 8.5, color: theme.muted, lineSpacing: 2),
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
              child: pw.Text(label,
                  style: pw.TextStyle(fontSize: 8.5, color: theme.muted)),
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
          pw.Text(
            _l('orders.quotation.pdf.footer',
                'ISI Steel · Generated by ISI Sales Mobile'),
            style: pw.TextStyle(fontSize: 7.5, color: theme.muted),
          ),
          pw.Text(
            '${_l('orders.quotation.pdf.page', 'Page')} '
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 7.5, color: theme.muted),
          ),
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
