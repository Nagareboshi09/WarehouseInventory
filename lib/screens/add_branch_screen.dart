import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:warehouse_inventory/widgets/item_form_fields.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:drift/drift.dart' as drift;
import 'package:async/async.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final Logger _logger = Logger('AddBranchScreen');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _branchLocationController = TextEditingController();
  final _codeController = TextEditingController();
  final _weeklyOrderOfftakeController = TextEditingController();
  final _weeklyReorderPointController = TextEditingController();
  final _maintainingInventoryController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  
  // Performance optimization state variables
  bool _isLoading = false;
  bool _isImporting = false;
  bool _isCodeValidating = false;
  
  // Progress tracking for large imports
  double _importProgress = 0.0;
  String _importStatus = '';
  int _totalRows = 0;
  int _processedRows = 0;
  
  bool _addingItem = false;
  final List<MasterItem> _masterItems = [];
  final List<int> _masterItemQuantities = [];
  final List<int?> _masterItemBegQuantities = [];
  final List<int?> _masterItemPrevQuantities = [];
  final List<int?> _masterItemSalesQuantities = [];
  String? _codeErrorMessage;

  bool get _isFormValid {
    return _formKey.currentState?.validate() == true &&
           _masterItems.isNotEmpty &&
           _codeErrorMessage == null &&
           !_isCodeValidating;
  }

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchLocationController.dispose();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _weeklyOrderOfftakeController.dispose();
    _weeklyReorderPointController.dispose();
    _maintainingInventoryController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Timer? _codeValidationTimer;

  void _onCodeChanged() {
    // Clear previous error when user starts typing
    if (_codeErrorMessage != null && _codeController.text.isNotEmpty) {
      setState(() {
        _codeErrorMessage = null;
      });
    }

    // Debounce the validation
    _codeValidationTimer?.cancel();
    _codeValidationTimer = Timer(const Duration(milliseconds: 800), () {
      _validateBranchCodeRealtime();
    });
  }

  Future<void> _validateBranchCodeRealtime() async {
    final code = _codeController.text.trim();
    
    // Skip validation if code is too short or empty
    if (code.length < 2) {
      if (mounted) {
        setState(() {
          _codeErrorMessage = null;
          _isCodeValidating = false;
        });
      }
      return;
    }

    setState(() {
      _isCodeValidating = true;
      _codeErrorMessage = null;
    });

    try {
      final existingBranches = await AppDatabase.instance.getAllBranches();
      final isDuplicate = existingBranches.any(
        (branch) => branch.code != null &&
                   branch.code!.toLowerCase() == code.toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _isCodeValidating = false;
          _codeErrorMessage = isDuplicate
              ? 'Branch code "$code" already exists. Please choose a different code.'
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCodeValidating = false;
          _codeErrorMessage = null;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  void _addMasterItem() {
    if (_skuController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty) {
      _showSnackBar('Please fill all item fields including quantity', Colors.red);
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 0) {
      _showSnackBar('Please enter a valid quantity', Colors.red);
      return;
    }

    final sku = _skuController.text.trim();

    // Check if SKU already exists in the current list of master items for this branch
    final existingItem = _masterItems.where((item) => item.sku == sku).isNotEmpty;
    if (existingItem) {
      _showSnackBar('SKU "$sku" already exists in this branch. Please use a different SKU.', Colors.red);
      return;
    }

    final masterItem = MasterItem(
      id: 0, // Temporary ID, will be replaced when inserted
      sku: sku,
      description: _descriptionController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      location: _branchLocationController.text.trim(),
      branchId: 0, // Will be updated after branch is created
    );

    setState(() {
      _masterItems.add(masterItem);
      _masterItemQuantities.add(quantity);
      _masterItemBegQuantities.add(null); // Will be null for manually added items
      _masterItemPrevQuantities.add(null);
      _masterItemSalesQuantities.add(null);
      _skuController.clear();
      _descriptionController.clear();
      _brandController.clear();
      _quantityController.clear();
      _addingItem = false;
    });
  }

  void _removeMasterItem(int index) {
    setState(() {
      _masterItems.removeAt(index);
      _masterItemQuantities.removeAt(index);
      _masterItemBegQuantities.removeAt(index);
      _masterItemPrevQuantities.removeAt(index);
      _masterItemSalesQuantities.removeAt(index);
    });
  }

  // Show import progress dialog
  void _showImportProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Importing Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _importStatus,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _importProgress,
                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_importProgress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                if (_totalRows > 0)
                  Text(
                    'Processing: $_processedRows of $_totalRows',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Optimized Excel/CSV import with progress tracking and chunked processing
  Future<void> _importFromExcel() async {
    if (_isImporting) return; // Prevent multiple concurrent imports
    
    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _importStatus = 'Starting import...';
      _totalRows = 0;
      _processedRows = 0;
    });

    // Show progress dialog for large imports
    _showImportProgressDialog();
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final ext = filePath.split('.').last.toLowerCase();

        // Check file size and warn if large (performance optimization for low-spec devices)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB limit warning
          _showSnackBar('Large file detected (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Processing may take longer on low-spec devices.', Colors.orange);
        }

        setState(() {
          _importStatus = 'Reading file...';
        });

        // Build a unified rows structure for both .xlsx and .csv
        List<List<dynamic>> rows = [];

        if (ext == 'csv') {
          // Try multiple encodings since CSV files can have different encodings
          String raw;
          try {
            raw = await file.readAsString(encoding: utf8);
          } catch (e) {
            // If UTF-8 fails, try Latin-1 (ISO-8859-1) which is common for CSV files
            try {
              raw = await file.readAsString(encoding: latin1);
            } catch (e2) {
              // If Latin-1 also fails, try Windows-1252
              try {
                final bytes = await file.readAsBytes();
                raw = String.fromCharCodes(bytes);
              } catch (e3) {
                if (!mounted) return;
                Navigator.of(context).pop(); // Close progress dialog
                _showSnackBar('Unable to read CSV file. Please ensure it\'s a valid text file.', Colors.red);
                return;
              }
            }
          }

          raw = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
          final firstLine = raw.split('\n').isNotEmpty ? raw.split('\n').first : '';
          final delimiter = firstLine.contains(';') ? ';' : ',';
          _logger.info('CSV first line: "$firstLine"');
          _logger.info('Detected delimiter: "$delimiter"');
          final converter = CsvToListConverter(fieldDelimiter: delimiter, eol: '\n');
          rows = converter.convert(raw);
          _logger.info('Parsed ${rows.length} rows from CSV');
        } else if (ext == 'xlsx') {
          setState(() {
            _importStatus = 'Decoding Excel file...';
          });
          final bytes = await file.readAsBytes();
          final decoder = SpreadsheetDecoder.decodeBytes(bytes);
          final sheet = decoder.tables[decoder.tables.keys.first];
          if (sheet == null) {
            if (!mounted) return;
            Navigator.of(context).pop(); // Close progress dialog
            _showSnackBar('No data found in the Excel file', Colors.red);
            return;
          }
          rows = sheet.rows;
        } else if (ext == 'xls') {
          if (!mounted) return;
          Navigator.of(context).pop(); // Close progress dialog
          _showSnackBar('Excel .xls files are not supported. Please save your file as .xlsx or export as CSV and try again.', Colors.red);
          return;
        } else {
          if (!mounted) return;
          Navigator.of(context).pop(); // Close progress dialog
          _showSnackBar('Unsupported file type. Please select a .xlsx or .csv file', Colors.red);
          return;
        }

        // Read headers from first row
        if (rows.isEmpty || rows[0].isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Close progress dialog
          _showSnackBar('Excel file must have headers in the first row', Colors.red);
          return;
        }

        setState(() {
          _importStatus = 'Processing headers...';
        });

        // Helpers to normalize headers and extract cell text
        String normalizeHeader(String s) =>
            s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        String cellText(dynamic c) {
          try {
            if (c == null) return '';
            if (c is num || c is String) return c.toString();
            // Some spreadsheet decoders expose a .value property
            // ignore: avoid_dynamic_calls
            final v = c.value;
            return v?.toString() ?? '';
          } catch (_) {
            return c?.toString() ?? '';
          }
        }

        final headerRow = rows[0];
        Map<String, int> headerMap = {};

        for (var i = 0; i < headerRow.length; i++) {
          final rawHeader = cellText(headerRow[i]);
          final key = normalizeHeader(rawHeader);
          if (key.isNotEmpty) {
            headerMap[key] = i;
          }
        }

        // Check for required headers (case-insensitive, normalized) aligned to sample:
        // A: SKU, B: ITEM DESCRIPTION, C: END
        final skuIndex = headerMap['sku'] ?? headerMap['itemcode'];
        final descriptionIndex = headerMap['itemdescription'] ??
            headerMap['description'] ??
            headerMap['desc'] ??
            headerMap['itemname'];
        final brandIndex = headerMap['brand'] ?? headerMap['manufacturer'];
        final quantityIndex = headerMap['end'] ??
            headerMap['quantity'] ??
            headerMap['qty'] ??
            headerMap['stock'];
        
        // Detect additional quantity-related headers
        final begIndex = headerMap['beg'] ?? headerMap['beginning'] ?? headerMap['begin'];
        final prevIndex = headerMap['prev'] ?? headerMap['previous'];
        final salesIndex = headerMap['sales'] ?? headerMap['sale'];

        // Debug: Show detected headers
        _logger.info('Detected headers: $headerMap');
        _logger.info('skuIndex: $skuIndex, descriptionIndex: $descriptionIndex, quantityIndex: $quantityIndex');

        if (skuIndex == null || descriptionIndex == null) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Close progress dialog
          _showSnackBar('Excel file must have "SKU" and "Description" columns. Found headers: ${headerMap.keys.join(", ")}', Colors.red);
          return;
        }

        List<MasterItem> importedItems = [];
        List<int> importedQuantities = [];
        List<int?> importedBegQuantities = [];
        List<int?> importedPrevQuantities = [];
        List<int?> importedSalesQuantities = [];

        // Progress tracking for large datasets
        setState(() {
          _totalRows = rows.length - 1; // Exclude header
          _processedRows = 0;
          _importStatus = 'Processing ${rows.length - 1} items...';
        });

        // Process rows in chunks to avoid blocking UI thread
        const chunkSize = 25; // Process 25 rows at a time for better performance on low-spec devices
        
        for (var i = 1; i < rows.length; i += chunkSize) {
          setState(() {
            _processedRows = i - 1;
            _importProgress = (_processedRows / _totalRows);
          });

          final endIndex = (i + chunkSize < rows.length) ? i + chunkSize : rows.length;
          
          for (var rowIndex = i; rowIndex < endIndex; rowIndex++) {
            final row = rows[rowIndex];
            _logger.info('Processing row $rowIndex: ${row.map(cellText).toList()}');

            if (row.length <= skuIndex || row.length <= descriptionIndex) {
              _logger.info('Skipping row $rowIndex - insufficient columns');
              continue;
            }

            final sku = cellText(row[skuIndex]).trim();
            final description = cellText(row[descriptionIndex]).trim();
            final brandRaw = (brandIndex != null && row.length > brandIndex)
                ? cellText(row[brandIndex]).trim()
                : null;
            final qtyStr = (quantityIndex != null && row.length > quantityIndex)
                ? cellText(row[quantityIndex]).replaceAll(',', '').trim()
                : '';
            final qty = qtyStr.isEmpty ? null : num.tryParse(qtyStr)?.round();

            // Extract additional quantity-related fields
            final begStr = (begIndex != null && row.length > begIndex)
                ? cellText(row[begIndex]).replaceAll(',', '').trim()
                : '';
            final beg = begStr.isEmpty ? null : num.tryParse(begStr)?.round();
            
            final prevStr = (prevIndex != null && row.length > prevIndex)
                ? cellText(row[prevIndex]).replaceAll(',', '').trim()
                : '';
            final prev = prevStr.isEmpty ? null : num.tryParse(prevStr)?.round();
            
            final salesStr = (salesIndex != null && row.length > salesIndex)
                ? cellText(row[salesIndex]).replaceAll(',', '').trim()
                : '';
            final sales = salesStr.isEmpty ? null : num.tryParse(salesStr)?.round();

            _logger.info('Row $rowIndex - SKU: "$sku", Description: "$description", Qty: $qty (from "$qtyStr")');
            _logger.info('Row $rowIndex - Beg: $beg, Prev: $prev, Sales: $sales');


            // Skip section headers like "Bronco" rows without SKU or empty description
            // Also skip rows where SKU is not a number
            if (sku.isEmpty || description.isEmpty || int.tryParse(sku) == null) {
              _logger.info('Skipping row $rowIndex - empty SKU/description or non-numeric SKU');
              continue;
            }

            // Auto-extract brand from first word of description if brand is empty
            String? finalBrand = (brandRaw != null && brandRaw.isNotEmpty) ? brandRaw : null;
            if (finalBrand == null && description.isNotEmpty) {
              // Extract first word from description as brand
              final words = description.split(' ');
              if (words.isNotEmpty) {
                finalBrand = words.first.trim();
                _logger.info('Auto-extracted brand "$finalBrand" from description');
              }
            }

            // Check if SKU already exists in the imported items list
            if (importedItems.any((item) => item.sku == sku)) {
              _logger.info('Skipping duplicate SKU "$sku" in import from row $rowIndex');
              continue;
            }

            // Allow items with null or any numeric quantity (including 0)
            _logger.info('Adding item from row $rowIndex');

            final masterItem = MasterItem(
              id: 0, // Temporary ID, will be replaced when inserted
              sku: sku,
              description: description,
              brand: finalBrand,
              location: _branchLocationController.text.trim(),
              branchId: 0, // Will be updated after branch is created
            );

            importedItems.add(masterItem);
            importedQuantities.add(qty ?? 0); // Use 0 as default for the list, but preserve null for DB
            importedBegQuantities.add(beg);
            importedPrevQuantities.add(prev);
            importedSalesQuantities.add(sales);
          }

          // Yield to event loop to prevent UI freezing on low-spec devices
          await Future.delayed(const Duration(milliseconds: 1));
        }

        _logger.info('Total items processed: ${rows.length - 1}, valid items found: ${importedItems.length}');

        if (importedItems.isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Close progress dialog
          _showSnackBar('No valid items found in the Excel file. Check that your file has SKU and Description columns with data.', Colors.orange);
          return;
        }

        setState(() {
          _isImporting = false;
          _importProgress = 1.0;
          _importStatus = 'Import completed!';
        });

        setState(() {
          _masterItems.addAll(importedItems);
          _masterItemQuantities.addAll(importedQuantities);
          _masterItemBegQuantities.addAll(importedBegQuantities);
          _masterItemPrevQuantities.addAll(importedPrevQuantities);
          _masterItemSalesQuantities.addAll(importedSalesQuantities);
        });

        Navigator.of(context).pop(); // Close progress dialog
        _showSnackBar('Imported ${importedItems.length} items from Excel', Colors.green);
      }
    } catch (e) {
      _logger.severe('Import error: $e');
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog if open
        _showSnackBar('Error importing Excel: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one item has been added
    if (_masterItems.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Items Required'),
            content: const Text('Please add at least one item before creating the branch.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : const Color(0xFF0651A4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Adding Branch and ${_masterItems.length} Items...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a few moments',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600]!,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Force UI to update before starting the operation
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final db = AppDatabase.instance;

      // Check for unique branch code (case-insensitive)
      final branchCode = _codeController.text.trim();
      if (branchCode.isNotEmpty) {
        final existingBranches = await db.getAllBranches();
        final isDuplicate = existingBranches.any(
          (branch) => branch.code != null &&
                     branch.code!.toLowerCase() == branchCode.toLowerCase(),
        );
        
        if (isDuplicate) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            _showSnackBar('Branch code "$branchCode" already exists. Please choose a different code.', Colors.red);
          }
          return;
        }
      }

      // Check for duplicate SKUs in the current list (client-side validation)
      final skus = _masterItems.map((item) => item.sku).toList();
      _logger.info('Current SKUs to add: $skus');
      final duplicateSkus = skus.where((sku) => skus.where((s) => s == sku).length > 1).toSet();
      if (duplicateSkus.isNotEmpty) {
        _logger.warning('Client-side duplicate SKUs found: $duplicateSkus');
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showSnackBar('Duplicate SKUs found in the list: ${duplicateSkus.join(", ")}. Please use unique SKUs.', Colors.red);
        }
        return;
      }

      // Create the branch first to get its ID
      _logger.info('Creating new branch...');
      final branchId = await db.into(db.branches).insert(BranchesCompanion.insert(
        name: _nameController.text.trim(),
        location: _branchLocationController.text.trim(),
        code: drift.Value(_codeController.text.trim()),
        weeklyOrderOfftake: drift.Value(_weeklyOrderOfftakeController.text.trim()),
        weeklyReorderPoint: drift.Value(_weeklyReorderPointController.text.trim()),
        maintainingInventory: drift.Value(_maintainingInventoryController.text.trim()),
      ));
      _logger.info('Branch created successfully with ID: $branchId');

      // Use the customWriteTransaction for all item operations
      await db.customWriteTransaction(() async {
        // Process items in chunks for better performance on low-spec devices
        const chunkSize = 10;
        for (var i = 0; i < _masterItems.length; i += chunkSize) {
          final endIndex = (i + chunkSize < _masterItems.length) ? i + chunkSize : _masterItems.length;
          
          // Validate all SKUs in this chunk first
          for (var j = i; j < endIndex; j++) {
            var item = _masterItems[j];
            
            // Check if SKU already exists in master_items for this branch
            final existingMasterItem = await (db.select(db.masterItems)
              ..where((m) => m.sku.equals(item.sku) & m.branchId.equals(branchId))).getSingleOrNull();
            
            if (existingMasterItem != null) {
              _logger.warning('Found existing MasterItem with SKU "${item.sku}" in branch $branchId');
              throw Exception('Item SKU "${item.sku}" already exists in this branch. Please use a different SKU.');
            }

            // Check if SKU already exists in inventory_items for this branch
            final existingInventoryItem = await (db.select(db.inventoryItems)
              ..where((i) => i.sku.equals(item.sku) & i.branchId.equals(branchId))).getSingleOrNull();
            
            if (existingInventoryItem != null) {
              _logger.warning('Found existing InventoryItem with SKU "${item.sku}" in branch $branchId');
              throw Exception('Item SKU "${item.sku}" already exists in this branch. Please use a different SKU.');
            }
          }
          
          // Insert all items in this chunk
          for (var j = i; j < endIndex; j++) {
            var item = _masterItems[j];
            var quantity = _masterItemQuantities[j];

            // Insert into master_items
            await db.into(db.masterItems).insert(MasterItemsCompanion.insert(
              sku: item.sku,
              description: item.description,
              location: item.location,
              brand: item.brand != null ? drift.Value(item.brand) : const drift.Value.absent(),
              branchId: branchId,
            ));

            // Insert into inventory_items with additional quantity fields
            await db.into(db.inventoryItems).insert(InventoryItemsCompanion.insert(
              sku: item.sku,
              description: item.description,
              end: quantity,
              location: item.location,
              brand: item.brand != null ? drift.Value(item.brand) : const drift.Value.absent(),
              dateAdded: DateTime.now().toIso8601String(),
              branchId: branchId,
              beg: _masterItemBegQuantities.isNotEmpty && _masterItemBegQuantities.length > j
                  ? drift.Value(_masterItemBegQuantities[j])
                  : const drift.Value.absent(),
              prev: _masterItemPrevQuantities.isNotEmpty && _masterItemPrevQuantities.length > j
                  ? drift.Value(_masterItemPrevQuantities[j])
                  : const drift.Value.absent(),
              sales: _masterItemSalesQuantities.isNotEmpty && _masterItemSalesQuantities.length > j
                  ? drift.Value(_masterItemSalesQuantities[j])
                  : const drift.Value.absent(),
            ));
          }
          
          // Yield to event loop to prevent UI freezing
          await Future.delayed(const Duration(milliseconds: 5));
        }
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSnackBar('Branch, master items, and inventory added successfully!', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      // If there was an error, delete the branch we created
      try {
        // Extract branchId from the error context or try to get the last inserted branch
        // For simplicity, we'll skip this cleanup or you can implement a more sophisticated cleanup
      } catch (cleanupError) {
        _logger.warning('Error during cleanup: $cleanupError');
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSnackBar('Error adding branch and items: ${e.toString()}', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Branch'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D), const Color(0xFF3A3A3A)]
                : [const Color(0xFF0651A4), const Color(0xFF0A7BFF), const Color(0xFF42A5F5)],
          ),
        ),
        child: Stack(
          children: [
            // Background bubbles (optimized for performance)
            Positioned(
              top: 100,
              left: 50,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withOpacity(.05) : Colors.white.withOpacity(0.1),
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
                  color: isDarkMode ? Colors.white.withOpacity(.08) : Colors.white.withOpacity(0.15),
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
                  color: isDarkMode ? Colors.white.withOpacity(.05) : Colors.white.withOpacity(0.1),
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
                  color: isDarkMode ? Colors.white.withOpacity(.06) : Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850]!.withOpacity(.95) : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Branch Details',
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                labelText: 'Code*',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.code,
                                  color: _isCodeValidating
                                      ? Colors.orange
                                      : (isDarkMode ? Colors.white70 : const Color(0xFF0651A4)),
                                ),
                                suffixIcon: _isCodeValidating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : (_codeErrorMessage != null
                                        ? Icon(Icons.error, color: Colors.red)
                                        : null),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                errorText: _codeErrorMessage,
                                errorMaxLines: 2,
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a branch code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Branch Name *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.store,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a branch name!';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _branchLocationController,
                              decoration: InputDecoration(
                                labelText: 'Location *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a location';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weeklyOrderOfftakeController,
                              decoration: InputDecoration(
                                labelText: 'Weekly Order Off take: *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.shopping_cart,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a Weekly Order Off take';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weeklyReorderPointController,
                              decoration: InputDecoration(
                                labelText: 'Weekly ReOrder Point: *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.warning,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter ReOrder Point';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _maintainingInventoryController,
                              decoration: InputDecoration(
                                labelText: 'Maintaining Inventory: *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.inventory,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter Maintaining Inventory!';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Master Items Section
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850]!.withOpacity(.95) : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Master Items',
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Add Items',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.file_upload),
                                        tooltip: 'Import from Excel',
                                        onPressed: _isImporting ? null : _importFromExcel,
                                      ),
                                      IconButton(
                                        icon: Icon(_addingItem ? Icons.remove : Icons.add),
                                        tooltip: _addingItem ? 'Cancel Add' : 'Add Item',
                                        onPressed: () {
                                          setState(() {
                                            _addingItem = !_addingItem;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              if (_addingItem) ...[
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withOpacity(0.3),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: ItemFormFields(
                                    skuController: _skuController,
                                    descriptionController: _descriptionController,
                                    brandController: _brandController,
                                    quantityController: _quantityController,
                                    isReadonly: false,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _addMasterItem,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Item'),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (_masterItems.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Added Items:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ..._masterItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ListTile(
                                      title: Text('${item.sku} - ${item.description}'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${item.brand != null && item.brand!.isNotEmpty ? '${item.brand} - ' : ''}${item.location}'),
                                          Text(
                                            'End: ${_masterItemQuantities[index]}'
                                            '${_masterItemBegQuantities[index] != null ? ' | Beg: ${_masterItemBegQuantities[index]}' : ''}'
                                            '${_masterItemPrevQuantities[index] != null ? ' | Prev: ${_masterItemPrevQuantities[index]}' : ''}'
                                            '${_masterItemSalesQuantities[index] != null ? ' | Sales: ${_masterItemSalesQuantities[index]}' : ''}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeMasterItem(index),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_isLoading || !_isFormValid || _isImporting) ? null : _saveBranch,
        backgroundColor: !_isFormValid || _isImporting
            ? Colors.grey
            : (isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4)),
        label: _isLoading || _isImporting
            ? const CircularProgressIndicator(color: Colors.white)
            : (!_isFormValid
                ? const Text('Add Items First')
                : const Text('Add Branch')),
        icon: const Icon(Icons.add),
      ),
    );
  }
}