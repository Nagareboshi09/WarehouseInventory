import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:warehouse_inventory/models/user.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/master_item.dart';
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
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } else {
      _database = await _initDB('warehouse_inventory.db');
    }
    
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
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
      CREATE TABLE master_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL,
        itemClass TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        branchId INTEGER NOT NULL,
        FOREIGN KEY (branchId) REFERENCES branches (id)
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
    final mainWarehouseId = await db.insert('branches', {
      'name': 'Main Warehouse',
      'location': 'Building A, Floor 1'
    });

    final secondaryId = await db.insert('branches', {
      'name': 'Secondary Storage',
      'location': 'Building B, Floor 2'
    });

    final coldStorageId = await db.insert('branches', {
      'name': 'Cold Storage',
      'location': 'Building C, Floor 1'
    });

    // Insert sample master items
    await db.insert('master_items', {
      'sku': 'SKU001',
      'itemClass': 'Electronics',
      'description': 'Smartphone iPhone 14',
      'location': 'Shelf A1',
      'branchId': mainWarehouseId,
    });

    await db.insert('master_items', {
      'sku': 'SKU002',
      'itemClass': 'Clothing',
      'description': 'Cotton T-Shirt Blue',
      'location': 'Rack B2',
      'branchId': secondaryId,
    });

    await db.insert('master_items', {
      'sku': 'SKU003',
      'itemClass': 'Food',
      'description': 'Frozen Chicken 5kg',
      'location': 'Freezer C1',
      'branchId': coldStorageId,
    });

    // Insert sample inventory items
    await db.insert('inventory_items', {
      'sku': 'SKU001',
      'itemClass': 'Electronics',
      'description': 'Smartphone iPhone 14',
      'quantity': 25,
      'location': 'Shelf A1',
      'dateAdded': DateTime.now().toIso8601String(),
      'branchId': mainWarehouseId,
    });

    await db.insert('inventory_items', {
      'sku': 'SKU002',
      'itemClass': 'Clothing',
      'description': 'Cotton T-Shirt Blue',
      'quantity': 100,
      'location': 'Rack B2',
      'dateAdded': DateTime.now().toIso8601String(),
      'branchId': secondaryId,
    });

    await db.insert('inventory_items', {
      'sku': 'SKU003',
      'itemClass': 'Food',
      'description': 'Frozen Chicken 5kg',
      'quantity': 8,
      'location': 'Freezer C1',
      'dateAdded': DateTime.now().toIso8601String(),
      'branchId': coldStorageId,
    });

    // Insert sample data for existing databases
    await _insertSampleData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS master_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sku TEXT NOT NULL,
          itemClass TEXT NOT NULL,
          description TEXT NOT NULL,
          location TEXT NOT NULL,
          branchId INTEGER NOT NULL,
          FOREIGN KEY (branchId) REFERENCES branches (id)
        )
      ''');

      // Insert sample master items for existing branches
      await _insertSampleData(db);
    }
  }

  Future<void> _insertSampleData(Database db) async {
    // Check if sample branches exist, if not create them
    final branchCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM branches')
    ) ?? 0;

    if (branchCount == 0) {
      // Insert default admin user
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123',
        'role': 'admin'
      });

      // Insert sample branches
      final mainWarehouseId = await db.insert('branches', {
        'name': 'Main Warehouse',
        'location': 'Building A, Floor 1'
      });

      final secondaryId = await db.insert('branches', {
        'name': 'Secondary Storage',
        'location': 'Building B, Floor 2'
      });

      final coldStorageId = await db.insert('branches', {
        'name': 'Cold Storage',
        'location': 'Building C, Floor 1'
      });

      // Insert sample master items
      await db.insert('master_items', {
        'sku': 'SKU001',
        'itemClass': 'Electronics',
        'description': 'Smartphone iPhone 14',
        'location': 'Shelf A1',
        'branchId': mainWarehouseId,
      });

      await db.insert('master_items', {
        'sku': 'SKU002',
        'itemClass': 'Clothing',
        'description': 'Cotton T-Shirt Blue',
        'location': 'Rack B2',
        'branchId': secondaryId,
      });

      await db.insert('master_items', {
        'sku': 'SKU003',
        'itemClass': 'Food',
        'description': 'Frozen Chicken 5kg',
        'location': 'Freezer C1',
        'branchId': coldStorageId,
      });

      // Insert sample inventory items
      await db.insert('inventory_items', {
        'sku': 'SKU001',
        'itemClass': 'Electronics',
        'description': 'Smartphone iPhone 14',
        'quantity': 25,
        'location': 'Shelf A1',
        'dateAdded': DateTime.now().toIso8601String(),
        'branchId': mainWarehouseId,
      });

      await db.insert('inventory_items', {
        'sku': 'SKU002',
        'itemClass': 'Clothing',
        'description': 'Cotton T-Shirt Blue',
        'quantity': 100,
        'location': 'Rack B2',
        'dateAdded': DateTime.now().toIso8601String(),
        'branchId': secondaryId,
      });

      await db.insert('inventory_items', {
        'sku': 'SKU003',
        'itemClass': 'Food',
        'description': 'Frozen Chicken 5kg',
        'quantity': 8,
        'location': 'Freezer C1',
        'dateAdded': DateTime.now().toIso8601String(),
        'branchId': coldStorageId,
      });
    }
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

  Future<void> updateBranch(Branch branch) async {
    final db = await instance.database;
    await db.update(
      'branches',
      branch.toMap(),
      where: 'id = ?',
      whereArgs: [branch.id],
    );
  }

  // Master Item methods
  Future<MasterItem> createMasterItem(MasterItem item) async {
    final db = await instance.database;
    final id = await db.insert('master_items', item.toMap());
    return item.id != null ? item : MasterItem(
      id: id,
      sku: item.sku,
      itemClass: item.itemClass,
      description: item.description,
      location: item.location,
      branchId: item.branchId,
    );
  }

  Future<void> updateMasterItem(MasterItem item) async {
    final db = await instance.database;
    await db.update(
      'master_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<List<MasterItem>> getAllMasterItems() async {
    final db = await instance.database;
    final result = await db.query('master_items');
    return result.map((json) => MasterItem.fromMap(json)).toList();
  }

  Future<List<MasterItem>> getMasterItemsByBranch(int branchId) async {
    final db = await instance.database;
    final result = await db.query(
      'master_items',
      where: 'branchId = ?',
      whereArgs: [branchId],
    );
    return result.map((json) => MasterItem.fromMap(json)).toList();
  }

  Future<void> deleteMasterItem(int id) async {
    final db = await instance.database;
    await db.delete(
      'master_items',
      where: 'id = ?',
      whereArgs: [id],
    );
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