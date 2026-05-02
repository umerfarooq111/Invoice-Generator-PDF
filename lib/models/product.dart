// ============================================================
// models/product.dart
// Represents a product/service that can be added to an invoice
// ============================================================

class Product {
  final int? id;           // Nullable: null means not yet saved to DB
  final String name;       // Product name, e.g. "Chai"
  final double price;      // Price per unit in PKR
  final int stock;         // Available stock quantity

  Product({
    this.id,
    required this.name,
    required this.price,
    this.stock = 0,
  });

  /// Whether this product is out of stock
  bool get isOutOfStock => stock <= 0;

  /// Whether stock is running low (≤5 units remaining)
  bool get isLowStock => stock > 0 && stock <= 5;

  /// Convert a Product to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
    };
  }

  /// Create a Product from a SQLite Map row
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
    );
  }

  /// Create a copy of this Product with optional field overrides
  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';
}
