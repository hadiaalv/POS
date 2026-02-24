// lib/database/db_helper.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<String> _getDbPath() async {
    if (kIsWeb) return 'dkfoods_pos.db';

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final dbDir = p.join(exeDir, 'data');
    await Directory(dbDir).create(recursive: true);
    final path = p.join(dbDir, 'dkfoods_pos.db');

    debugPrint('✅ DB path: $path');
    return path;
  }

  Future<Database> _initDB() async {
    final path = await _getDbPath();

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          await db.execute('PRAGMA journal_mode=WAL');
          await db.execute('PRAGMA synchronous=NORMAL');
          debugPrint('✅ DB opened successfully at: $path');
        },
      ),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE orders ADD COLUMN notes TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE customers ADD COLUMN total_orders INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE customers ADD COLUMN total_spent REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE customers ADD COLUMN last_order_at TEXT'); } catch (_) {}
    }
    debugPrint('✅ DB upgraded to version $newVersion');
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        address TEXT,
        total_orders INTEGER DEFAULT 0,
        total_spent REAL DEFAULT 0,
        last_order_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        is_available INTEGER DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        customer_name TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        subtotal REAL NOT NULL,
        delivery_charges REAL DEFAULT 0,
        total REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
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

    debugPrint('✅ All tables created');
  }

  Future<void> seedDefaultData() async {
    final db = await database;
    final cats = await db.query('categories');
    if (cats.isNotEmpty) return;

    final pizzaId    = await db.insert('categories', {'name': 'Pizza'});
    final squareId   = await db.insert('categories', {'name': 'Square Pizza'});
    final royalId    = await db.insert('categories', {'name': 'Royal Crust'});
    final stuffId    = await db.insert('categories', {'name': 'Stuff Crust'});
    final platterId  = await db.insert('categories', {'name': 'Platter'});
    final burgerId   = await db.insert('categories', {'name': 'Burgers'});
    final shawarmaId = await db.insert('categories', {'name': 'Shawarma'});
    final pastaId    = await db.insert('categories', {'name': 'Pasta'});
    final appeId     = await db.insert('categories', {'name': 'Appetizer'});
    final parathaId  = await db.insert('categories', {'name': 'Parathas'});
    final troppingId = await db.insert('categories', {'name': 'Tropping'});
    final bbqId      = await db.insert('categories', {'name': 'BBQ & Bake'});

    Future<void> ins(int catId, List<Map<String, dynamic>> items) async {
      for (final item in items) {
        await db.insert('menu_items', {
          'category_id': catId,
          'name': item['name'],
          'price': item['price'],
          'is_available': 1,
        });
      }
    }

    await ins(pizzaId, [
      {'name': 'Malai Boti (S)',     'price': 0.0},
      {'name': 'Super Supreme (M)',  'price': 950.0},
      {'name': 'Bonifire (L)',       'price': 1250.0},
      {'name': 'Click On (XL)',      'price': 1650.0},
      {'name': 'Dk Special (S)',     'price': 0.0},
      {'name': 'Behari Kabab (M)',   'price': 1050.0},
      {'name': 'Curnchy Pizza (L)',  'price': 1400.0},
      {'name': 'Mughlai Pizza (XL)', 'price': 1950.0},
    ]);
    await ins(squareId, [
      {'name': 'DK Square Pizza (S)', 'price': 500.0},
      {'name': 'DK Square Pizza (M)', 'price': 1100.0},
      {'name': 'DK Square Pizza (L)', 'price': 1700.0},
    ]);
    await ins(royalId, [
      {'name': 'Royal Crust Pizza (L)',  'price': 1350.0},
      {'name': 'Royal Crust Pizza (XL)', 'price': 1850.0},
    ]);
    await ins(stuffId, [
      {'name': 'Kabab Stuffer (Round)',    'price': 2200.0},
      {'name': 'Kabab Stuffer Round (M)',  'price': 1100.0},
      {'name': 'Kabab Stuffer Round (L)',  'price': 1650.0},
      {'name': 'Kabab Stuffer Square (M)', 'price': 1350.0},
      {'name': 'Kabab Stuffer Square (L)', 'price': 1700.0},
      {'name': 'Chicken & Cheese (Round)', 'price': 2200.0},
      {'name': 'Cheese Stuffer (Round)',   'price': 2200.0},
    ]);
    await ins(platterId, [
      {'name': 'Dk Special Platter', 'price': 800.0},
      {'name': 'Malai Boti Platter', 'price': 350.0},
      {'name': 'Zinger Platter',     'price': 380.0},
      {'name': 'Chicken Platter',    'price': 340.0},
    ]);
    await ins(burgerId, [
      {'name': 'Reg Shami Burger',            'price': 150.0},
      {'name': 'Double Shami Burger',         'price': 200.0},
      {'name': 'Fri Egg Burger',              'price': 200.0},
      {'name': 'Fri Egg Double Shami Burger', 'price': 200.0},
      {'name': 'Dk Special Burger',           'price': 250.0},
      {'name': 'Chicken Burger Special',      'price': 340.0},
      {'name': 'Half Chicken Burger',         'price': 240.0},
      {'name': 'Special Zinger Burger',       'price': 340.0},
      {'name': 'Patty Burger',                'price': 250.0},
      {'name': 'Baba T Spicy Burger',         'price': 250.0},
    ]);
    await ins(shawarmaId, [
      {'name': 'Chicken Shawarma',          'price': 180.0},
      {'name': 'Zinger Shawarma',           'price': 240.0},
      {'name': 'Zinger Chicken Shawarma',   'price': 280.0},
      {'name': 'Turkish Shawarma (S)',       'price': 200.0},
      {'name': 'Turkish Shawarma (M)',       'price': 300.0},
      {'name': 'Turkish Shawarma (L)',       'price': 450.0},
      {'name': 'Malai Boti Kabab Shawarma', 'price': 0.0},
      {'name': 'Malai Boti Shawarma',       'price': 0.0},
      {'name': 'Chicken Cheese Shawarma',   'price': 280.0},
      {'name': 'Chicken Kabab Shawarma',    'price': 250.0},
    ]);
    await ins(pastaId, [
      {'name': 'Chef Special Pasta (F1)', 'price': 350.0},
      {'name': 'Chef Special Pasta (F2)', 'price': 650.0},
      {'name': 'Dk Special Pasta (F1)',   'price': 350.0},
      {'name': 'Dk Special Pasta (F2)',   'price': 650.0},
      {'name': 'Curnchy Pasta (F1)',      'price': 450.0},
      {'name': 'Curnchy Pasta (F2)',      'price': 800.0},
    ]);
    await ins(appeId, [
      {'name': 'Mexican Sandwich',       'price': 550.0},
      {'name': 'Classic Sandwich',       'price': 580.0},
      {'name': 'Kabab Stuff Sticks 4pc', 'price': 400.0},
      {'name': 'Oven Bake Wings 6pc',    'price': 300.0},
      {'name': 'Oven Bake Wings 12pc',   'price': 550.0},
      {'name': 'Oven Bake Rolls',        'price': 500.0},
    ]);
    await ins(parathaId, [
      {'name': 'Chicken Paratha',    'price': 330.0},
      {'name': 'Zinger Paratha',     'price': 380.0},
      {'name': 'Malai Boti Paratha', 'price': 0.0},
    ]);
    await ins(troppingId, [
      {'name': 'French Fries', 'price': 100.0},
      {'name': 'Wings',        'price': 100.0},
      {'name': 'Nuggets',      'price': 100.0},
    ]);
    await ins(bbqId, [
      {'name': 'Steam Pece', 'price': 0.0},
      {'name': 'DK Bake',    'price': 0.0},
    ]);

    debugPrint('✅ Default menu data seeded');
  }

  // ── Customer Methods ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    final db = await database;
    final result = await db.query('customers',
        where: 'phone = ?', whereArgs: [phone], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  /// Search customers by phone OR name.
  ///
  /// Results are ranked so that records whose name/phone STARTS WITH the query
  /// come before those that merely CONTAIN it, then sorted by most recent order.
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await database;
    final q       = '%${query.trim()}%';   // contains match
    final qStart  = '${query.trim()}%';    // starts-with match (for ranking)

    return await db.rawQuery('''
      SELECT *,
        CASE
          WHEN LOWER(phone) LIKE LOWER(?) OR LOWER(name) LIKE LOWER(?) THEN 0
          ELSE 1
        END AS rank_order
      FROM customers
      WHERE phone LIKE ? OR LOWER(name) LIKE LOWER(?)
      ORDER BY rank_order ASC, last_order_at DESC, name ASC
      LIMIT 20
    ''', [qStart, qStart, q, q]);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM customers
      ORDER BY last_order_at DESC, name ASC
    ''');
  }

  Future<int> saveCustomer(String phone, String name, String address) async {
    final db = await database;
    final existing = await db.query('customers',
        where: 'phone = ?', whereArgs: [phone], limit: 1);

    if (existing.isNotEmpty) {
      await db.update(
        'customers',
        {'name': name, 'address': address},
        where: 'phone = ?',
        whereArgs: [phone],
      );
      return existing.first['id'] as int;
    } else {
      return await db.insert('customers', {
        'phone': phone,
        'name': name,
        'address': address,
        'total_orders': 0,
        'total_spent': 0.0,
      });
    }
  }

  Future<void> updateCustomer(String phone, String name, String address) async {
    final db = await database;
    await db.update('customers', {'name': name, 'address': address},
        where: 'phone = ?', whereArgs: [phone]);
  }

  Future<void> _updateCustomerStats(
      Database db, int customerId, double orderTotal) async {
    await db.rawUpdate('''
      UPDATE customers
      SET total_orders = COALESCE(total_orders, 0) + 1,
          total_spent  = COALESCE(total_spent, 0) + ?,
          last_order_at = ?
      WHERE id = ?
    ''', [orderTotal, DateTime.now().toIso8601String(), customerId]);
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOrdersByCustomer(int customerId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT o.*,
        (SELECT GROUP_CONCAT(oi.item_name || ' x' || oi.quantity, ', ')
         FROM order_items oi WHERE oi.order_id = o.id) as items_summary
      FROM orders o
      WHERE o.customer_id = ?
      ORDER BY o.created_at DESC
    ''', [customerId]);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await database;
    return await db.query('order_items',
        where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 50}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT o.*,
        (SELECT GROUP_CONCAT(oi.item_name || ' x' || oi.quantity, ', ')
         FROM order_items oi WHERE oi.order_id = o.id) as items_summary
      FROM orders o
      ORDER BY o.created_at DESC
      LIMIT ?
    ''', [limit]);
  }

  // ── Menu Methods ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> getMenuItemsByCategory(
      int categoryId) async {
    final db = await database;
    return await db.query('menu_items',
        where: 'category_id = ? AND is_available = 1',
        whereArgs: [categoryId],
        orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getAllMenuItemsWithCategory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT mi.*, c.name as category_name
      FROM menu_items mi
      JOIN categories c ON mi.category_id = c.id
      ORDER BY c.id, mi.name
    ''');
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

  Future<void> updateMenuItem(int id, String name, double price) async {
    final db = await database;
    await db.update('menu_items', {'name': name, 'price': price},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleMenuItem(int id, bool available) async {
    final db = await database;
    await db.update('menu_items', {'is_available': available ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Save Order ────────────────────────────────────────────────────────────

  Future<int> saveOrder({
    required int? customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double subtotal,
    required double deliveryCharges,
    required double total,
    required List<Map<String, dynamic>> items,
    String? notes,
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
      'notes': notes,
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

    if (customerId != null) {
      await _updateCustomerStats(db, customerId, total);
    }

    return orderId;
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailySalesReport(String date) async {
    final db = await database;

    final orderResult = await db.rawQuery('''
      SELECT COUNT(*) as total_orders, SUM(total) as total_revenue
      FROM orders WHERE DATE(created_at) = ?
    ''', [date]);

    final pizzaResult = await db.rawQuery('''
      SELECT SUM(oi.quantity) as count
      FROM order_items oi JOIN orders o ON oi.order_id = o.id
      WHERE DATE(o.created_at) = ?
        AND (LOWER(oi.category_name) LIKE '%pizza%'
          OR LOWER(oi.category_name) LIKE '%square%'
          OR LOWER(oi.category_name) LIKE '%royal%'
          OR LOWER(oi.category_name) LIKE '%stuff%')
    ''', [date]);

    final shawarmaResult = await db.rawQuery('''
      SELECT SUM(oi.quantity) as count
      FROM order_items oi JOIN orders o ON oi.order_id = o.id
      WHERE DATE(o.created_at) = ? AND LOWER(oi.category_name) LIKE '%shawarma%'
    ''', [date]);

    final burgerResult = await db.rawQuery('''
      SELECT SUM(oi.quantity) as count
      FROM order_items oi JOIN orders o ON oi.order_id = o.id
      WHERE DATE(o.created_at) = ? AND LOWER(oi.category_name) LIKE '%burger%'
    ''', [date]);

    final recentOrders = await db.rawQuery('''
      SELECT id, customer_name, customer_phone, total, created_at
      FROM orders WHERE DATE(created_at) = ?
      ORDER BY created_at DESC
    ''', [date]);

    return {
      'total_orders':    orderResult.first['total_orders'] ?? 0,
      'total_revenue':   orderResult.first['total_revenue'] ?? 0.0,
      'total_pizzas':    pizzaResult.first['count'] ?? 0,
      'total_shawarmas': shawarmaResult.first['count'] ?? 0,
      'total_burgers':   burgerResult.first['count'] ?? 0,
      'recent_orders':   recentOrders,
    };
  }

  Future<void> resetAndReseed() async {
    final db = await database;
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('menu_items');
    await db.delete('categories');
    await db.delete('customers');
    await seedDefaultData();
  }
}