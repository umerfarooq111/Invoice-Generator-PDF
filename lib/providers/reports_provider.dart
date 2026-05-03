// ============================================================
// providers/reports_provider.dart
// Manages data for sales analytics and top product reports
// ============================================================

import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SalesDataPoint {
  final String period;
  final double total;
  SalesDataPoint(this.period, this.total);
}

class TopProduct {
  final String name;
  final int totalQty;
  final double revenue;
  TopProduct(this.name, this.totalQty, this.revenue);
}

class ReportsProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<SalesDataPoint> _dailySales = [];
  List<SalesDataPoint> _monthlySales = [];
  List<TopProduct> _topProducts = [];
  
  double _totalSales = 0;
  double _todaySales = 0;
  double _monthlySalesTotal = 0;
  int _totalInvoices = 0;
  String _mostDemandedProduct = 'N/A';
  
  bool _isLoading = false;

  List<SalesDataPoint> get dailySales => _dailySales;
  List<SalesDataPoint> get monthlySales => _monthlySales;
  List<TopProduct> get topProducts => _topProducts;
  
  double get totalSales => _totalSales;
  double get todaySales => _todaySales;
  double get monthlySalesTotal => _monthlySalesTotal;
  int get totalInvoices => _totalInvoices;
  String get mostDemandedProduct => _mostDemandedProduct;
  
  bool get isLoading => _isLoading;

  /// Load all report data from the database
  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch data in parallel
      final results = await Future.wait([
        _db.getDailySales(),
        _db.getMonthlySales(),
        _db.getTopSellingProducts(limit: 5),
        _db.getTotalSales(),
        _db.getTodaySales(),
        _db.getCurrentMonthSales(),
        _db.getInvoiceCount(),
      ]);

      final dailyRaw = results[0] as List<Map<String, dynamic>>;
      final monthlyRaw = results[1] as List<Map<String, dynamic>>;
      final topRaw = results[2] as List<Map<String, dynamic>>;
      
      _totalSales = results[3] as double;
      _todaySales = results[4] as double;
      _monthlySalesTotal = results[5] as double;
      _totalInvoices = results[6] as int;

      _dailySales = dailyRaw.map((m) => SalesDataPoint(
        m['period'] as String,
        (m['total'] as num).toDouble(),
      )).toList();

      _monthlySales = monthlyRaw.map((m) => SalesDataPoint(
        m['period'] as String,
        (m['total'] as num).toDouble(),
      )).toList();

      _topProducts = topRaw.map((m) => TopProduct(
        m['product_name'] as String,
        m['total_qty'] as int,
        (m['revenue'] as num).toDouble(),
      )).toList();
      
      if (_topProducts.isNotEmpty) {
        _mostDemandedProduct = _topProducts.first.name;
      } else {
        _mostDemandedProduct = 'N/A';
      }

    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
