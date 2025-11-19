import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bcrypt/bcrypt.dart';

part 'app_database.g.dart';

// Password hashing utilities using bcrypt
class PasswordUtils {
  static String hashPassword(String password) {
    // Use bcrypt for secure password hashing
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    return hashedPassword;
  }

  static bool verifyPassword(String plainPassword, String hashedPassword) {
    // Verify password using bcrypt
    return BCrypt.checkpw(plainPassword, hashedPassword);
  }
}

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

  // Custom transaction method
  Future<void> customWriteTransaction(Future<void> Function() action) async {
    await transaction<void>(() async {
      await action();
    });
  }

  // Fixed batch insert method - use proper table references
  Future<void> batchInsertMasterAndInventoryItems(
    List<MasterItem> items, // Renamed parameter to avoid conflict
    List<int> quantities,
    int branchId,
  ) async {
    await transaction(() async {
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final quantity = quantities[i];

        // Insert into master_items - use the actual table from database
        await into(masterItems).insert(MasterItemsCompanion.insert(
          sku: item.sku,
          description: item.description,
          location: item.location,
          brand: item.brand != null ? Value(item.brand) : const Value.absent(),
          branchId: branchId,
        ));

        // Insert into inventory_items - use the actual table from database
        await into(inventoryItems).insert(InventoryItemsCompanion.insert(
          sku: item.sku,
          description: item.description,
          end: quantity,
          location: item.location,
          brand: item.brand != null ? Value(item.brand) : const Value.absent(),
          dateAdded: DateTime.now().toIso8601String(),
          branchId: branchId,
        ));
      }
    });
  }

  // Add this optimized validation method
  Future<Map<String, bool>> validateSkusForBranch(List<String> skus, int branchId) async {
    final result = <String, bool>{};
    
    await transaction(() async {
      // Get all existing SKUs in this branch in one query
      final existingMasterSkus = await (select(masterItems)
        ..where((m) => m.branchId.equals(branchId) & m.sku.isIn(skus)))
        .get()
        .then((items) => items.map((item) => item.sku).toSet());
      
      final existingInventorySkus = await (select(inventoryItems)
        ..where((i) => i.branchId.equals(branchId) & i.sku.isIn(skus)))
        .get()
        .then((items) => items.map((item) => item.sku).toSet());
      
      final allExistingSkus = {...existingMasterSkus, ...existingInventorySkus};
      
      for (final sku in skus) {
        result[sku] = !allExistingSkus.contains(sku);
      }
    });
    
    return result;
  }

  // Data seeding
  Future<void> _insertDefaultData() async {
    // No default data inserted
    // Users must register their own accounts through the registration screen
  }

  // User methods
  Future<User?> getUser(String username, String password) async {
    // First, get the user by username
    final userData = await (select(users)
      ..where((u) => u.username.equals(username))).getSingleOrNull();
    
    if (userData == null) {
      return null; // User not found
    }

    // Verify the password hash
    if (PasswordUtils.verifyPassword(password, userData.password)) {
      return userData;
    }
    
    return null; // Password doesn't match
  }

  // Check if username already exists
  Future<bool> usernameExists(String username) async {
    final existingUser = await (select(users)
      ..where((u) => u.username.equals(username))).getSingleOrNull();
    return existingUser != null;
  }

  // Register a new user with hashed password
  Future<User?> registerUser(String username, String password, {String role = 'user'}) async {
    try {
      // Check if username already exists
      final exists = await usernameExists(username);
      if (exists) {
        return null; // Username already taken
      }

      // Hash the password and insert new user
      final hashedPassword = PasswordUtils.hashPassword(password);
      final userId = await into(users).insert(
        UsersCompanion.insert(
          username: username,
          password: hashedPassword,
          role: role,
        ),
      );

      // Return the created user
      final newUser = await (select(users)
        ..where((u) => u.id.equals(userId))).getSingle();
      
      return newUser;
    } catch (e) {
      // Handle any database errors
      print('Error registering user: $e');
      return null;
    }
  }

  // Get all users (for admin purposes)
  Future<List<User>> getAllUsers() async {
    final result = await select(users).get();
    return result;
  }

  // Update user role
  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      final user = await (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
      if (user != null) {
        await update(users).replace(user.copyWith(role: newRole));
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Branch methods
  Future<List<Branch>> getAllBranches() async {
    final result = await select(branches).get();
    return result;
  }

  Future<Branch?> getBranchByCode(String code) async {
    final result = await (select(branches)
      ..where((b) => b.code.equals(code))).getSingleOrNull();
    return result;
  }

  Future<bool> branchCodeExists(String code) async {
    final existingBranch = await (select(branches)
      ..where((b) => b.code.equals(code))).getSingleOrNull();
    return existingBranch != null;
  }

  // Cleanup orphaned data - call this once to fix existing database
  Future<void> cleanupOrphanedData() async {
    // Get all existing branch IDs
    final allBranches = await select(branches).get();
    final validBranchIds = allBranches.map((b) => b.id).toSet();
    
    print('Valid branch IDs: $validBranchIds');
    
    // Delete orphaned master items
    final orphanedMasterItems = await (select(masterItems)
      ..where((m) => m.branchId.isNotIn(validBranchIds))).get();
    if (orphanedMasterItems.isNotEmpty) {
      print('Found ${orphanedMasterItems.length} orphaned MasterItems, deleting...');
      await (delete(masterItems)..where((m) => m.branchId.isNotIn(validBranchIds))).go();
    }
    
    // Delete orphaned inventory items
    final orphanedInventoryItems = await (select(inventoryItems)
      ..where((i) => i.branchId.isNotIn(validBranchIds))).get();
    if (orphanedInventoryItems.isNotEmpty) {
      print('Found ${orphanedInventoryItems.length} orphaned InventoryItems, deleting...');
      await (delete(inventoryItems)..where((i) => i.branchId.isNotIn(validBranchIds))).go();
    }
    
    // Delete orphaned orders
    final orphanedOrders = await (select(orders)
      ..where((o) => o.branchId.isNotIn(validBranchIds))).get();
    if (orphanedOrders.isNotEmpty) {
      print('Found ${orphanedOrders.length} orphaned Orders, deleting...');
      await (delete(orders)..where((o) => o.branchId.isNotIn(validBranchIds))).go();
    }
    
    print('Database cleanup completed!');
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
    // Delete in correct order to handle foreign key dependencies
    // 1. Delete orders referencing this branch
    await (delete(orders)..where((o) => o.branchId.equals(id))).go();
    
    // 2. Delete inventory items for this branch
    await (delete(inventoryItems)..where((i) => i.branchId.equals(id))).go();
    
    // 3. Delete master items for this branch
    await (delete(masterItems)..where((m) => m.branchId.equals(id))).go();
    
    // 4. Finally delete the branch itself
    await (delete(branches)..where((b) => b.id.equals(id))).go();
  }

  // Master Items methods
  Future<List<MasterItem>> getAllMasterItems() async {
    final result = await select(masterItems).get();
    return result;
  }

  Future<List<MasterItem>> getMasterItemsByBranch(int branchId) async {
    final result = await (select(masterItems)..where((m) => m.branchId.equals(branchId))).get();
    return result;
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
    return result;
  }

  Future<List<InventoryItem>> getInventoryItemsByBranch(int branchId) async {
    final result = await (select(inventoryItems)..where((i) => i.branchId.equals(branchId))).get();
    return result;
  }

  Future<List<InventoryItem>> searchInventoryItems(String query) async {
    final result = await (select(inventoryItems)
      ..where((i) => i.sku.like('%$query%') | i.description.like('%$query%'))).get();
    return result;
  }

  Future<List<InventoryItem>> getLowStockItems(int threshold) async {
    final result = await (select(inventoryItems)..where((i) => i.end.isSmallerThanValue(threshold + 1))).get();
    return result;
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
    // Check if SKU exists in master_items for this branch
    final existingMasterItem = await (select(masterItems)
      ..where((m) => m.sku.equals(sku) & m.branchId.equals(branchId))).getSingleOrNull();
    
    // Check if SKU exists in inventory_items for this branch
    final existingInventoryItem = await (select(inventoryItems)
      ..where((i) => i.sku.equals(sku) & i.branchId.equals(branchId))).getSingleOrNull();
    
    // SKU exists if it exists in either table
    return existingMasterItem != null || existingInventoryItem != null;
  }

  // Order methods
  Future<List<Order>> getAllOrders() async {
    final result = await select(orders).get();
    return result;
  }

  Future<List<Order>> getOrdersByBranch(int branchId) async {
    final result = await (select(orders)..where((o) => o.branchId.equals(branchId))).get();
    return result;
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