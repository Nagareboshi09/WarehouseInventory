# Warehouse Inventory

A cross-platform Flutter application for managing warehouse inventory across multiple branches. Built with Drift for local offline storage, featuring role-based authentication, batch data operations via Excel/CSV, and real-time dashboard analytics.

---

## Features

- **Authentication & Roles** – Secure login/registration with bcrypt password hashing and role-based access control
- **Multi-Branch Management** – Create, edit, and organize inventory by branch/location
- **Master Data** – Maintain SKU master lists tied to specific branches
- **Inventory Tracking** – Real-time stock levels with low-stock alerts and search
- **Order Management** – Create, track, and batch-process orders by status
- **Dashboard Analytics** – Charts and summaries for inventory and order health
- **Import / Export** – Bulk load data from Excel or CSV; export reports to XLSX or CSV
- **Dark Mode** – System-aware theme with persistent preference
- **Offline-First** – Full local database via Drift (SQLite) with no backend dependency

---

## Tech Stack

| Layer | Package / Tool |
|---|---|
| UI Framework | Flutter 3.x |
| State Management | `provider` |
| Database | `drift` + `sqlite3_flutter_libs` |
| Auth | `bcrypt`, `shared_preferences` |
| Charts | `fl_chart` |
| File I/O | `file_picker`, `excel`, `csv`, `spreadsheet_decoder` |
| Sharing | `share_plus`, `open_file` |
| Permissions | `permission_handler` |
| Background | `workmanager`, `isolate` |
| Logging | `logging` |

---


## Database Schema

| Table | Key Fields |
|---|---|
| `Users` | id, username, password (bcrypt), role |
| `Branches` | id, name, location, code, weeklyOrderOfftake, weeklyReorderPoint |
| `MasterItems` | id, sku, description, location, brand, branchId |
| `InventoryItems` | id, sku, description, end (qty), location, brand, dateAdded, branchId, beg, prev, sales |
| `Orders` | id, branchId, location, brand, itemId, quantity, dateOrdered, status, batchId |

Schema version: **13** with migration strategy for onCreate/onUpgrade.

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.9.2`
- Dart SDK `^3.9.2`
- Android Studio / Xcode / Visual Studio (for platform tooling)
- A supported platform: Android, iOS, Windows, macOS, Linux, or Web

### Install

```bash
# Install dependencies
flutter pub get

# Generate Drift code
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run

```bash
# Available platforms (pick one or more)
flutter run                    # Default device
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome          # Web
flutter run -d emulator-5554   # Android
```

### Launcher Icons

```bash
flutter pub run flutter_launcher_icons:main
```

---

## Key Flows

### Login & Auth
1. First launch opens `LoginScreen`
2. Users register with username + password (bcrypt-hashed)
3. Default role is `user`; admins can manage roles via `AccountScreen`
4. Session is not persistent across app restarts unless extended with token storage

### Inventory Lifecycle
1. **Master Data** – Define SKUs and descriptions per branch
2. **Add Inventory** – Assign stock quantities to master items
3. **Orders** – Create orders referencing inventory items; batch by `batchId`
4. **Dashboard** – Monitor low stock, branch performance, sales trends

### Batch Operations
- `batchInsertMasterAndInventoryItems` wraps master + inventory inserts in a single Drift transaction
- `validateSkusForBranch` checks SKU uniqueness in one round-trip

---

## Configuration

| Setting | Location |
|---|---|
| App name / version | `pubspec.yaml` |
| Theme seed color | `lib/main.dart` (`ColorScheme.fromSeed`) |
| Dark mode persistence | `shared_preferences` key `darkMode` |
| Database path | `getApplicationDocumentsDirectory/warehouse_inventory.db` |
| Log level | `Logger.root.level = Level.ALL` in `main.dart` |

---

## Testing

```bash
flutter test
```

---

## Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
flutter build macos --release
flutter build linux --release
flutter build web --release
```

---

## Notes

- The database starts **empty**; no default users or demo data are seeded.
- Orphaned records are cleaned up on app startup via `cleanupOrphanedData()`.
- Web platform uses an in-memory database; data is lost on page reload.
- `permission_handler` is included; ensure platform-specific permission manifests are configured if using file-sharing features.
