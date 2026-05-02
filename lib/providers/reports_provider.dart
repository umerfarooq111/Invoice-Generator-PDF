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
  bool _isLoading = false;

  List<SalesDataPoint> get dailySales => _dailySales;
  List<SalesDataPoint> get monthlySales => _monthlySales;
  List<TopProduct> get topProducts => _topProducts;
  bool get isLoading => _isLoading;

  /// Load all report data from the database
  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dailyRaw = await _db.getDailySales();
      final monthlyRaw = await _db.getMonthlySales();
      final topRaw = await _db.getTopSellingProducts(limit: 5);

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

    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
