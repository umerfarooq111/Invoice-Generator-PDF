// ============================================================
// models/shop_settings.dart
// Stores shop/business information used across the app
// ============================================================

class ShopSettings {
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String shopEmail;
  final String defaultTerms;
  final String defaultNotes;
  final String currencySymbol;

  const ShopSettings({
    this.shopName = '',
    this.shopAddress = '',
    this.shopPhone = '',
    this.shopEmail = '',
    this.defaultTerms = '',
    this.defaultNotes = '',
    this.currencySymbol = 'PKR',
  });

  /// Whether any shop info has been configured
  bool get isConfigured => shopName.trim().isNotEmpty;

  /// Convert to Map for SQLite storage (key-value pairs)
  Map<String, String> toMap() {
    return {
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_phone': shopPhone,
      'shop_email': shopEmail,
      'default_terms': defaultTerms,
      'default_notes': defaultNotes,
      'currency_symbol': currencySymbol,
    };
  }

  /// Create from a Map of key-value pairs
  factory ShopSettings.fromMap(Map<String, String> map) {
    return ShopSettings(
      shopName: map['shop_name'] ?? '',
      shopAddress: map['shop_address'] ?? '',
      shopPhone: map['shop_phone'] ?? '',
      shopEmail: map['shop_email'] ?? '',
      defaultTerms: map['default_terms'] ?? '',
      defaultNotes: map['default_notes'] ?? '',
      currencySymbol: map['currency_symbol'] ?? 'PKR',
    );
  }

  /// Create a copy with optional overrides
  ShopSettings copyWith({
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? shopEmail,
    String? defaultTerms,
    String? defaultNotes,
    String? currencySymbol,
  }) {
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      shopEmail: shopEmail ?? this.shopEmail,
      defaultTerms: defaultTerms ?? this.defaultTerms,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
