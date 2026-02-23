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
    final path = join(dbPath, 'dkfoods_pos.db');

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

  // ─── SEED DK FOODS MENU ───────────────────────────────────────────────────

  Future<void> seedDefaultData() async {
    final db = await database;
    final cats = await db.query('categories');
    if (cats.isNotEmpty) return;

    // ── Categories ──
    final pizzaId      = await db.insert('categories', {'name': 'Pizza'});
    final squareId     = await db.insert('categories', {'name': 'Square Pizza'});
    final royalId      = await db.insert('categories', {'name': 'Royal Crust'});
    final stuffId      = await db.insert('categories', {'name': 'Stuff Crust'});
    final platterId    = await db.insert('categories', {'name': 'Platter'});
    final burgerId     = await db.insert('categories', {'name': 'Burgers'});
    final shawarmaId   = await db.insert('categories', {'name': 'Shawarma'});
    final pastaId      = await db.insert('categories', {'name': 'Pasta'});
    final appeId       = await db.insert('categories', {'name': 'Appetizer'});
    final parathaId    = await db.insert('categories', {'name': 'Parathas'});
    final troppingId   = await db.insert('categories', {'name': 'Tropping'});
    final bbqId        = await db.insert('categories', {'name': 'BBQ & Bake'});

    // ── Pizza ──
    final pizzaItems = [
      {'name': 'Malai Boti (S)',       'price': 0.0},
      {'name': 'Super Supreme (M)',    'price': 950.0},
      {'name': 'Bonifire (L)',         'price': 1250.0},
      {'name': 'Click On (XL)',        'price': 1650.0},
      {'name': 'Dk Special (S)',       'price': 0.0},
      {'name': 'Behari Kabab (M)',     'price': 1050.0},
      {'name': 'Curnchy Pizza (L)',    'price': 1400.0},
      {'name': 'Mughlai Pizza (XL)',   'price': 1950.0},
    ];
    for (final item in pizzaItems) {
      await db.insert('menu_items', {'category_id': pizzaId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── DK Square Pizza ──
    final squareItems = [
      {'name': 'DK Square Pizza (S)', 'price': 500.0},
      {'name': 'DK Square Pizza (M)', 'price': 1100.0},
      {'name': 'DK Square Pizza (L)', 'price': 1700.0},
    ];
    for (final item in squareItems) {
      await db.insert('menu_items', {'category_id': squareId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Royal Crust Pizza ──
    final royalItems = [
      {'name': 'Royal Crust Pizza (L)',  'price': 1350.0},
      {'name': 'Royal Crust Pizza (XL)', 'price': 1850.0},
    ];
    for (final item in royalItems) {
      await db.insert('menu_items', {'category_id': royalId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Stuff Crust Pizza ──
    final stuffItems = [
      {'name': 'Kabab Stuffer (Round)',          'price': 2200.0},
      {'name': 'Kabab Stuffer Round (M)',        'price': 1100.0},
      {'name': 'Kabab Stuffer Round (L)',        'price': 1650.0},
      {'name': 'Kabab Stuffer Square (M)',       'price': 1350.0},
      {'name': 'Kabab Stuffer Square (L)',       'price': 1700.0},
      {'name': 'Chicken & Cheese (Round)',       'price': 2200.0},
      {'name': 'Cheese Stuffer (Round)',         'price': 2200.0},
    ];
    for (final item in stuffItems) {
      await db.insert('menu_items', {'category_id': stuffId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Platter ──
    final platterItems = [
      {'name': 'Dk Special Platter',   'price': 800.0},
      {'name': 'Malai Boti Platter',   'price': 350.0},
      {'name': 'Zinger Platter',       'price': 380.0},
      {'name': 'Chicken Platter',      'price': 340.0},
    ];
    for (final item in platterItems) {
      await db.insert('menu_items', {'category_id': platterId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Burgers ──
    final burgerItems = [
      {'name': 'Reg Shami Burger',           'price': 150.0},
      {'name': 'Double Shami Burger',        'price': 200.0},
      {'name': 'Fri Egg Burger',             'price': 200.0},
      {'name': 'Fri Egg Double Shami Burger','price': 200.0},
      {'name': 'Dk Special Burger',          'price': 250.0},
      {'name': 'Chicken Burger Special',     'price': 340.0},
      {'name': 'Half Chicken Burger',        'price': 240.0},
      {'name': 'Special Zinger Burger',      'price': 340.0},
      {'name': 'Patty Burger',               'price': 250.0},
      {'name': 'Baba T Spicy Burger',        'price': 250.0},
    ];
    for (final item in burgerItems) {
      await db.insert('menu_items', {'category_id': burgerId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Shawarma ──
    final shawarmaItems = [
      {'name': 'Chicken Shawarma',           'price': 180.0},
      {'name': 'Zinger Shawarma',            'price': 240.0},
      {'name': 'Zinger Chicken Shawarma',    'price': 280.0},
      {'name': 'Turkish Shawarma (S)',        'price': 200.0},
      {'name': 'Turkish Shawarma (M)',        'price': 300.0},
      {'name': 'Turkish Shawarma (L)',        'price': 450.0},
      {'name': 'Malai Boti Kabab Shawarma',  'price': 0.0},
      {'name': 'Malai Boti Shawarma',        'price': 0.0},
      {'name': 'Chicken Cheese Shawarma',    'price': 280.0},
      {'name': 'Chicken Kabab Shawarma',     'price': 250.0},
    ];
    for (final item in shawarmaItems) {
      await db.insert('menu_items', {'category_id': shawarmaId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Delicious Pasta ──
    final pastaItems = [
      {'name': 'Chef Special Pasta (F1)',  'price': 350.0},
      {'name': 'Chef Special Pasta (F2)',  'price': 650.0},
      {'name': 'Dk Special Pasta (F1)',    'price': 350.0},
      {'name': 'Dk Special Pasta (F2)',    'price': 650.0},
      {'name': 'Curnchy Pasta (F1)',       'price': 450.0},
      {'name': 'Curnchy Pasta (F2)',       'price': 800.0},
    ];
    for (final item in pastaItems) {
      await db.insert('menu_items', {'category_id': pastaId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Appetizer ──
    final appeItems = [
      {'name': 'Mexican Sandwich',       'price': 550.0},
      {'name': 'Classic Sandwich',       'price': 580.0},
      {'name': 'Kabab Stuff Sticks 4pc', 'price': 400.0},
      {'name': 'Oven Bake Wings 6pc',    'price': 300.0},
      {'name': 'Oven Bake Wings 12pc',   'price': 550.0},
      {'name': 'Oven Bake Rolls',        'price': 500.0},
    ];
    for (final item in appeItems) {
      await db.insert('menu_items', {'category_id': appeId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Parathas ──
    final parathaItems = [
      {'name': 'Chicken Paratha',    'price': 330.0},
      {'name': 'Zinger Paratha',     'price': 380.0},
      {'name': 'Malai Boti Paratha', 'price': 0.0},
    ];
    for (final item in parathaItems) {
      await db.insert('menu_items', {'category_id': parathaId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── Tropping ──
    final troppingItems = [
      {'name': 'French Fries', 'price': 100.0},
      {'name': 'Wings',        'price': 100.0},
      {'name': 'Nuggets',      'price': 100.0},
    ];
    for (final item in troppingItems) {
      await db.insert('menu_items', {'category_id': troppingId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
    }

    // ── BBQ & Bake ──
    final bbqItems = [
      {'name': 'Steam Pece', 'price': 0.0},
      {'name': 'DK Bake',    'price': 0.0},
    ];
    for (final item in bbqItems) {
      await db.insert('menu_items', {'category_id': bbqId, 'name': item['name'], 'price': item['price'], 'is_available': 1});
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
    await db.update(
      'menu_items',
      {'name': name, 'price': price},
      where: 'id = ?',
      whereArgs: [id],
    );
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

  // ─── RESET DB (for dev) ───────────────────────────────────────────────────
  Future<void> resetAndReseed() async {
    final db = await database;
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('menu_items');
    await db.delete('categories');
    await seedDefaultData();
  }
}