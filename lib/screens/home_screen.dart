// ============================================================
// screens/home_screen.dart
// Dashboard screen — shows total sales and invoice count
// Also provides quick-action button to create a new invoice
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';
import 'package:quickbill_pk/providers/invoice_provider.dart';
import 'package:quickbill_pk/providers/product_provider.dart';
import 'package:quickbill_pk/providers/customer_provider.dart';
import 'package:quickbill_pk/providers/settings_provider.dart';
import '../widgets/common_widgets.dart';
import 'invoices/create_invoice_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Currency formatter for PKR
  final _currencyFmt = NumberFormat('#,##0.00', 'en_US');
  final _dateFmt = DateFormat('EEEE, dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    // Load all data when the home screen first appears
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  /// Load products, customers, invoices, and settings from the database
  Future<void> _loadAllData() async {
    final productProvider = context.read<ProductProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // Load in parallel for speed
    await Future.wait([
      productProvider.loadProducts(),
      customerProvider.loadCustomers(),
      invoiceProvider.loadInvoices(),
      settingsProvider.loadSettings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        // Pull to refresh
        onRefresh: _loadAllData,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, primary.withOpacity(0.75)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QuickBill PK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateFmt.format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Dashboard Content ─────────────────────────
            SliverToBoxAdapter(
              child: Consumer<InvoiceProvider>(
                builder: (_, invoiceProvider, __) {
                  if (invoiceProvider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: LoadingIndicator(),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── Stats Grid ───────────────────────
                      const SectionHeader(title: 'Overview'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.receipt_long,
                                label: 'Total Invoices',
                                value: invoiceProvider.invoiceCount.toString(),
                                color: primary,
                              ),
                            ),
                            Expanded(
                              child: StatCard(
                                icon: Icons.attach_money,
                                label: 'Total Sales',
                                value: 'PKR ${_currencyFmt.format(invoiceProvider.totalSales)}',
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Quick Actions ────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _navigateToCreateInvoice,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('New Invoice'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _navigateToReports,
                                icon: const Icon(Icons.bar_chart, size: 20),
                                label: const Text('Reports'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Recent Invoices ──────────────────
                      const SectionHeader(title: 'Recent Invoices'),
                      if (invoiceProvider.invoices.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No invoices yet',
                          subtitle: 'Tap "Create New Invoice" to get started',
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invoiceProvider.invoices.length > 5
                              ? 5
                              : invoiceProvider.invoices.length,
                          itemBuilder: (_, i) {
                            final inv = invoiceProvider.invoices[i];
                            return _RecentInvoiceTile(invoice: inv);
                          },
                        ),

                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FAB to quickly create a new invoice
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateInvoice,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  void _navigateToCreateInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportsScreen()),
    );
  }
}

// ─── Recent Invoice Tile ──────────────────────────────────

class _RecentInvoiceTile extends StatelessWidget {
  final Invoice invoice;

  const _RecentInvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final currencyFmt = NumberFormat('#,##0.00', 'en_US');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            '#${invoice.id}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          invoice.customerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          dateFmt.format(invoice.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          'PKR ${currencyFmt.format(invoice.total)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
