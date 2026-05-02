// ============================================================
// services/database_service.dart
// Singleton SQLite service — handles all DB operations
// Uses the sqflite package for local, offline storage
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/product.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/shop_settings.dart';

class DatabaseService {
  // ── Singleton pattern ──────────────────────────────────────
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  // ──────────────────────────────────────────────────────────

  static Database? _database;

  /// Returns the database, initializing it if needed
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // ─── Database Initialization ──────────────────────────────

  Future<Database> _initDatabase() async {
    // Get the platform-specific path for storing databases
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quickbill_pk.db');

    return openDatabase(
      path,
      version: 3, // v3: adds settings table + invoice extra columns
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Safety check: Ensure settings table exists even if migration was interrupted
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key   TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
    );
  }

  /// Creates all required tables on first launch
  Future<void> _createTables(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT    NOT NULL,
        price REAL    NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT NOT NULL,
        phone TEXT NOT NULL
      )
    ''');

    // Invoices header table (with extra info columns)
    await db.execute('''
      CREATE TABLE invoices (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        title            TEXT,
        customer_id      INTEGER NOT NULL,
        customer_name    TEXT    NOT NULL,
        customer_phone   TEXT    NOT NULL,
        created_at       TEXT    NOT NULL,
        total            REAL    NOT NULL,
        notes            TEXT,
        shop_address     TEXT,
        terms_conditions TEXT
      )
    ''');

    // Invoice line items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id   INTEGER NOT NULL,
        product_id   INTEGER NOT NULL,
        product_name TEXT    NOT NULL,
        unit_price   REAL    NOT NULL,
        quantity     INTEGER NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
      )
    ''');

    // Settings table (key-value pairs for shop info)
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// Handle database schema upgrades for existing users
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: Add new columns to invoices table
      await db.execute('ALTER TABLE invoices ADD COLUMN title TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN shop_address TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN terms_conditions TEXT');
    }
    if (oldVersion < 3) {
      // v2 → v3: Add settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key   TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL DEFAULT ''
        )
      ''');
    }
  }

  // ─── Product CRUD ─────────────────────────────────────────

  /// Insert a new product; returns the new row id
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Fetch all products ordered alphabetically
  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// Update an existing product record
  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Delete a product by its id
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Deduct stock for a product by the given quantity
  Future<void> deductStock(int productId, int quantity) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
      [quantity, productId],
    );
  }

  // ─── Customer CRUD ────────────────────────────────────────

  /// Insert a new customer; returns the new row id
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert('customers', customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Fetch all customers ordered alphabetically
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  /// Update an existing customer record
  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete a customer by id
  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Invoice CRUD ─────────────────────────────────────────

  /// Internal helper to ensure newer invoice columns exist (Self-Healing)
  Future<void> _ensureInvoiceColumns() async {
    final db = await database;
    // Check if columns exist by attempting to add them (SQLite ignores if already there is tricky,
    // so we catch the error if they exist)
    try {
      await db.execute('ALTER TABLE invoices ADD COLUMN title TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE invoices ADD COLUMN notes TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE invoices ADD COLUMN shop_address TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE invoices ADD COLUMN terms_conditions TEXT');
    } catch (_) {}
  }

  /// Save a full invoice (header + all line items) in one transaction
  Future<int> insertInvoice(Invoice invoice) async {
    await _ensureInvoiceColumns();
    final db = await database;

    // Use a transaction to ensure both header & items are saved atomically
    return db.transaction<int>((txn) async {
      // Insert invoice header
      final invoiceId = await txn.insert('invoices', invoice.toMap());

      // Insert each line item linked to this invoice
      for (final item in invoice.items) {
        await txn.insert('invoice_items', item.copyWith(invoiceId: invoiceId).toMap());
      }

      return invoiceId;
    });
  }

  /// Fetch all invoices with their items, newest first
  Future<List<Invoice>> getInvoices() async {
    await _ensureInvoiceColumns();
    final db = await database;

    // Get invoice headers
    final invoiceMaps = await db.query('invoices', orderBy: 'created_at DESC');

    // For each header, load its items
    final invoices = <Invoice>[];
    for (final map in invoiceMaps) {
      final id = map['id'] as int;
      final items = await _getItemsForInvoice(db, id);
      invoices.add(Invoice.fromMap(map, items));
    }

    return invoices;
  }

  /// Load items belonging to a specific invoice
  Future<List<InvoiceItem>> _getItemsForInvoice(Database db, int invoiceId) async {
    final maps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  /// Delete an invoice and all its items (cascade)
  Future<int> deleteInvoice(int id) async {
    final db = await database;
    // Items are deleted automatically via ON DELETE CASCADE
    return db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Settings CRUD ────────────────────────────────────────

  /// Internal helper to ensure settings table exists (Self-Healing)
  Future<void> _ensureSettingsTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// Save a setting key-value pair (insert or update)
  Future<void> saveSetting(String key, String value) async {
    await _ensureSettingsTable();
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a single setting value by key
  Future<String?> getSetting(String key) async {
    await _ensureSettingsTable();
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  /// Load all settings as a Map
  Future<Map<String, String>> getAllSettings() async {
    await _ensureSettingsTable();
    final db = await database;
    final maps = await db.query('settings');
    final result = <String, String>{};
    for (final row in maps) {
      result[row['key'] as String] = row['value'] as String? ?? '';
    }
    return result;
  }

  /// Save the entire ShopSettings object
  Future<void> saveShopSettings(ShopSettings settings) async {
    await _ensureSettingsTable();
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in settings.toMap().entries) {
        await txn.insert(
          'settings',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Load ShopSettings from the database
  Future<ShopSettings> loadShopSettings() async {
    final map = await getAllSettings(); // Already calls _ensureSettingsTable
    return ShopSettings.fromMap(map);
  }

  // ─── Dashboard Stats ─────────────────────────────────────

  /// Total revenue across all invoices
  Future<double> getTotalSales() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(total) as total FROM invoices');
    final value = result.first['total'];
    return value == null ? 0.0 : (value as num).toDouble();
  }

  /// Total number of invoices ever created
  Future<int> getInvoiceCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
    return (result.first['count'] as int?) ?? 0;
  }
}
