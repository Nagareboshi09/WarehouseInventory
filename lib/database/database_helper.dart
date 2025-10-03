import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:warehouse_inventory/models/user.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (kIsWeb) {
      // Use in-memory database for web
      _database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _createDB
      );
    } else {
      _database = await _initDB('warehouse_inventory.db');
    }
    
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE branches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL,
        itemClass TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        location TEXT NOT NULL,
        dateAdded TEXT NOT NULL,
        branchId INTEGER NOT NULL,
        FOREIGN KEY (branchId) REFERENCES branches (id)
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin'
    });

    // Insert sample branches
    await db.insert('branches', {
      'name': 'Main Warehouse',
      'location': 'Building A, Floor 1'
    });

    await db.insert('branches', {
      'name': 'Secondary Storage',
      'location': 'Building B, Floor 2'
    });

    await db.insert('branches', {
      'name': 'Cold Storage',
      'location': 'Building C, Floor 1'
    });
  }

  // User methods
  Future<User> createUser(User user) async {
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return user.id != null ? user : User(
      id: id,
      username: user.username,
      password: user.password,
      role: user.role,
    );
  }

  Future<User?> getUser(String username, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Branch methods
  Future<Branch> createBranch(Branch branch) async {
    final db = await instance.database;
    final id = await db.insert('branches', branch.toMap());
    return branch.id != null ? branch : Branch(
      id: id,
      name: branch.name,
      location: branch.location,
    );
  }

  Future<List<Branch>> getAllBranches() async {
    final db = await instance.database;
    final result = await db.query('branches');
    return result.map((json) => Branch.fromMap(json)).toList();
  }

  // Inventory methods
  Future<InventoryItem> createInventoryItem(InventoryItem item) async {
    final db = await instance.database;
    final id = await db.insert('inventory_items', item.toMap());
    return item.id != null ? item : InventoryItem(
      id: id,
      sku: item.sku,
      itemClass: item.itemClass,
      description: item.description,
      quantity: item.quantity,
      location: item.location,
      dateAdded: item.dateAdded,
      branchId: item.branchId,
    );
  }

  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await instance.database;
    final result = await db.query('inventory_items');
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<List<InventoryItem>> getInventoryItemsByBranch(int branchId) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory_items',
      where: 'branchId = ?',
      whereArgs: [branchId],
    );
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<List<InventoryItem>> searchInventoryItems(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory_items',
      where: 'sku LIKE ? OR description LIKE ? OR itemClass LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
    );
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<List<InventoryItem>> getLowStockItems(int threshold) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory_items',
      where: 'quantity <= ?',
      whereArgs: [threshold],
    );
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await instance.database;
    await db.update(
      'inventory_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}