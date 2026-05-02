// ============================================================
// providers/invoice_provider.dart
// Manages invoice list, dashboard stats, and PDF operations
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/invoice_item.dart';
import '../models/shop_settings.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final List<Invoice> _invoices = [];

  List<Invoice> get invoices => List.unmodifiable(_invoices);

  // Dashboard stats (cached to avoid frequent DB calls)
  double _totalSales = 0;
  int _invoiceCount = 0;

  double get totalSales => _totalSales;
  int get invoiceCount => _invoiceCount;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all invoices from the database (called on app start / refresh)
  Future<void> loadInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _invoices
        ..clear()
        ..addAll(await DatabaseService.instance.getInvoices());
      await _refreshStats();
    } catch (e) {
      _error = 'Failed to load invoices: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create and save a new invoice with optional extra info
  Future<bool> createInvoice({
    required Customer customer,
    required List<InvoiceItem> items,
    String? title,
    String? notes,
    String? shopAddress,
    String? termsConditions,
  }) async {
    if (items.isEmpty) return false;

    try {
      final total = Invoice.calculateTotal(items);
      final invoice = Invoice(
        title: title,
        customerId: customer.id!,
        customerName: customer.name,
        customerPhone: customer.phone,
        createdAt: DateTime.now(),
        items: items,
        total: total,
        notes: notes,
        shopAddress: shopAddress,
        termsConditions: termsConditions,
      );

      final id = await DatabaseService.instance.insertInvoice(invoice);
      // Add to local list with the real DB id
      _invoices.insert(0, invoice.copyWith(id: id));
      await _refreshStats();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create invoice: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Delete an invoice by id
  Future<bool> deleteInvoice(int id) async {
    try {
      await DatabaseService.instance.deleteInvoice(id);
      _invoices.removeWhere((inv) => inv.id == id);
      await _refreshStats();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete invoice: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Generate and share the PDF for a given invoice
  Future<void> shareInvoicePdf(Invoice invoice,
      {ShopSettings? shopSettings}) async {
    try {
      await PdfService.generateAndShareInvoice(invoice,
          shopSettings: shopSettings);
    } catch (e) {
      _error = 'Failed to generate PDF: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Preview invoice PDF in viewer
  Future<void> previewInvoicePdf(Invoice invoice,
      {ShopSettings? shopSettings}) async {
    try {
      await PdfService.previewInvoice(invoice, shopSettings: shopSettings);
    } catch (e) {
      _error = 'Failed to preview PDF: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Refresh cached dashboard statistics
  Future<void> _refreshStats() async {
    _totalSales = await DatabaseService.instance.getTotalSales();
    _invoiceCount = await DatabaseService.instance.getInvoiceCount();
  }
}
