// ============================================================
// models/invoice.dart
// Represents a complete invoice (header + line items)
// ============================================================

import 'invoice_item.dart';

class Invoice {
  final int? id;                     // DB id (null if not saved yet)
  final String? title;               // Custom invoice name/title (optional)
  final int customerId;              // FK → customers.id
  final String customerName;         // Stored for display even if customer deleted
  final String customerPhone;        // Customer phone at time of creation
  final DateTime createdAt;          // When the invoice was created
  final List<InvoiceItem> items;     // Line items on this invoice
  final double total;                // Grand total (pre-calculated & stored)
  final String? notes;               // Additional notes/messages (optional)
  final String? shopAddress;         // Shop address printed on invoice (optional)
  final String? termsConditions;     // Terms & conditions text (optional)

  Invoice({
    this.id,
    this.title,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.createdAt,
    required this.items,
    required this.total,
    this.notes,
    this.shopAddress,
    this.termsConditions,
  });

  /// Convert Invoice header to Map for SQLite
  /// NOTE: items are stored in a separate table (invoice_items)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'created_at': createdAt.toIso8601String(),
      'total': total,
      'notes': notes,
      'shop_address': shopAddress,
      'terms_conditions': termsConditions,
    };
  }

  /// Create Invoice from SQLite Map (items loaded separately)
  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'] as int?,
      title: map['title'] as String?,
      customerId: map['customer_id'] as int,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      total: (map['total'] as num).toDouble(),
      items: items,
      notes: map['notes'] as String?,
      shopAddress: map['shop_address'] as String?,
      termsConditions: map['terms_conditions'] as String?,
    );
  }

  /// Create a copy with optional field overrides
  Invoice copyWith({
    int? id,
    String? title,
    int? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? createdAt,
    List<InvoiceItem>? items,
    double? total,
    String? notes,
    String? shopAddress,
    String? termsConditions,
  }) {
    return Invoice(
      id: id ?? this.id,
      title: title ?? this.title,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      shopAddress: shopAddress ?? this.shopAddress,
      termsConditions: termsConditions ?? this.termsConditions,
    );
  }

  /// Recalculate total from items (helper for UI)
  static double calculateTotal(List<InvoiceItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Display name — uses custom title or falls back to invoice number
  String get displayName =>
      (title != null && title!.trim().isNotEmpty)
          ? title!
          : '#${id?.toString().padLeft(4, '0') ?? '0000'}';
}
