// ============================================================
// screens/invoices/invoice_history_screen.dart
// Displays all saved invoices with share/delete options
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import 'package:quickbill_pk/providers/invoice_provider.dart';
import 'package:quickbill_pk/providers/settings_provider.dart';
import '../../widgets/common_widgets.dart';
import '../invoices/create_invoice_screen.dart';
import '../invoice_detail_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final _currencyFmt = NumberFormat('#,##0.00', 'en_US');
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          Consumer<InvoiceProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${p.invoices.length} total'),
              ),
            ),
          ),
        ],
      ),

      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const LoadingIndicator();

          if (provider.invoices.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No invoices yet',
              subtitle: 'Create your first invoice from the Home screen',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadInvoices(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: provider.invoices.length,
              itemBuilder: (_, i) {
                final invoice = provider.invoices[i];
                return _InvoiceCard(
                  invoice: invoice,
                  currencyFmt: _currencyFmt,
                  dateFmt: _dateFmt,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoiceDetailScreen(invoice: invoice),
                    ),
                  ),
                  onShare: () {
                    final settings = context.read<SettingsProvider>().settings;
                    provider.shareInvoicePdf(invoice, shopSettings: settings);
                  },
                  onDelete: () => _confirmDelete(context, provider, invoice),
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    InvoiceProvider provider,
    Invoice invoice,
  ) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      itemName: 'Invoice #${invoice.id} (${invoice.customerName})',
    );
    if (confirmed == true && context.mounted) {
      final success = await provider.deleteInvoice(invoice.id!);
      if (!success && context.mounted) {
        showErrorSnackBar(context, 'Failed to delete invoice');
      } else if (context.mounted) {
        showSuccessSnackBar(context, 'Invoice deleted');
      }
    }
  }
}

// ─── Invoice Card ─────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.currencyFmt,
    required this.dateFmt,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Top Row: Invoice # + Date ──────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Invoice number badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${invoice.id?.toString().padLeft(4, '0') ?? '0000'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    dateFmt.format(invoice.createdAt),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Middle Row: Customer info ──────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      invoice.customerName[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        Text(
                          '${invoice.items.length} item(s) • ${invoice.customerPhone}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'PKR ${currencyFmt.format(invoice.total)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              // ── Bottom Row: Action Buttons ─────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Share PDF button
                  TextButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Share PDF'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
