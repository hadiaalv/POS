// lib/database/db_helper.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        is_available INTEGER DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        customer_name TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        subtotal REAL NOT NULL,
        delivery_charges REAL DEFAULT 0,
        total REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        menu_item_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        category_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');
  }

  // ─── Seed default menu data ───────────────────────────────────────────────

  Future<void> seedDefaultData() async {
    final db = await database;

    // Check if already seeded
    final cats = await db.query('categories');
    if (cats.isNotEmpty) return;

    // Insert categories
    final pizzaId = await db.insert('categories', {'name': 'Pizza'});
    final shawarmaId = await db.insert('categories', {'name': 'Shawarma'});

    // Pizza items
    final pizzaItems = [
      {'name': 'Margherita Pizza', 'price': 500.0},
      {'name': 'BBQ Chicken Pizza', 'price': 700.0},
      {'name': 'Veggie Pizza', 'price': 550.0},
      {'name': 'Pepperoni Pizza', 'price': 750.0},
      {'name': 'Beef Pizza', 'price': 800.0},
      {'name': 'Cheese Burst Pizza', 'price': 850.0},
    ];

    for (final item in pizzaItems) {
      await db.insert('menu_items', {
        'category_id': pizzaId,
        'name': item['name'],
        'price': item['price'],
        'is_available': 1,
      });
    }

    // Shawarma items
    final shawarmaItems = [
      {'name': 'Chicken Shawarma', 'price': 250.0},
      {'name': 'Beef Shawarma', 'price': 300.0},
      {'name': 'Mix Shawarma', 'price': 320.0},
      {'name': 'Shawarma Platter', 'price': 600.0},
      {'name': 'Shawarma Roll', 'price': 200.0},
    ];

    for (final item in shawarmaItems) {
      await db.insert('menu_items', {
        'category_id': shawarmaId,
        'name': item['name'],
        'price': item['price'],
        'is_available': 1,
      });
    }
  }

  // ─── CUSTOMER OPERATIONS ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  Future<int> saveCustomer(String phone, String name, String address) async {
    final db = await database;
    return await db.insert(
      'customers',
      {'phone': phone, 'name': name, 'address': address},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCustomer(String phone, String name, String address) async {
    final db = await database;
    await db.update(
      'customers',
      {'name': name, 'address': address},
      where: 'phone = ?',
      whereArgs: [phone],
    );
  }

  // ─── CATEGORY OPERATIONS ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'id ASC');
  }

  // ─── MENU ITEM OPERATIONS ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMenuItemsByCategory(int categoryId) async {
    final db = await database;
    return await db.query(
      'menu_items',
      where: 'category_id = ? AND is_available = 1',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
  }

  Future<int> addMenuItem(int categoryId, String name, double price) async {
    final db = await database;
    return await db.insert('menu_items', {
      'category_id': categoryId,
      'name': name,
      'price': price,
      'is_available': 1,
    });
  }

  Future<void> toggleMenuItem(int id, bool available) async {
    final db = await database;
    await db.update(
      'menu_items',
      {'is_available': available ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── ORDER OPERATIONS ────────────────────────────────────────────────────

  Future<int> saveOrder({
    required int? customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double subtotal,
    required double deliveryCharges,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final orderId = await db.insert('orders', {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'subtotal': subtotal,
      'delivery_charges': deliveryCharges,
      'total': total,
      'created_at': now,
    });

    for (final item in items) {
      await db.insert('order_items', {
        'order_id': orderId,
        'menu_item_id': item['menu_item_id'],
        'item_name': item['item_name'],
        'category_name': item['category_name'],
        'price': item['price'],
        'quantity': item['quantity'],
      });
    }

    return orderId;
  }

  // ─── SALES REPORT ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailySalesReport(String date) async {
    final db = await database;

    // Total orders and revenue for the day
    final orderResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_orders,
        SUM(total) as total_revenue
      FROM orders
      WHERE DATE(created_at) = ?
    ''', [date]);

    // Count pizzas sold
    final pizzaResult = await db.rawQuery('''
      SELECT SUM(oi.quantity) as count
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE DATE(o.created_at) = ? AND LOWER(oi.category_name) = 'pizza'
    ''', [date]);

    // Count shawarmas sold
    final shawarmaResult = await db.rawQuery('''
      SELECT SUM(oi.quantity) as count
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE DATE(o.created_at) = ? AND LOWER(oi.category_name) = 'shawarma'
    ''', [date]);

    // Recent orders
    final recentOrders = await db.rawQuery('''
      SELECT id, customer_name, customer_phone, total, created_at
      FROM orders
      WHERE DATE(created_at) = ?
      ORDER BY created_at DESC
    ''', [date]);

    return {
      'total_orders': orderResult.first['total_orders'] ?? 0,
      'total_revenue': orderResult.first['total_revenue'] ?? 0.0,
      'total_pizzas': pizzaResult.first['count'] ?? 0,
      'total_shawarmas': shawarmaResult.first['count'] ?? 0,
      'recent_orders': recentOrders,
    };
  }
}