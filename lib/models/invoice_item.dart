// ============================================================
// models/invoice_item.dart
// Represents a single line item within an invoice
// (one product + quantity selected by the user)
// ============================================================

class InvoiceItem {
  final int? id;             // DB row id (nullable if not yet saved)
  final int? invoiceId;      // Which invoice this item belongs to
  final int productId;       // FK → products.id
  final String productName;  // Stored to preserve name if product is later edited
  final double unitPrice;    // Price at the time of invoice creation
  final int quantity;        // How many units

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  /// Total cost for this line item
  double get subtotal => unitPrice * quantity;

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
    };
  }

  /// Create from SQLite Map row
  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
    );
  }

  /// Create a copy with optional overrides
  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}
