// ============================================================
// models/customer.dart
// Represents a customer who can be billed via an invoice
// ============================================================

class Customer {
  final int? id;         // Nullable: null means not yet saved to DB
  final String name;     // Customer's full name
  final String phone;    // Customer's phone number (Pakistani format)

  Customer({
    this.id,
    required this.name,
    required this.phone,
  });

  /// Convert Customer to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  /// Create a Customer from a SQLite Map row
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
    );
  }

  /// Create a copy of this Customer with optional field overrides
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, phone: $phone)';
}
