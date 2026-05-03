// ============================================================
// screens/reports_screen.dart
// Modern Reports Dashboard with Sales Charts and Top Products
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/reports_provider.dart';
import '../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Daily'; // 'Daily' or 'Monthly'
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            onPressed: () => context.read<ReportsProvider>().loadReports(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          final dataPoints = _selectedPeriod == 'Daily' 
              ? provider.dailySales 
              : provider.monthlySales;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Business Overview Section ──────────────────
                const SectionHeader(title: 'Business Overview'),
                const SizedBox(height: 12),
                
                // Primary Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Total Sales',
                        value: 'PKR ${_currencyFmt.format(provider.totalSales)}',
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: "Today's Sales",
                        value: 'PKR ${_currencyFmt.format(provider.todaySales)}',
                        icon: Icons.today,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Secondary Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Monthly Sales',
                        value: 'PKR ${_currencyFmt.format(provider.monthlySalesTotal)}',
                        icon: Icons.calendar_month,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Total Invoices',
                        value: provider.totalInvoices.toString(),
                        icon: Icons.receipt,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Top Product Stat
                _buildStatCard(
                  label: 'Most Demanded Product',
                  value: provider.mostDemandedProduct,
                  icon: Icons.star,
                  color: Colors.red,
                  isWide: true,
                ),

                const SizedBox(height: 32),

                // ── Sales Trend Card ────────────────────────
                const SectionHeader(title: 'Sales Trends'),
                const SizedBox(height: 12),
                _buildCard(
                  title: 'Revenue Trend',
                  subtitle: 'Visualizing your business growth',
                  child: Column(
                    children: [
                      _buildPeriodToggle(),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 220,
                        child: dataPoints.isEmpty 
                          ? _buildEmptyState('No sales data yet')
                          : _buildLineChart(dataPoints, primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Top Products Card ───────────────────────
                _buildCard(
                  title: 'Top Selling Products',
                  subtitle: 'By units sold (Quantity)',
                  child: provider.topProducts.isEmpty
                      ? _buildEmptyState('No products sold yet')
                      : Column(
                          children: provider.topProducts.map((p) => _buildProductRow(p)).toList(),
                        ),
                ),

                const SizedBox(height: 20),

                // ── Revenue Share Card ──────────────────────
                _buildCard(
                  title: 'Revenue Distribution',
                  subtitle: 'Revenue generated per top product',
                  child: SizedBox(
                    height: 200,
                    child: provider.topProducts.isEmpty
                        ? _buildEmptyState('No data available')
                        : _buildPieChart(provider.topProducts),
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          );
        },
      ),
    );
  }

  // ── UI Components ───────────────────────────────────────

  Widget _buildCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ['Daily', 'Monthly'].map((p) {
          final isSelected = _selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ] : [],
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<SalesDataPoint> points, Color color) {
    if (points.isEmpty) return const SizedBox();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList(),
            isCurved: true,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(TopProduct p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_bag, size: 18, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${p.totalQty} units sold', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            'PKR ${_currencyFmt.format(p.revenue)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<TopProduct> products) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: products.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: p.revenue,
            title: p.name.length > 8 ? '${p.name.substring(0, 5)}...' : p.name,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
