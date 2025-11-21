import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift hide Column;
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:warehouse_inventory/widgets/filter_widget.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:logging/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:warehouse_inventory/utils/user_helper.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key, 
    this.initialBranch, 
    this.showLowStockOnly = false,
    this.editBatchOrders,
  });

  final Branch? initialBranch;
  final bool showLowStockOnly;
  final List<Order>? editBatchOrders;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Logger _logger = Logger('InventoryScreen');
  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> _filteredItems = [];
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  bool _isLoading = true;
  bool _branchSelected = false;
  bool _isExporting = false; // Prevent multiple concurrent exports
  String _searchQuery = '';
  String _branchSearchQuery = '';
  
  // Order editing variables
  bool _isEditMode = false;
  List<Order> _editBatchOrders = [];
  Map<int, TextEditingController> _orderQuantityControllers = {};
  Map<int, int> _orderQuantities = {};
  String _orderLocation = '';

  @override
  void initState() {
    super.initState();
    _initializeLogger();
    
    // Check if we're in edit mode
    if (widget.editBatchOrders != null && widget.editBatchOrders!.isNotEmpty) {
      _isEditMode = true;
      _editBatchOrders = widget.editBatchOrders!;
      
      // Set the branch from the first order
      final firstOrder = _editBatchOrders.first;
      _orderLocation = firstOrder.location;
      
      // Initialize order quantity controllers
      for (final order in _editBatchOrders) {
        _orderQuantityControllers[order.itemId] = TextEditingController(text: order.quantity.toString());
        _orderQuantities[order.itemId] = order.quantity;
      }
    }
    
    _loadBranches();
  }

  void _initializeLogger() {
    // Configure logging level based on environment
    Logger.root.level = Level.INFO; // Set to Level.ALL for debug, Level.INFO for production
    
    // Set up logging listener for console output
    Logger.root.onRecord.listen((LogRecord record) {
      final timestamp = record.time.toIso8601String().split('T')[1].split('.')[0];
      final level = record.level.name.padRight(7);
      final loggerName = record.loggerName.padRight(15);
      final message = record.message;
      
      // Use different emojis for different log levels
      final emoji = switch (record.level.name) {
        'FINE' || 'FINER' || 'FINEST' => '🔍',
        'INFO' => 'ℹ️',
        'WARNING' => '⚠️',
        'SEVERE' => '❌',
        _ => '📝',
      };
      
      print('$emoji $timestamp [$level] $loggerName: $message');
      
      // Log stack trace for errors
      if (record.level >= Level.SEVERE && record.stackTrace != null) {
        print('Stack trace: ${record.stackTrace}');
      }
    });
  }

Future<void> _loadBranches() async {
    try {
      final branches = await AppDatabase.instance.getAllBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          // Update selected branch if it exists
          if (_selectedBranch != null) {
            try {
              final updatedBranch = branches.firstWhere(
                (branch) => branch.id == _selectedBranch!.id,
              );
              _selectedBranch = updatedBranch;
            } catch (e) {
              // Branch not found, might be deleted, so set to null
              _selectedBranch = null;
              _branchSelected = false;
              _inventoryItems = [];
              _filteredItems = [];
            }
          } else if (widget.initialBranch != null) {
            // Set initial branch if provided
            try {
              final initialBranch = branches.firstWhere((branch) => branch.id == widget.initialBranch!.id);
              _selectedBranch = initialBranch;
            } catch (e) {
              // Initial branch not found
            }
          }
          _isLoading = false;
          // Load items if branch is selected
          if (_selectedBranch != null) {
            _loadInventoryItems();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading branches: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

Future<void> _loadInventoryItems() async {
    if (_selectedBranch == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await AppDatabase.instance.getInventoryItemsByBranch(
        _selectedBranch!.id,
      );
      if (mounted) {
        List<InventoryItem> filteredItems = items;
        if (widget.showLowStockOnly) {
          final maintainingInventory = int.tryParse(_selectedBranch?.maintainingInventory ?? '10') ?? 10;
          final lowStockThreshold = maintainingInventory - 1;
          filteredItems = items.where((item) => item.end <= lowStockThreshold).toList();
        }
        setState(() {
          _inventoryItems = items;
          _filteredItems = filteredItems;
          _isLoading = false;
          _branchSelected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetBranchSelection() {
    setState(() {
      _selectedBranch = null;
      _branchSelected = false;
      _inventoryItems = [];
      _filteredItems = [];
      _searchQuery = '';
    });
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _inventoryItems;
      } else {
        _filteredItems = _inventoryItems.where((item) {
          return item.sku.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              (item.brand?.toLowerCase() ?? '').contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildInfoRow(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithDate(String label, String value, String? date) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 16)),
                if (date != null) Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.parse(date)),
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, Function(String) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRowWithDate(String label, TextEditingController controller, DateTime date, Function(String) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(date)}', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Test method to debug the export process
  void _testInventoryData() {
    if (_selectedBranch == null) {
      _logger.fine('❌ No branch selected');
      return;
    }
     
    if (_inventoryItems.isEmpty) {
      _logger.warning('❌ No inventory items found for branch: ${_selectedBranch!.name}');
      _logger.fine('Branch ID: ${_selectedBranch!.id}');
      return;
    }
     
    _logger.info('✅ Data verification:');
    _logger.fine('Branch: ${_selectedBranch!.name}');
    _logger.fine('Total items: ${_inventoryItems.length}');
    _logger.fine('First item: ${_inventoryItems.first.sku} - ${_inventoryItems.first.description} - Qty: ${_inventoryItems.first.end}');
    _logger.fine('Last item: ${_inventoryItems.last.sku} - ${_inventoryItems.last.description} - Qty: ${_inventoryItems.last.end}');
  }

  Future<void> _exportInventoryToFile() async {
    // Prevent multiple concurrent exports
    if (_isExporting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Export already in progress. Please wait...'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_selectedBranch == null || _inventoryItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No inventory data to export'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Test the data before export
    _testInventoryData();

    // Set exporting flag to prevent concurrent operations
    setState(() {
      _isExporting = true;
    });

    // Show initial loading message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Creating Excel file...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Create file name with format: branchCode_branchName_date
      final String currentDate = DateTime.now().toIso8601String().split('T')[0];
      final String branchName = _selectedBranch!.name.replaceAll(' ', '_');
      final String branchCode = _selectedBranch!.code ?? _selectedBranch!.id.toString(); // Use branch code from master data, fallback to ID
      final String fileName = '${branchCode}_${branchName}_${currentDate}.xlsx';
      
      // Run the export operation
      final exportResult = await _performExportInBackground(_inventoryItems, fileName);
      
      if (exportResult['success'] == true) {
        final String filePath = exportResult['path'];
        final File file = File(filePath);
        
        // Debug: Show the file path for troubleshooting
        _logger.info('✅ Export successful!');
        _logger.fine('File saved at: $filePath');
        _logger.fine('File exists: ${await file.exists()}');
        _logger.fine('File size: ${await file.length()} bytes');
        
        if (mounted) {
          // Show options to user
          _showExportOptions(file, fileName);
        }
      } else {
        throw Exception(exportResult['error'] ?? 'Unknown export error');
      }
      
    } catch (e, stackTrace) {
      _logger.severe('Export error: $e', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error exporting inventory: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: () => _exportInventoryToFile(),
            ),
          ),
        );
      }
    } finally {
      // Always reset the exporting flag
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // Show export options dialog
  void _showExportOptions(File file, String fileName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Export Complete!',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Excel file created successfully!',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'File: $fileName',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Items exported: ${_inventoryItems.length}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Includes user export information',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What would you like to do?',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await Share.shareXFiles(
                    [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
                    subject: 'Inventory Export - ${_selectedBranch!.name}',
                    text: 'Here is the inventory export for ${_selectedBranch!.name}. This export includes user information for accountability.',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing file: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0651A4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Share'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await OpenFile.open(file.path);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error opening file: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  // Perform the actual export operation in background to prevent UI blocking
  Future<Map<String, dynamic>> _performExportInBackground(
    List<InventoryItem> items,
    String fileName,
  ) async {
    try {
      // Get current user information
      final userInfo = await UserHelper.getCurrentUser();
      final username = userInfo?['username'] ?? 'Unknown User';
      final userRole = userInfo?['role'] ?? 'user';
      final currentTimestamp = DateTime.now().toIso8601String();
      
      // Log the export activity
      _logger.info('📤 Export initiated by user: $username (Role: $userRole) for branch: ${_selectedBranch?.name}');
      
      // Create Excel workbook
      final excel = Excel.createExcel();
      
      // Get the first (default) sheet that Excel creates automatically
      // DO NOT access by string name to avoid creating additional sheets
      final sheet = excel.sheets.values.first;
      
      // Sort items by brand name A-Z for better organization
      items.sort((a, b) {
        final brandA = (a.brand ?? 'N/A').toLowerCase();
        final brandB = (b.brand ?? 'N/A').toLowerCase();
        return brandA.compareTo(brandB);
      });
      
      // Add headers
      sheet.appendRow(['SKU', 'Description', 'Brand', 'Location', 'Quantity', 'Beg', 'Prev', 'Sales']);
      
      // Add data rows - simplified to avoid batch processing issues
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final brand = item.brand ?? 'N/A';
        final description = item.description;
        final beg = item.beg?.toString() ?? 'N/A';
        final prev = item.prev?.toString() ?? 'N/A';
        final sales = item.sales?.toString() ?? 'N/A';
        
        sheet.appendRow([
          item.sku,
          description,
          brand,
          item.location.toString(),
          item.end.toString(),
          beg,
          prev,
          sales
        ]);
        
        // Add small delay every 100 items to prevent UI blocking
        if (i % 100 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // Add user information at the bottom of the file
      sheet.appendRow(['']); // Empty row for spacing
      sheet.appendRow(['Export Information']);
      sheet.appendRow(['Prepared by:', username]);
      sheet.appendRow(['Code', _selectedBranch?.code ?? 'Unknown']);
      sheet.appendRow(['Export Date:', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())]);
      sheet.appendRow(['Branch:', _selectedBranch?.name ?? 'Unknown']);

      // Encode Excel data once
      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to encode Excel file');
      }

      // Try multiple storage locations with proper error handling
      String savePath = '';
      String locationName = '';
      bool savedSuccessfully = false;
      
      if (Platform.isAndroid) {
        try {
          int sdkInt = 28; // Default to Android 9 for safety
          
          // Try to get Android version, but don't fail if it doesn't work
          try {
            final androidInfo = await DeviceInfoPlugin().androidInfo;
            sdkInt = androidInfo.version.sdkInt;
          } catch (e) {
            _logger.warning('Could not get Android version, using default (Android 9): $e');
          }
          
          // Method 1: For Android 10+ with permissions (scoped storage)
          if (sdkInt >= 29) {
            if (await Permission.manageExternalStorage.isGranted) {
              try {
                final downloadsDir = await getDownloadsDirectory();
                if (downloadsDir != null) {
                  final warehouseDir = Directory('${downloadsDir.path}/WarehouseInventory');
                  
                  if (!await warehouseDir.exists()) {
                    await warehouseDir.create(recursive: true);
                  }
                  
                  final file = File('${warehouseDir.path}/$fileName');
                  await file.writeAsBytes(bytes);
                  savePath = file.absolute.path;
                  locationName = 'Downloads/WarehouseInventory folder (PUBLIC)';
                  savedSuccessfully = true;
                  _logger.fine('✅ Saved to public Downloads for Android 10+');
                }
              } catch (e) {
                _logger.warning('Public Downloads failed for Android 10+: $e');
              }
            }
          }
          
          // Method 2: Use app-scoped storage (works for all Android versions)
          if (!savedSuccessfully) {
            try {
              final appDir = await getApplicationDocumentsDirectory();
              final exportsDir = Directory('${appDir.path}/Exports');
              
              if (!await exportsDir.exists()) {
                await exportsDir.create(recursive: true);
              }
              
              final file = File('${exportsDir.path}/$fileName');
              await file.writeAsBytes(bytes);
              savePath = file.absolute.path;
              
              // Provide clear location name based on Android version
              if (sdkInt <= 28) {
                locationName = 'Exports folder (Android 9- compatible)';
                _logger.fine('✅ Saved to app-scoped Exports for Android 9- compatibility');
              } else {
                locationName = 'Exports folder (app-scoped)';
                _logger.fine('✅ Saved to app-scoped Exports (no permissions needed)');
              }
              savedSuccessfully = true;
            } catch (e) {
              _logger.warning('App-scoped storage failed: $e');
            }
          }
        } catch (e) {
          _logger.warning('Android-specific storage logic failed: $e');
          
          // Fallback: Always try app-scoped storage
          try {
            final appDir = await getApplicationDocumentsDirectory();
            final exportsDir = Directory('${appDir.path}/Exports');
            
            if (!await exportsDir.exists()) {
              await exportsDir.create(recursive: true);
            }
            
            final file = File('${exportsDir.path}/$fileName');
            await file.writeAsBytes(bytes);
            savePath = file.absolute.path;
            locationName = 'Exports folder (universal fallback)';
            savedSuccessfully = true;
            _logger.fine('✅ Saved to app-scoped Exports (universal fallback)');
          } catch (fallbackE) {
            _logger.warning('Universal fallback failed: $fallbackE');
          }
        }
      } else {
        // For iOS and other platforms, use Documents directory
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          final exportsDir = Directory('${documentsDir.path}/Exports');
          
          if (!await exportsDir.exists()) {
            await exportsDir.create(recursive: true);
          }
          
          final file = File('${exportsDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          savePath = file.absolute.path;
          locationName = 'Documents/Exports folder';
          savedSuccessfully = true;
          _logger.fine('✅ Saved to Documents/Exports for iOS');
        } catch (e) {
          _logger.warning('Documents directory failed: $e');
        }
      }
      
      // Method 3: Try app-specific directory (if other methods failed)
      if (!savedSuccessfully) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final file = File('${appDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          savePath = file.absolute.path;
          locationName = 'App Documents folder (fallback)';
          savedSuccessfully = true;
          _logger.fine('✅ Saved to App Documents (fallback)');
        } catch (e) {
          _logger.warning('App storage failed: $e');
        }
      }
      
      // Method 4: Try temp directory (last resort)
      if (!savedSuccessfully) {
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          savePath = file.absolute.path;
          locationName = 'Temp folder (emergency fallback)';
          savedSuccessfully = true;
          _logger.fine('✅ Saved to Temp folder (emergency)');
        } catch (e) {
          _logger.warning('Temp directory failed: $e');
        }
      }
      
      if (savedSuccessfully) {
        return {
          'success': true,
          'path': savePath,
          'location': locationName,
        };
      } else {
        return {
          'success': false,
          'error': 'Unable to save file. Please check permissions and storage space.',
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }



  Future<void> _showQuantityUpdateDialog(InventoryItem item) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate values for display
    final inventoryOfftake = (item.beg ?? 0) + (item.prev ?? 0) - item.end;
    final weeklyOrderOfftake = double.tryParse(_selectedBranch?.weeklyOrderOfftake?.toString() ?? '1') ?? 1;
    final weeklyOfftake = (item.sales ?? 0) / weeklyOrderOfftake;
    final weeklyReorderPoint = double.tryParse(_selectedBranch?.weeklyReorderPoint?.toString() ?? '0') ?? 0;
    final reorderPoint = weeklyOfftake * weeklyReorderPoint;
    final maintainingInventory = double.tryParse(_selectedBranch?.maintainingInventory ?? '0') ?? 0;
    final maintinvty = (item.sales ?? 0) * maintainingInventory;
    final TextEditingController prevDeliveryController = TextEditingController(text: item.prev?.toString() ?? '');
    final TextEditingController actualCountController = TextEditingController(text: item.end.toString());
    final TextEditingController actualOrderController = TextEditingController();
    final proposedOrder = max(0.0, maintinvty - item.end.toDouble());
    int calculatedSales = (item.prev ?? 0) - item.end;
    double weeklySales = calculatedSales / weeklyOrderOfftake;
    double reorderPt = weeklySales * weeklyReorderPoint;
    double maintInvty = calculatedSales * maintainingInventory;
    double proposedOrd = max(0.0, maintInvty - item.end.toDouble());
    bool showSubmitButton = false;

    // Helper function to format doubles to 2 decimal places if not whole
    String formatDouble(double value) {
      return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_selectedBranch?.name ?? 'Unknown Branch'} - ${_selectedBranch?.location ?? 'Unknown Location'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : Color(0xFF0651A4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SKU
                        Row(
                          children: [
                            Expanded(child: Text('SKU:', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(item.sku, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4))))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Row(
                          children: [
                            Expanded(child: Text('Description:', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(item.description, style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4))))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Brand
                        Row(
                          children: [
                            Expanded(child: Text('Brand:', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(item.brand ?? 'N/A', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4))))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Count (Quantity)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Count (Quantity):', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18)),
                                  if (item.lastUpdated != null) Text(
                                    DateFormat('MMM dd, yyyy').format(DateTime.parse(item.lastUpdated!)),
                                    style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(item.end.toString(), style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4))),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // prev delivery
                        Row(
                          children: [
                            Expanded(child: Text('prev delivery:', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(
                              child: TextField(
                                controller: prevDeliveryController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final prev = int.tryParse(value) ?? 0;
                                  final actual = int.tryParse(actualCountController.text) ?? item.end;
                                  setDialogState(() {
                                    calculatedSales = prev - actual;
                                    weeklySales = calculatedSales / weeklyOrderOfftake;
                                    reorderPt = weeklySales * weeklyReorderPoint;
                                    maintInvty = calculatedSales * maintainingInventory;
                                    proposedOrd = max(0.0, maintInvty - actual.toDouble());
                                  });
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // actual count
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('actual count:', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 12)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: TextField(
                                  controller: actualCountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final actual = int.tryParse(value) ?? item.end;
                                    final prev = int.tryParse(prevDeliveryController.text) ?? item.prev ?? 0;
                                    setDialogState(() {
                                      calculatedSales = prev - actual;
                                      weeklySales = calculatedSales / weeklyOrderOfftake;
                                      reorderPt = weeklySales * weeklyReorderPoint;
                                      maintInvty = calculatedSales * maintainingInventory;
                                      proposedOrd = max(0.0, maintInvty - actual.toDouble());
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // sales
                        Row(
                          children: [
                            Expanded(child: Text('Sales (${_selectedBranch?.weeklyOrderOfftake ?? 'N/A'} weeks):', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(calculatedSales.toString(), style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 16)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // weekly sales
                        Row(
                          children: [
                            Expanded(child: Text('weekly sales:', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(formatDouble(weeklySales), style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 16)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // re-order point
                        Row(
                          children: [
                            Expanded(child: Text('Reorder Pt. (${_selectedBranch?.weeklyReorderPoint ?? 'N/A'} weeks):', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(formatDouble(reorderPt), style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 16)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // main invty
                        Row(
                          children: [
                            Expanded(child: Text('Maint Invty (${_selectedBranch?.maintainingInventory ?? 'N/A'} x sales):', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(formatDouble(maintInvty), style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 16)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // proposed order
                        Row(
                          children: [
                            Expanded(child: Text('proposed order:', style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 18))),
                            Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text(formatDouble(proposedOrd), style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), fontSize: 16)))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDarkMode ? Colors.white70 : Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Update logic
                                  final newPrev = int.tryParse(prevDeliveryController.text) ?? item.prev ?? 0;
                                  final newEnd = int.tryParse(actualCountController.text) ?? item.end;
                                  final newSales = calculatedSales;
                                  // Update the item
                                  final updatedItem = InventoryItem(
                                    id: item.id,
                                    sku: item.sku,
                                    description: item.description,
                                    end: newEnd,
                                    location: item.location,
                                    brand: item.brand,
                                    dateAdded: item.dateAdded,
                                    lastUpdated: DateTime.now().toIso8601String(),
                                    branchId: item.branchId,
                                    beg: item.beg, // keep
                                    prev: newPrev == 0 ? null : newPrev,
                                    sales: newSales == 0 ? null : newSales,
                                  );
                                  try {
                                    await AppDatabase.instance.updateInventoryItem(updatedItem);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Updated successfully')),
                                    );
                                    Navigator.of(context).pop();
                                    _loadInventoryItems();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error updating: $e')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(
                                    0xFF0651A4,
                                  ).withValues(alpha: isDarkMode ? 0.5 : 0.3),
                                ),
                                child: const Text(
                                  'Update',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Actual Order Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : Color(0xFF0651A4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actual Order', style: TextStyle(color: isDarkMode ? Colors.white : Color(0xFF0651A4), fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 12),
                        _buildInputRow('actual order:', actualOrderController, (value) {
                          final orderQty = int.tryParse(value) ?? 0;
                          setDialogState(() {
                            showSubmitButton = orderQty > 0;
                          });
                        }),
                        if (showSubmitButton) Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final orderQty = int.tryParse(actualOrderController.text) ?? 0;
                                if (orderQty > 0) {
                                  final order = OrdersCompanion.insert(
                                    branchId: _selectedBranch!.id,
                                    location: item.location,
                                    brand: item.brand ?? '',
                                    itemId: item.id,
                                    quantity: orderQty,
                                    dateOrdered: DateTime.now().toIso8601String(),
                                    status: drift.Value('pending'),
                                    batchId: const drift.Value.absent(),
                                  );
                                  try {
                                    await AppDatabase.instance.into(AppDatabase.instance.orders).insert(order);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Order submitted successfully')),
                                    );
                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error submitting order: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Submit Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
);
  }

  Future<void> _showUpdateFormDialog(InventoryItem item) async {
    final TextEditingController begController = TextEditingController();
    final TextEditingController prevController = TextEditingController();
    final TextEditingController endingController = TextEditingController(
      text: item.end.toString(),
    );
    final TextEditingController salesController = TextEditingController();
    bool isLoading = false;
    int total = 0;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Update Quantity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3),
                        ),
                      ),
                      child: StatefulBuilder(
                        builder: (context, setTableState) {
                          return Column(
                            children: [
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(1),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller: begController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            int beg = int.tryParse(begController.text) ?? 0;
                                            int prev = int.tryParse(prevController.text) ?? 0;
                                            setTableState(() {
                                              total = beg + prev;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Beg.',
                                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller: prevController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            int beg = int.tryParse(begController.text) ?? 0;
                                            int prev = int.tryParse(prevController.text) ?? 0;
                                            setTableState(() {
                                              total = beg + prev;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Prev.',
                                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller: endingController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Ending',
                                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller: salesController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Sales',
                                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Total: $total',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: isDarkMode ? Colors.white70 : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isLoading = true;
                                    });

                                    // Validate that all fields are not empty
                                    if (begController.text.trim().isEmpty ||
                                        prevController.text.trim().isEmpty ||
                                        endingController.text.trim().isEmpty ||
                                        salesController.text.trim().isEmpty) {
                                      if (mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Error'),
                                              content: Text('All fields (Beginning, Previous, Ending, Sales) must be filled. Please enter 0 if no value.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    } else {
                                      final newBeg = int.tryParse(begController.text) ?? 0;
                                      final newPrev = int.tryParse(prevController.text) ?? 0;
                                      final newEnding = int.tryParse(endingController.text.trim());
                                      final newSales = int.tryParse(salesController.text) ?? 0;

                                      if (newEnding != null && newEnding >= 0) {
                                      // Calculate the values that should not be negative
                                      final inventoryOfftake = newBeg + newPrev - newEnding;
                                      final weeklyOrderOfftake = double.tryParse(_selectedBranch?.weeklyOrderOfftake?.toString() ?? '1') ?? 1;
                                      final weeklyOfftake = newSales / weeklyOrderOfftake;
                                      final weeklyReorderPoint = double.tryParse(_selectedBranch?.weeklyReorderPoint?.toString() ?? '0') ?? 0;
                                      final reorderPoint = weeklyOfftake * weeklyReorderPoint;
                                      final maintainingInventory = double.tryParse(_selectedBranch?.maintainingInventory ?? '0') ?? 0;
                                      final maintinvty = newSales * maintainingInventory;

                                      // Check if any calculated values would be negative
                                      if (inventoryOfftake < 0 || weeklyOfftake < 0 || reorderPoint < 0 || maintinvty < 0) {
                                        if (mounted) {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Error'),
                                                content: Text('Update would result in negative inventory values. Please adjust the inputs.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: Text('OK'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      } else {
                                        try {
                                          final updatedItem = InventoryItem(
                                            id: item.id,
                                            sku: item.sku,
                                            description: item.description,
                                            end: newEnding,
                                            location: item.location,
                                            brand: item.brand,
                                            dateAdded: item.dateAdded,
                                            lastUpdated: DateTime.now().toIso8601String(),
                                            branchId: item.branchId,
                                            beg: newBeg == 0 ? null : newBeg,
                                            prev: newPrev == 0 ? null : newPrev,
                                            sales: newSales == 0 ? null : newSales,
                                          );

await AppDatabase.instance
                                              .updateInventoryItem(updatedItem);

                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Quantity updated successfully!',
                                                ),
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                            Navigator.of(context).pop();
                                            _loadInventoryItems(); // Refresh the list
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error updating quantity: ${e.toString()}',
                                                ),
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Please enter a valid ending quantity',
                                              ),
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                  BorderRadius.circular(15),
                                              ),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                      }
 
                                      setDialogState(() {
                                        isLoading = false;
                                      });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF0651A4,
                              ).withValues(alpha: isDarkMode ? 0.5 : 0.3),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Update',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBranchSelectionView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : Color(0xFF0651A4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.location_on,
              size: 60,
              color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select a Branch',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Color(0xFF0651A4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please select a branch to view inventory items',
            style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_branches.isNotEmpty) ..._getBranchSelectionWidgets(),
          if (_branches.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'No branches available',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF1E1E1E), Color(0xFF2D2D2D), Color(0xFF3A3A3A)]
                : [Color(0xFF0651A4), Color(0xFF0A7BFF), Color(0xFF42A5F5)],
          ),
        ),
        child: Stack(
          children: [
            // Background bubbles
            Positioned(
              top: 100,
              left: 50,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              top: 200,
              right: 80,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              left: 100,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              right: 50,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_branchSelected) {
                              _resetBranchSelection();
                            } else if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _branchSelected
                                ? '${_selectedBranch?.name ?? 'Unknown Branch'} (${_selectedBranch?.location ?? 'Unknown Location'})'
                                : 'Warehouse Inventory',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850]!.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0651A4),
                              ),
                            )
                          : !_branchSelected
                          ? _buildBranchSelectionView()
                          : Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.inventory,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.showLowStockOnly ? 'Low Stock Items' : '${_selectedBranch?.name} Inventory',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Search Inventory',
                                      labelStyle: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                      ),
                                      hintText: 'Search by SKU or name',
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode ? Colors.grey[700] : Colors.white,
                                    ),
                                    onChanged: _filterItems,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: buildFilterWidget(
                                    filterOptions: const [
                                      DropdownMenuItem(
                                        value: 'name',
                                        child: Text('Name / Description'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'date',
                                        child: Text('Date Created'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'sku',
                                        child: Text('SKU'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'brand',
                                        child: Text('Brand'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'branch',
                                        child: Text('Branch'),
                                      ),
                                    ],
                                    onFilterApplied: (filterType, filterValue) {
                                      setState(() {
                                        _filteredItems = _inventoryItems.where((
                                          item,
                                        ) {
                                          switch (filterType) {
                                            case 'sku':
                                              return item.sku
                                                  .toLowerCase()
                                                  .contains(
                                                    filterValue.toLowerCase(),
                                                  );
                                            case 'name':
                                              return item.description
                                                  .toLowerCase()
                                                  .contains(
                                                    filterValue.toLowerCase(),
                                                  );
                                            case 'date':
final formattedDate = item.dateAdded.substring(0, 10); // Get YYYY-MM-DD part
                                              return formattedDate.contains(
                                                    filterValue,
                                                  ) ||
                                                  item.dateAdded.contains(filterValue);
                                            case 'brand':
                                              return (item.brand ?? '')
                                                  .toLowerCase()
                                                  .contains(
                                                    filterValue.toLowerCase(),
                                                  );
                                            case 'branch':
                                              return _selectedBranch?.name
                                                      .toLowerCase()
                                                      .contains(
                                                        filterValue
                                                            .toLowerCase(),
                                                      ) ??
                                                  false;
                                            default:
                                              return true;
                                          }
                                        }).toList();
                                      });
                                    },
                                    onReset: () {
                                      setState(() {
                                        _filteredItems = List.from(
                                          _inventoryItems,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _filteredItems.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No inventory items found',
                                          ),
                                        )
                                      : RefreshIndicator(
                                          onRefresh: _loadInventoryItems,
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            itemCount: _filteredItems.length,
                                            itemBuilder: (context, index) {
                                              final item =
                                                  _filteredItems[index];
                                              return Card(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12.0,
                                                ),
                                                elevation: 6,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                color: isDarkMode ? Colors.grey[800] : Colors.white,
                                                shadowColor: const Color(
                                                  0xFF0651A4,
                                                ).withValues(alpha: isDarkMode ? 0.5 : 0.2),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        const Color(
                                                          0xFF0651A4,
                                                        ).withValues(alpha: isDarkMode ? 0.3 : 0.1),
                                                    child: const Icon(
                                                      Icons.inventory,
                                                      color: Color(0xFF0651A4),
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      _showQuantityUpdateDialog(
                                                        item,
                                                      ),
                                                  title: Text(
                                                    item.description,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                                    ),
                                                  ),
                                                  subtitle: Text(
'SKU: ${item.sku} | Brand: ${item.brand}\nLast Updated: ${item.lastUpdated != null ? DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(item.lastUpdated!)) : 'Never'}',
                                                    style: TextStyle(
                                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                                    ),
                                                  ),
                                                  trailing: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: item.end <= (int.tryParse(_selectedBranch?.maintainingInventory ?? '10') ?? 10) - 1
                                                          ? Colors.red
                                                                .withValues(
                                                                  alpha: isDarkMode ? 0.3 : 0.1,
                                                                )
                                                          : Colors.green
                                                                .withValues(
                                                                  alpha: isDarkMode ? 0.3 : 0.1,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Qty: ${item.end}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: item.end <= (int.tryParse(_selectedBranch?.maintainingInventory ?? '10') ?? 10) - 1
                                                            ? Colors.red
                                                            : Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                  isThreeLine: false,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
floatingActionButton: _branchSelected && _inventoryItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isExporting ? null : _exportInventoryToFile,
              backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
              foregroundColor: Colors.white,
              elevation: 8,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'Exporting...' : 'Export to XLSX'),
            )
          : null,
    );
  }

@override
  void dispose() {
    super.dispose();
  }

  List<Widget> _getBranchSelectionWidgets() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    List<Branch> filteredBranches = _branches.where((branch) {
      return branch.name.toLowerCase().contains(
            _branchSearchQuery.toLowerCase(),
          ) ||
          branch.location.toLowerCase().contains(
            _branchSearchQuery.toLowerCase(),
          );
    }).toList();
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Search Branches',
            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
            hintText: 'Search by name or location',
            prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4), width: 2),
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[700] : Colors.white,
          ),
          onChanged: (value) {
            setState(() {
              _branchSearchQuery = value;
            });
          },
        ),
      ),
      if (_branchSearchQuery.isNotEmpty && filteredBranches.isNotEmpty)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredBranches.length,
            itemBuilder: (context, index) {
              final branch = filteredBranches[index];
              return ListTile(
                leading: Icon(Icons.business, color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                title: Text(
                  '${branch.name} (${branch.location})',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                ),
                onTap: () {
                  setState(() {
                    _selectedBranch = branch;
                    _branchSearchQuery = '';
                  });
                  _loadInventoryItems();
                },
              );
            },
          ),
        ),
      const SizedBox(height: 16),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButton<Branch>(
          value: _selectedBranch,
          isExpanded: true,
          hint: Text(
            'Select a branch',
            style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
          ),
          underline: Container(),
          icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
          items: _branches.map((Branch branch) {
            return DropdownMenuItem<Branch>(
              value: branch,
              child: Text(
                '${branch.name} (${branch.location})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                ),
              ),
            );
          }).toList(),
          onChanged: (Branch? newBranch) {
            if (newBranch != null) {
              setState(() {
                _selectedBranch = newBranch;
              });
              _loadInventoryItems();
            }
          },
        ),
      ),
    ];
  }
}
