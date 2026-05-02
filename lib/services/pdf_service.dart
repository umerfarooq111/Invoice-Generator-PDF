// ============================================================
// services/pdf_service.dart
// Generates a professionally formatted PDF invoice
// Uses the 'pdf' package for layout and 'printing' for sharing
// Includes shop info from Settings, notes, address, T&C
// ============================================================

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/shop_settings.dart';

class PdfService {
  // PKR currency formatter
  static final _currencyFmt = NumberFormat('#,##0.00', 'en_US');
  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// Generate and share/print a PDF for the given invoice
  static Future<void> generateAndShareInvoice(
    Invoice invoice, {
    ShopSettings? shopSettings,
  }) async {
    final pdf = pw.Document();
    final settings = shopSettings ?? const ShopSettings();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => _buildInvoicePage(context, invoice, settings),
      ),
    );

    // Use custom title in filename if available
    final nameSlug = invoice.title != null && invoice.title!.trim().isNotEmpty
        ? invoice.title!.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')
        : invoice.customerName.replaceAll(' ', '_');

    // Show the system share/print dialog
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_${invoice.id}_$nameSlug.pdf',
    );
  }

  /// Preview PDF in a full-screen viewer
  static Future<void> previewInvoice(
    Invoice invoice, {
    ShopSettings? shopSettings,
  }) async {
    final settings = shopSettings ?? const ShopSettings();

    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => _buildInvoicePage(context, invoice, settings),
          ),
        );
        return pdf.save();
      },
    );
  }

  // ─── PDF Layout ───────────────────────────────────────────

  static pw.Widget _buildInvoicePage(
      pw.Context ctx, Invoice invoice, ShopSettings settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header: Company + Invoice title
        _buildHeader(invoice, settings),
        pw.SizedBox(height: 24),

        // Customer info
        _buildCustomerInfo(invoice),
        pw.SizedBox(height: 24),

        // Items table
        _buildItemsTable(invoice.items),
        pw.SizedBox(height: 16),

        // Totals
        _buildTotals(invoice),
        pw.SizedBox(height: 24),

        // Additional info (notes, T&C)
        _buildAdditionalInfo(invoice),

        // Footer
        _buildFooter(settings),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────
  static pw.Widget _buildHeader(Invoice invoice, ShopSettings settings) {
    // Use shop name from settings, or default
    final shopName = settings.shopName.isNotEmpty
        ? settings.shopName
        : 'QuickBill PK';

    // Determine address: use invoice-level address first, then settings
    final address = (invoice.shopAddress != null && invoice.shopAddress!.trim().isNotEmpty)
        ? invoice.shopAddress!
        : settings.shopAddress;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Name + Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              shopName,
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            // Shop address
            if (address.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Container(
                width: 200,
                child: pw.Text(
                  address,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
            // Shop phone
            if (settings.shopPhone.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                settings.shopPhone,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
            // Shop email
            if (settings.shopEmail.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Text(
                settings.shopEmail,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ],
        ),

        // Invoice details block
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              '#${invoice.id?.toString().padLeft(4, '0') ?? '0000'}',
              style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
            ),
            // Show custom title
            if (invoice.title != null && invoice.title!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                invoice.title!,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue600,
                ),
              ),
            ],
            pw.SizedBox(height: 4),
            pw.Text(
              _dateFmt.format(invoice.createdAt),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  // ── Customer Info ─────────────────────────────────────────
  static pw.Widget _buildCustomerInfo(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILLED TO',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            invoice.customerName,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            invoice.customerPhone,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // ── Items Table ───────────────────────────────────────────
  static pw.Widget _buildItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),   // Product name
        1: const pw.FixedColumnWidth(60), // Qty
        2: const pw.FixedColumnWidth(80), // Unit price
        3: const pw.FixedColumnWidth(90), // Subtotal
      },
      children: [
        // Table header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: [
            _tableCell('Product / Service', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), align: pw.Alignment.centerLeft),
            _tableCell('Qty', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            _tableCell('Unit Price', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            _tableCell('Subtotal', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
          ],
        ),

        // Table rows (one per item)
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isEven = i % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.blue50,
            ),
            children: [
              _tableCell(item.productName, align: pw.Alignment.centerLeft),
              _tableCell(item.quantity.toString()),
              _tableCell('PKR ${_currencyFmt.format(item.unitPrice)}'),
              _tableCell('PKR ${_currencyFmt.format(item.subtotal)}'),
            ],
          );
        }),
      ],
    );
  }

  /// Helper to build a padded table cell
  static pw.Widget _tableCell(
    String text, {
    pw.TextStyle? style,
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: align,
      child: pw.Text(text, style: style ?? const pw.TextStyle(fontSize: 10)),
    );
  }

  // ── Totals Block ──────────────────────────────────────────
  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 230,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue800,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'GRAND TOTAL',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'PKR ${_currencyFmt.format(invoice.total)}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Additional Info (Notes, T&C) ──────────────────────────
  static pw.Widget _buildAdditionalInfo(Invoice invoice) {
    final hasNotes = invoice.notes != null && invoice.notes!.trim().isNotEmpty;
    final hasTerms = invoice.termsConditions != null &&
        invoice.termsConditions!.trim().isNotEmpty;

    if (!hasNotes && !hasTerms) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Notes section
          if (hasNotes) ...[
            pw.Text(
              'NOTES',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.notes!,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
            if (hasTerms) pw.SizedBox(height: 12),
          ],

          // Terms & Conditions section
          if (hasTerms) ...[
            pw.Text(
              'TERMS & CONDITIONS',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.termsConditions!,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────
  static pw.Widget _buildFooter(ShopSettings settings) {
    final shopName = settings.shopName.isNotEmpty
        ? settings.shopName
        : 'QuickBill PK';

    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Text(
          'Thank you for your business!',
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'Generated by $shopName',
          style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
