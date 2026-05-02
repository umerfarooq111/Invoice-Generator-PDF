// ============================================================
// providers/customer_provider.dart
// Manages the customer list state and syncs with SQLite
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/database_service.dart';

class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [];

  List<Customer> get customers => List.unmodifiable(_customers);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all customers from the database
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await DatabaseService.instance.getCustomers();
      _customers
        ..clear()
        ..addAll(list);
    } catch (e) {
      _error = 'Failed to load customers: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new customer to the database and local list
  Future<bool> addCustomer(Customer customer) async {
    try {
      final id = await DatabaseService.instance.insertCustomer(customer);
      _customers.add(customer.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add customer: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Update an existing customer record
  Future<bool> updateCustomer(Customer customer) async {
    try {
      await DatabaseService.instance.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update customer: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Delete a customer by id
  Future<bool> deleteCustomer(int id) async {
    try {
      await DatabaseService.instance.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete customer: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }
}
