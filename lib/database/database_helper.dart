import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:warehouse_inventory/models/user.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/master_item.dart';
import 'package:warehouse_inventory/models/order.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Stream controller for notifying about data updates
  final StreamController<String> _updateController = StreamController<String>.broadcast();
  Stream<String> get updateStream => _updateController.stream;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      // Use in-memory database for web
      _database = await openDatabase(
        inMemoryDatabasePath,
        version: 11,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } else {
      _database = await _initDB('warehouse_inventory.db');
    }

    // Ensure orders table exists
    await _ensureOrdersTableExists();

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 11, onCreate: _createDB, onUpgrade: _upgradeDB);
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
        location TEXT NOT NULL,
        code TEXT UNIQUE,
        weeklyOrderOfftake TEXT,
        weeklyReorderPoint TEXT,
        maintainingInventory TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE master_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        brand TEXT,
        branchId INTEGER NOT NULL,
        FOREIGN KEY (branchId) REFERENCES branches (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL,
        description TEXT NOT NULL,
        end INTEGER NOT NULL,
        location TEXT NOT NULL,
        brand TEXT,
        dateAdded TEXT NOT NULL,
        branchId INTEGER NOT NULL,
        beg INTEGER,
        prev INTEGER,
        sales INTEGER,
        FOREIGN KEY (branchId) REFERENCES branches (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        branchId INTEGER NOT NULL,
        location TEXT NOT NULL,
        brand TEXT NOT NULL,
        itemId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        dateOrdered TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        batchId TEXT,
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
      'description': 'Smartphone iPhone 14',
      'location': 'Shelf A1',
      'brand': 'Apple',
      'branchId': mainWarehouseId,
    });

    await db.insert('master_items', {
      'sku': 'SKU002',
      'description': 'Cotton T-Shirt Blue',
      'location': 'Rack B2',
      'brand': 'Nike',
      'branchId': secondaryId,
    });

    await db.insert('master_items', {
      'sku': 'SKU003',
      'description': 'Frozen Chicken 5kg',
      'location': 'Freezer C1',
      'brand': 'Tyson',
      'branchId': coldStorageId,
    });

    // Insert sample inventory items
    await db.insert('inventory_items', {
      'sku': 'SKU001',
      'description': 'Smartphone iPhone 14',
      'end': 25,
      'location': 'Shelf A1',
      'dateAdded': DateTime.now().toIso8601String(),
      'branchId': mainWarehouseId,
    });

    await db.insert('inventory_items', {
      'sku': 'SKU002',
      'description': 'Cotton T-Shirt Blue',
      'end': 100,
      'location': 'Rack B2',
      'dateAdded': DateTime.now().toIso8601String(),
      'branchId': secondaryId,
    });

    await db.insert('inventory_items', {
      'sku': 'SKU003',
      'description': 'Frozen Chicken 5kg',
      'end': 8,
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
          description TEXT NOT NULL,
          location TEXT NOT NULL,
          branchId INTEGER NOT NULL,
          FOREIGN KEY (branchId) REFERENCES branches (id)
        )
      ''');

      // Insert sample master items for existing branches
      await _insertSampleData(db);
    }
    if (oldVersion < 3) {
      // Add code column to branches table if it doesn't exist
      await db.execute('ALTER TABLE branches ADD COLUMN code TEXT');
    }
    if (oldVersion < 4) {
      // Add brand column to master_items and inventory_items tables
      await db.execute('ALTER TABLE master_items ADD COLUMN brand TEXT');
      await db.execute('ALTER TABLE inventory_items ADD COLUMN brand TEXT');
    }
    if (oldVersion < 6) {
      // Add orders table
      await db.execute('''
        CREATE TABLE orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          branchId INTEGER NOT NULL,
          location TEXT NOT NULL,
          brand TEXT NOT NULL,
          itemId INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          dateOrdered TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          batchId TEXT,
          FOREIGN KEY (branchId) REFERENCES branches (id)
        )
      ''');
    }
    if (oldVersion < 7) {
      // Force recreate master_items and inventory_items tables to fix schema issues

      // Fix master_items table
      final masterTableInfo = await db.rawQuery("PRAGMA table_info(master_items)");
      final hasMasterLegacyColumns = masterTableInfo.any((column) =>
        column['name'] == 'itemClassCode' || column['name'] == 'itemClass'
      );

      if (hasMasterLegacyColumns || masterTableInfo.isEmpty) {
        try {
          await db.execute('''
            CREATE TABLE master_items_new(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sku TEXT NOT NULL,
              description TEXT NOT NULL,
              location TEXT NOT NULL,
              brand TEXT,
              branchId INTEGER NOT NULL,
              FOREIGN KEY (branchId) REFERENCES branches (id)
            )
          ''');

          try {
            await db.execute('''
              INSERT INTO master_items_new (id, sku, description, location, brand, branchId)
              SELECT id, sku, description, location, brand, branchId FROM master_items
            ''');
          } catch (e) {
            print('Could not copy master_items data: $e');
          }

          await db.execute('DROP TABLE IF EXISTS master_items');
          await db.execute('ALTER TABLE master_items_new RENAME TO master_items');
        } catch (e) {
          print('Error recreating master_items table: $e');
          await db.execute('DROP TABLE IF EXISTS master_items');
          await db.execute('''
            CREATE TABLE master_items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sku TEXT NOT NULL,
              description TEXT NOT NULL,
              location TEXT NOT NULL,
              brand TEXT,
              branchId INTEGER NOT NULL,
              FOREIGN KEY (branchId) REFERENCES branches (id),
              UNIQUE(sku, branchId)
            )
          ''');
        }
      }

      // Fix inventory_items table
      final invTableInfo = await db.rawQuery("PRAGMA table_info(inventory_items)");
      final hasEndColumn = invTableInfo.any((column) => column['name'] == 'end');

      if (!hasEndColumn || invTableInfo.isEmpty) {
        try {
          await db.execute('''
            CREATE TABLE inventory_items_new(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sku TEXT NOT NULL,
              description TEXT NOT NULL,
              end INTEGER NOT NULL,
              location TEXT NOT NULL,
              brand TEXT,
              dateAdded TEXT NOT NULL,
              branchId INTEGER NOT NULL,
              beg INTEGER,
              prev INTEGER,
              sales INTEGER,
              FOREIGN KEY (branchId) REFERENCES branches (id)
            )
          ''');

          try {
            // Try to copy with 'end' column if it exists
            await db.execute('''
              INSERT INTO inventory_items_new (id, sku, description, end, location, brand, dateAdded, branchId)
              SELECT id, sku, description, end, location, brand, dateAdded, branchId FROM inventory_items
            ''');
          } catch (e) {
            print('Could not copy inventory_items data with end column: $e');
            // Try alternative column names
            try {
              await db.execute('''
                INSERT INTO inventory_items_new (id, sku, description, end, location, brand, dateAdded, branchId)
                SELECT id, sku, description, quantity, location, brand, dateAdded, branchId FROM inventory_items
              ''');
            } catch (e2) {
              print('Could not copy inventory_items data: $e2');
            }
          }

          await db.execute('DROP TABLE IF EXISTS inventory_items');
          await db.execute('ALTER TABLE inventory_items_new RENAME TO inventory_items');
        } catch (e) {
          print('Error recreating inventory_items table: $e');
          await db.execute('DROP TABLE IF EXISTS inventory_items');
          await db.execute('''
            CREATE TABLE inventory_items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sku TEXT NOT NULL,
              description TEXT NOT NULL,
              end INTEGER NOT NULL,
              location TEXT NOT NULL,
              brand TEXT,
              dateAdded TEXT NOT NULL,
              branchId INTEGER NOT NULL,
              beg INTEGER,
              prev INTEGER,
              sales INTEGER,
              FOREIGN KEY (branchId) REFERENCES branches (id)
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS orders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              branchId INTEGER NOT NULL,
              location TEXT NOT NULL,
              brand TEXT NOT NULL,
              itemId INTEGER NOT NULL,
              quantity INTEGER NOT NULL,
              dateOrdered TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              batchId TEXT,
              FOREIGN KEY (branchId) REFERENCES branches (id)
            )
          ''');
        }
      }
    }
    if (oldVersion < 9) {
      // Add new columns for inventory management
      await db.execute('ALTER TABLE branches ADD COLUMN weeklyOrderOfftake TEXT');
      await db.execute('ALTER TABLE branches ADD COLUMN weeklyReorderPoint TEXT');
      await db.execute('ALTER TABLE branches ADD COLUMN maintainingInventory TEXT');
    }
    if (oldVersion < 10) {
      // Add unique constraints for branch codes and item SKUs
      // First, handle potential duplicates by updating them to null or appending suffix
      try {
        // For branches with duplicate codes, keep the first one and set others to null
        final duplicateBranches = await db.rawQuery('''
          SELECT code, COUNT(*) as count
          FROM branches
          WHERE code IS NOT NULL
          GROUP BY code
          HAVING count > 1
        ''');

        for (var row in duplicateBranches) {
          final code = row['code'];
          // Update all but the first occurrence to have null code
          await db.rawUpdate('''
            UPDATE branches
            SET code = NULL
            WHERE code = ? AND id NOT IN (
              SELECT MIN(id) FROM branches WHERE code = ?
            )
          ''', [code, code]);
        }

        await db.execute('CREATE UNIQUE INDEX idx_branches_code ON branches(code)');
      } catch (e) {
        print('Could not create unique index on branches.code: $e');
      }

      try {
        // For master_items with duplicate SKUs within the same branch, keep the first one and append suffix to others
        final duplicateItems = await db.rawQuery('''
          SELECT sku, branchId, COUNT(*) as count
          FROM master_items
          GROUP BY sku, branchId
          HAVING count > 1
        ''');

        for (var row in duplicateItems) {
          final sku = row['sku'];
          final branchId = row['branchId'];
          // Get all items with this SKU in this branch except the first one
          final duplicateRows = await db.rawQuery('''
            SELECT id FROM master_items
            WHERE sku = ? AND branchId = ?
            ORDER BY id
            LIMIT -1 OFFSET 1
          ''', [sku, branchId]);

          int suffix = 1;
          for (var dupRow in duplicateRows) {
            final newSku = '${sku}_dup_$suffix';
            await db.update(
              'master_items',
              {'sku': newSku},
              where: 'id = ?',
              whereArgs: [dupRow['id']],
            );
            suffix++;
          }
        }

        await db.execute('CREATE UNIQUE INDEX idx_master_items_sku_branch ON master_items(sku, branchId)');
      } catch (e) {
        print('Could not create unique index on master_items.sku per branch: $e');
      }
    }
    if (oldVersion < 11) {
      // Add beg, prev, sales columns to inventory_items table
      await db.execute('ALTER TABLE inventory_items ADD COLUMN beg INTEGER');
      await db.execute('ALTER TABLE inventory_items ADD COLUMN prev INTEGER');
      await db.execute('ALTER TABLE inventory_items ADD COLUMN sales INTEGER');
    }
  }

  Future<void> _ensureOrdersTableExists() async {
    final db = await database;
    try {
      // Check if orders table exists
      final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='orders'");
      if (result.isEmpty) {
        // Create orders table if it doesn't exist
        await db.execute('''
          CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            branchId INTEGER NOT NULL,
            location TEXT NOT NULL,
            brand TEXT NOT NULL,
            itemId INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            dateOrdered TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            batchId TEXT,
            FOREIGN KEY (branchId) REFERENCES branches (id)
          )
        ''');
      }
    } catch (e) {
      print('Error ensuring orders table exists: $e');
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
        'description': 'Smartphone iPhone 14',
        'location': 'Shelf A1',
        'brand': 'Apple',
        'branchId': mainWarehouseId,
      });

      await db.insert('master_items', {
        'sku': 'SKU002',
        'description': 'Cotton T-Shirt Blue',
        'location': 'Rack B2',
        'brand': 'Nike',
        'branchId': secondaryId,
      });

      await db.insert('master_items', {
        'sku': 'SKU003',
        'description': 'Frozen Chicken 5kg',
        'location': 'Freezer C1',
        'brand': 'Tyson',
        'branchId': coldStorageId,
      });

      // Insert sample inventory items
      await db.insert('inventory_items', {
        'sku': 'SKU001',
        'description': 'Smartphone iPhone 14',
        'end': 25,
        'location': 'Shelf A1',
        'dateAdded': DateTime.now().toIso8601String(),
        'branchId': mainWarehouseId,
      });

      await db.insert('inventory_items', {
        'sku': 'SKU002',
        'description': 'Cotton T-Shirt Blue',
        'end': 100,
        'location': 'Rack B2',
        'dateAdded': DateTime.now().toIso8601String(),
        'branchId': secondaryId,
      });

      await db.insert('inventory_items', {
        'sku': 'SKU003',
        'description': 'Frozen Chicken 5kg',
        'end': 8,
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
      code: branch.code,
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

    // Notify listeners about the update
    _updateController.add('branch_updated');
  }

  Future<void> deleteBranch(int id) async {
    final db = await instance.database;
    await db.delete(
      'branches',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Also delete associated master items and inventory items
    await db.delete(
      'master_items',
      where: 'branchId = ?',
      whereArgs: [id],
    );

    await db.delete(
      'inventory_items',
      where: 'branchId = ?',
      whereArgs: [id],
    );

    // Notify listeners about the deletion
    _updateController.add('branch_deleted');
  }

  // Master Item methods
  Future<MasterItem> createMasterItem(MasterItem item) async {
    final db = await instance.database;
    final id = await db.insert('master_items', item.toMap());

    // Create corresponding inventory item with default quantity 0
    final inventoryId = await db.insert('inventory_items', {
      'sku': item.sku,
      'description': item.description,
      'end': 0,
      'location': item.location,
      'brand': item.brand,
      'dateAdded': DateTime.now().toIso8601String(),
      'branchId': item.branchId,
    });

    return item.id != null ? item : MasterItem(
      id: id,
      sku: item.sku,
      description: item.description,
      location: item.location,
      branchId: item.branchId,
    );
  }

  Future<void> updateMasterItem(MasterItem item) async {
    final db = await instance.database;

    // Get the old master item to find inventory items with the old sku
    final oldItemMaps = await db.query(
      'master_items',
      where: 'id = ?',
      whereArgs: [item.id],
    );
    final oldSku = oldItemMaps.isNotEmpty ? oldItemMaps.first['sku'] as String : item.sku;

    await db.update(
      'master_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    // Update corresponding inventory items using the old sku
    final inventoryItems = await db.query(
      'inventory_items',
      where: 'sku = ? AND branchId = ?',
      whereArgs: [oldSku, item.branchId],
    );

    for (var invMap in inventoryItems) {
      final updatedInv = {
        'sku': item.sku,
        'description': item.description,
        'location': item.location,
        'brand': item.brand,
      };
      await db.update(
        'inventory_items',
        updatedInv,
        where: 'id = ?',
        whereArgs: [invMap['id']],
      );
    }

    // Notify listeners about the update
    _updateController.add('master_item_updated');
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
      description: item.description,
      end: item.end,
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
      where: 'sku LIKE ? OR `description` LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<List<InventoryItem>> getLowStockItems(int threshold) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory_items',
      where: 'end <= ?',
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

  // Order methods
  Future<Order> createOrder(Order order) async {
    final db = await instance.database;
    final id = await db.insert('orders', order.toMap());
    return order.id != null ? order : Order(
      id: id,
      branchId: order.branchId,
      location: order.location,
      brand: order.brand,
      itemId: order.itemId,
      quantity: order.quantity,
      dateOrdered: order.dateOrdered,
      status: order.status,
      batchId: order.batchId,
    );
  }

  Future<List<Order>> getAllOrders() async {
    final db = await instance.database;
    final result = await db.query('orders');
    return result.map((json) => Order.fromMap(json)).toList();
  }

  Future<List<Order>> getOrdersByBranch(int branchId) async {
    final db = await instance.database;
    final result = await db.query(
      'orders',
      where: 'branchId = ?',
      whereArgs: [branchId],
    );
    return result.map((json) => Order.fromMap(json)).toList();
  }

  Future<void> updateOrder(Order order) async {
    final db = await instance.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> deleteOrder(int id) async {
    final db = await instance.database;
    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}