// ============================================================
// screens/invoice_detail_screen.dart
// Shows full details of a single invoice with PDF preview/share
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';
import '../models/invoice_item.dart';
import 'package:quickbill_pk/providers/invoice_provider.dart';
import 'package:quickbill_pk/providers/settings_provider.dart';
import '../widgets/common_widgets.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('dd MMMM yyyy, hh:mm a');
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          invoice.displayName,
        ),
        actions: [
          // Share PDF action in AppBar
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () {
              final settings = context.read<SettingsProvider>().settings;
              context.read<InvoiceProvider>().shareInvoicePdf(invoice,
                  shopSettings: settings);
            },
          ),
          // Preview PDF action
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Preview PDF',
            onPressed: () {
              final settings = context.read<SettingsProvider>().settings;
              context.read<InvoiceProvider>().previewInvoicePdf(invoice,
                  shopSettings: settings);
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Invoice Header Card ───────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice # and Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INVOICE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '#${invoice.id?.toString().padLeft(4, '0') ?? '0000'}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Show custom title if present
                            if (invoice.title != null &&
                                invoice.title!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  invoice.title!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.receipt_long, color: primary, size: 32),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Date
                    _InfoRow(
                      label: 'Date',
                      value: dateFmt.format(invoice.createdAt),
                      icon: Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Customer Card ─────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BILLED TO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Name',
                      value: invoice.customerName,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Phone',
                      value: invoice.customerPhone,
                      icon: Icons.phone_outlined,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Items Table Card ──────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITEMS (${invoice.items.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Product',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(
                            width: 40,
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Item rows
                    ...invoice.items.asMap().entries.map((entry) {
                      return _ItemRow(
                        item: entry.value,
                        isEven: entry.key % 2 == 0,
                        currencyFmt: currencyFmt,
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Total Card ────────────────────────────────
            Card(
              color: primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'PKR ${currencyFmt.format(invoice.total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Additional Information ────────────────────
            if (_hasAdditionalInfo(invoice)) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADDITIONAL INFORMATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Divider(height: 20),

                      // Shop Address
                      if (invoice.shopAddress != null &&
                          invoice.shopAddress!.trim().isNotEmpty) ...[
                        _InfoRow(
                          label: 'Shop Address',
                          value: invoice.shopAddress!,
                          icon: Icons.store_outlined,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Notes
                      if (invoice.notes != null &&
                          invoice.notes!.trim().isNotEmpty) ...[
                        _InfoRow(
                          label: 'Notes',
                          value: invoice.notes!,
                          icon: Icons.sticky_note_2_outlined,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Terms & Conditions
                      if (invoice.termsConditions != null &&
                          invoice.termsConditions!.trim().isNotEmpty) ...[
                        _InfoRow(
                          label: 'Terms & Conditions',
                          value: invoice.termsConditions!,
                          icon: Icons.gavel_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Action Buttons ────────────────────────────
            ElevatedButton.icon(
              onPressed: () {
                final settings = context.read<SettingsProvider>().settings;
                context.read<InvoiceProvider>().shareInvoicePdf(invoice,
                    shopSettings: settings);
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share Invoice PDF'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                final settings = context.read<SettingsProvider>().settings;
                context.read<InvoiceProvider>().previewInvoicePdf(invoice,
                    shopSettings: settings);
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Preview PDF'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Check if any additional info fields are present
  static bool _hasAdditionalInfo(Invoice invoice) {
    return (invoice.shopAddress != null && invoice.shopAddress!.trim().isNotEmpty) ||
        (invoice.notes != null && invoice.notes!.trim().isNotEmpty) ||
        (invoice.termsConditions != null && invoice.termsConditions!.trim().isNotEmpty);
  }
}

// ─── Info Row Helper ──────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─── Item Row in Detail ───────────────────────────────────

class _ItemRow extends StatelessWidget {
  final InvoiceItem item;
  final bool isEven;
  final NumberFormat currencyFmt;

  const _ItemRow({
    required this.item,
    required this.isEven,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.productName,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '×${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              currencyFmt.format(item.unitPrice),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              currencyFmt.format(item.subtotal),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
