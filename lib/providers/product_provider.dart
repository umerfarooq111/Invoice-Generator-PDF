// ============================================================
// providers/product_provider.dart
// Manages the product list state and syncs with SQLite
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ProductProvider extends ChangeNotifier {
  // Internal list of all products (private)
  final List<Product> _products = [];

  // Public getter — read-only view of the products list
  List<Product> get products => List.unmodifiable(_products);

  // Loading & error state
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all products from the database (called on app start / refresh)
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await DatabaseService.instance.getProducts();
      _products
        ..clear()
        ..addAll(list);
    } catch (e) {
      _error = 'Failed to load products: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new product to the database and refresh the local list
  Future<bool> addProduct(Product product) async {
    try {
      final id = await DatabaseService.instance.insertProduct(product);
      _products.add(product.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add product: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Update an existing product in the database and local list
  Future<bool> updateProduct(Product product) async {
    try {
      await DatabaseService.instance.updateProduct(product);
      // Replace the old product in the list with the updated one
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update product: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Delete a product from the database and remove from local list
  Future<bool> deleteProduct(int id) async {
    try {
      await DatabaseService.instance.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete product: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  // ─── Stock Alert Helpers ────────────────────────────────

  /// Products with zero stock
  List<Product> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  /// Products with stock ≤ 5
  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  /// Whether any stock alerts exist
  bool get hasStockAlerts =>
      outOfStockProducts.isNotEmpty || lowStockProducts.isNotEmpty;

  /// Deduct stock for each product in the invoice
  /// Returns a list of products that became out-of-stock
  Future<List<Product>> deductStockForInvoice(
      Map<int, int> productQuantities) async {
    final nowOutOfStock = <Product>[];

    for (final entry in productQuantities.entries) {
      final productId = entry.key;
      final qty = entry.value;

      // Deduct in DB
      await DatabaseService.instance.deductStock(productId, qty);

      // Update local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final oldProduct = _products[index];
        final newStock = (oldProduct.stock - qty).clamp(0, oldProduct.stock);
        final updated = oldProduct.copyWith(stock: newStock);
        _products[index] = updated;

        if (updated.isOutOfStock && !oldProduct.isOutOfStock) {
          nowOutOfStock.add(updated);
        }
      }
    }

    notifyListeners();
    return nowOutOfStock;
  }
}
