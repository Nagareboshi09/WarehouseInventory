import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'app_database.g.dart';

// Define all our tables as classes
@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  TextColumn get role => text()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Branch')
class Branches extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get location => text()();
  TextColumn get code => text().nullable()();
  TextColumn get weeklyOrderOfftake => text().nullable()();
  TextColumn get weeklyReorderPoint => text().nullable()();
  TextColumn get maintainingInventory => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MasterItem')
class MasterItems extends Table {
  IntColumn get id => integer()();
  TextColumn get sku => text()();
  TextColumn get description => text()();
  TextColumn get location => text()();
  TextColumn get brand => text().nullable()();
  IntColumn get branchId => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InventoryItem')
class InventoryItems extends Table {
  IntColumn get id => integer()();
  TextColumn get sku => text()();
  TextColumn get description => text()();
  IntColumn get end => integer()();
  TextColumn get location => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get dateAdded => text()();
  TextColumn get lastUpdated => text().nullable()();
  IntColumn get branchId => integer()();
  IntColumn get beg => integer().nullable()();
  IntColumn get prev => integer().nullable()();
  IntColumn get sales => integer().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Order')
class Orders extends Table {
  IntColumn get id => integer()();
  IntColumn get branchId => integer()();
  TextColumn get location => text()();
  TextColumn get brand => text()();
  IntColumn get itemId => integer()();
  IntColumn get quantity => integer()();
  TextColumn get dateOrdered => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get batchId => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Define our database
@DriftDatabase(tables: [Users, Branches, MasterItems, InventoryItems, Orders])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase _instance = AppDatabase._();
  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertDefaultData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 13) {
          // Perform schema changes for version 13
          // No migrations needed since we're creating fresh database
        }
      },
      beforeOpen: (OpeningDetails details) async {
        // Additional setup after opening the database
        // Enable foreign keys - this will be available through generated code
      },
    );
  }

  // Database connection helper
  static QueryExecutor _openConnection() {
    if (kIsWeb) {
      // Use memory database for web
      return NativeDatabase.memory();
    }

    // For mobile and desktop platforms - use LazyDatabase for async path resolution
    return LazyDatabase(
      () async {
        final docsDir = await getApplicationDocumentsDirectory();
        return NativeDatabase(
          File(p.join(docsDir.path, 'warehouse_inventory.db')),
          logStatements: true,
        );
      },
    );
  }

  // Data seeding
  Future<void> _insertDefaultData() async {
    // Check if we already have data
    final userCount = await select(users).get().then((list) => list.length);
    if (userCount > 0) return; // Data already exists

    // Insert default admin user
    await into(users).insert(
      UsersCompanion.insert(
        username: 'admin',
        password: 'admin123',
        role: 'admin',
      ),
    );

    // Insert sample branches
    final mainWarehouseId = await into(branches).insert(
      BranchesCompanion.insert(
        name: 'Main Warehouse',
        location: 'Building A, Floor 1',
        code: Value.absent(),
        weeklyOrderOfftake: Value.absent(),
        weeklyReorderPoint: Value.absent(),
        maintainingInventory: Value.absent(),
      ),
    );

    final secondaryId = await into(branches).insert(
      BranchesCompanion.insert(
        name: 'Secondary Storage',
        location: 'Building B, Floor 2',
        code: Value.absent(),
        weeklyOrderOfftake: Value.absent(),
        weeklyReorderPoint: Value.absent(),
        maintainingInventory: Value.absent(),
      ),
    );

    final coldStorageId = await into(branches).insert(
      BranchesCompanion.insert(
        name: 'Cold Storage',
        location: 'Building C, Floor 1',
        code: Value.absent(),
        weeklyOrderOfftake: Value.absent(),
        weeklyReorderPoint: Value.absent(),
        maintainingInventory: Value.absent(),
      ),
    );

    // Insert sample master items
    await into(masterItems).insert(MasterItemsCompanion.insert(
      sku: 'SKU001',
      description: 'Smartphone iPhone 14',
      location: 'Shelf A1',
      brand: Value('Apple'),
      branchId: mainWarehouseId,
    ));
    await into(masterItems).insert(MasterItemsCompanion.insert(
      sku: 'SKU002',
      description: 'Cotton T-Shirt Blue',
      location: 'Rack B2',
      brand: Value('Nike'),
      branchId: secondaryId,
    ));
    await into(masterItems).insert(MasterItemsCompanion.insert(
      sku: 'SKU003',
      description: 'Frozen Chicken 5kg',
      location: 'Freezer C1',
      brand: Value('Tyson'),
      branchId: coldStorageId,
    ));

    // Insert sample inventory items
    await into(inventoryItems).insert(InventoryItemsCompanion.insert(
      sku: 'SKU001',
      description: 'Smartphone iPhone 14',
      end: 25,
      location: 'Shelf A1',
      brand: Value('Apple'),
      dateAdded: DateTime.now().toIso8601String(),
      lastUpdated: Value.absent(),
      branchId: mainWarehouseId,
      beg: Value.absent(),
      prev: Value.absent(),
      sales: Value.absent(),
    ));
    await into(inventoryItems).insert(InventoryItemsCompanion.insert(
      sku: 'SKU002',
      description: 'Cotton T-Shirt Blue',
      end: 100,
      location: 'Rack B2',
      brand: Value('Nike'),
      dateAdded: DateTime.now().toIso8601String(),
      lastUpdated: Value.absent(),
      branchId: secondaryId,
      beg: Value.absent(),
      prev: Value.absent(),
      sales: Value.absent(),
    ));
    await into(inventoryItems).insert(InventoryItemsCompanion.insert(
      sku: 'SKU003',
      description: 'Frozen Chicken 5kg',
      end: 8,
      location: 'Freezer C1',
      brand: Value('Tyson'),
      dateAdded: DateTime.now().toIso8601String(),
      lastUpdated: Value.absent(),
      branchId: coldStorageId,
      beg: Value.absent(),
      prev: Value.absent(),
      sales: Value.absent(),
    ));
  }

  // User methods
  Future<User?> getUser(String username, String password) async {
    final query = (select(users)
      ..where((u) => u.username.equals(username) & u.password.equals(password)));
    
    final userData = await query.getSingleOrNull();
    return userData; // Return the generated User class directly
  }

  // Branch methods
  Future<List<Branch>> getAllBranches() async {
    final result = await select(branches).get();
    return result; // Return the generated Branch class directly
  }

  Future<int> insertBranch(Branch branch) async {
    return await into(branches).insert(
      branch.toCompanion(false),
    );
  }

  Future<void> updateBranch(Branch branch) async {
    await update(branches).replace(branch);
  }

  Future<void> deleteBranch(int id) async {
    await (delete(branches)..where((b) => b.id.equals(id))).go();
  }

  // Master Items methods
  Future<List<MasterItem>> getAllMasterItems() async {
    final result = await select(masterItems).get();
    return result; // Return the generated MasterItem class directly
  }

  Future<List<MasterItem>> getMasterItemsByBranch(int branchId) async {
    final result = await (select(masterItems)..where((m) => m.branchId.equals(branchId))).get();
    return result; // Return the generated MasterItem class directly
  }

  Future<int> insertMasterItem(MasterItem item) async {
    return await into(masterItems).insert(
      item.toCompanion(false),
    );
  }

  Future<int> insertMasterItemFromCompanion(MasterItemsCompanion companion) async {
    return await into(masterItems).insert(companion);
  }

  Future<void> updateMasterItem(MasterItem item) async {
    await update(masterItems).replace(item);
  }

  Future<void> deleteMasterItem(int id) async {
    await (delete(masterItems)..where((m) => m.id.equals(id))).go();
  }

  // Inventory methods
  Future<List<InventoryItem>> getAllInventoryItems() async {
    final result = await select(inventoryItems).get();
    return result; // Return the generated InventoryItem class directly
  }

  Future<List<InventoryItem>> getInventoryItemsByBranch(int branchId) async {
    final result = await (select(inventoryItems)..where((i) => i.branchId.equals(branchId))).get();
    return result; // Return the generated InventoryItem class directly
  }

  Future<List<InventoryItem>> searchInventoryItems(String query) async {
    final result = await (select(inventoryItems)
      ..where((i) => i.sku.like('%$query%') | i.description.like('%$query%'))).get();
    return result; // Return the generated InventoryItem class directly
  }

  Future<List<InventoryItem>> getLowStockItems(int threshold) async {
    final result = await (select(inventoryItems)..where((i) => i.end.isSmallerThanValue(threshold + 1))).get();
    return result; // Return the generated InventoryItem class directly
  }

  Future<int> insertInventoryItem(InventoryItem item) async {
    return await into(inventoryItems).insert(
      item.toCompanion(false),
    );
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await update(inventoryItems).replace(item);
  }

  Future<bool> checkSkuExistsInBranch(String sku, int branchId) async {
    final result = await (select(inventoryItems)
      ..where((i) => i.sku.equals(sku) & i.branchId.equals(branchId))).getSingleOrNull();
    return result != null;
  }

  // Order methods
  Future<List<Order>> getAllOrders() async {
    final result = await select(orders).get();
    return result; // Return the generated Order class directly
  }

  Future<List<Order>> getOrdersByBranch(int branchId) async {
    final result = await (select(orders)..where((o) => o.branchId.equals(branchId))).get();
    return result; // Return the generated Order class directly
  }

  Future<int> insertOrder(Order order) async {
    return await into(orders).insert(
      order.toCompanion(false),
    );
  }

  Future<void> updateOrder(Order order) async {
    await update(orders).replace(order);
  }

  Future<void> deleteOrder(int id) async {
    await (delete(orders)..where((o) => o.id.equals(id))).go();
  }
}