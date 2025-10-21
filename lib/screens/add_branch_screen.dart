import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/master_item.dart';
import 'package:warehouse_inventory/widgets/item_form_fields.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';

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
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  bool _addingItem = false;
  final List<MasterItem> _masterItems = [];
  final List<int> _masterItemQuantities = [];

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

    final masterItem = MasterItem(
      sku: _skuController.text.trim(),
      description: _descriptionController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      location: _branchLocationController.text.trim(),
      branchId: 0, // Will be updated after branch is created
    );

    setState(() {
      _masterItems.add(masterItem);
      _masterItemQuantities.add(quantity);
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
    });
  }

  Future<void> _importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final ext = filePath.split('.').last.toLowerCase();

        // Build a unified rows structure for both .xlsx and .csv
        List<List<dynamic>> rows = [];

        if (ext == 'csv') {
          // Try multiple encodings since CSV files can have different encodings
          String raw;
          try {
            raw = file.readAsStringSync(encoding: utf8);
          } catch (e) {
            // If UTF-8 fails, try Latin-1 (ISO-8859-1) which is common for CSV files
            try {
              raw = file.readAsStringSync(encoding: latin1);
            } catch (e2) {
              // If Latin-1 also fails, try Windows-1252
              try {
                final bytes = file.readAsBytesSync();
                raw = String.fromCharCodes(bytes);
              } catch (e3) {
                if (!mounted) return;
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
          final bytes = file.readAsBytesSync();
          final decoder = SpreadsheetDecoder.decodeBytes(bytes);
          final sheet = decoder.tables[decoder.tables.keys.first];
          if (sheet == null) {
            if (!mounted) return;
            _showSnackBar('No data found in the Excel file', Colors.red);
            return;
          }
          rows = sheet.rows;
        } else if (ext == 'xls') {
          if (!mounted) return;
          _showSnackBar('Excel .xls files are not supported. Please save your file as .xlsx or export as CSV and try again.', Colors.red);
          return;
        } else {
          _showSnackBar('Unsupported file type. Please select a .xlsx or .csv file', Colors.red);
          return;
        }

        // Read headers from first row
        if (rows.isEmpty || rows[0].isEmpty) {
          if (!mounted) return;
          _showSnackBar('Excel file must have headers in the first row', Colors.red);
          return;
        }

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

        // Debug: Show detected headers
        _logger.info('Detected headers: $headerMap');
        _logger.info('skuIndex: $skuIndex, descriptionIndex: $descriptionIndex, quantityIndex: $quantityIndex');

        if (skuIndex == null || descriptionIndex == null) {
          if (!mounted) return;
          _showSnackBar('Excel file must have "SKU" and "Description" columns. Found headers: ${headerMap.keys.join(", ")}', Colors.red);
          return;
        }

        List<MasterItem> importedItems = [];
        List<int> importedQuantities = [];

        for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
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

          _logger.info('Row $rowIndex - SKU: "$sku", Description: "$description", Qty: $qty (from "$qtyStr")');

          // Skip section headers like "Bronco" rows without SKU or empty description
          if (sku.isEmpty || description.isEmpty) {
            _logger.info('Skipping row $rowIndex - empty SKU or description');
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

          // Allow items with null or any numeric quantity (including 0)
          _logger.info('Adding item from row $rowIndex');

          final masterItem = MasterItem(
            sku: sku,
            description: description,
            brand: finalBrand,
            location: _branchLocationController.text.trim(),
            branchId: 0,
          );

          importedItems.add(masterItem);
          importedQuantities.add(qty ?? 0); // Use 0 as default for the list, but preserve null for DB
        }

        _logger.info('Total items processed: ${rows.length - 1}, valid items found: ${importedItems.length}');

        if (importedItems.isEmpty) {
          if (!mounted) return;
          _showSnackBar('No valid items found in the Excel file. Check that your file has SKU and Description columns with data.', Colors.orange);
          return;
        }

        setState(() {
          _masterItems.addAll(importedItems);
          _masterItemQuantities.addAll(importedQuantities);
        });

        _showSnackBar('Imported ${importedItems.length} items from Excel', Colors.green);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error importing Excel: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        // Insert the branch first
        final branchMap = {
          'name': _nameController.text.trim(),
          'location': _branchLocationController.text.trim(),
          'code': _codeController.text.trim(),
        };
        final branchId = await txn.insert('branches', branchMap);

        // Insert master items and inventory items for each
        for (var i = 0; i < _masterItems.length; i++) {
          var item = _masterItems[i];
          var quantity = _masterItemQuantities[i];

          // Insert into master_items
          final masterItemMap = {
            'sku': item.sku,
            'description': item.description,
            'brand': item.brand,
            'location': item.location,
            'branchId': branchId,
          };
          await txn.insert('master_items', masterItemMap);

          // Insert into inventory_items - handle null quantity
          final inventoryItemMap = {
            'sku': item.sku,
            'description': item.description,
            'brand': item.brand,
            'end': quantity, // Will be 0 if quantity was null during import
            'location': item.location,
            'dateAdded': DateTime.now().toIso8601String(),
            'branchId': branchId,
          };
          await txn.insert('inventory_items', inventoryItemMap);
        }
      });

      if (mounted) {
        _showSnackBar('Branch, master items, and inventory added successfully!', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error adding branch and items: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchLocationController.dispose();
    _codeController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    super.dispose();
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
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1),
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
                  color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.15),
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
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1),
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
                  color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.12),
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
                          color: isDarkMode ? Colors.grey[850]!.withOpacity(0.95) : Colors.white.withOpacity(0.95),
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
                                color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
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
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.code,
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Branch Name *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.store,
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a branch name';
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
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                              controller: _branchLocationController,
                              decoration: InputDecoration(
                                labelText: 'Weekly Order Off take: *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                              controller: _branchLocationController,
                              decoration: InputDecoration(
                                labelText: 'Weekly ReOrder Point: *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                              controller: _branchLocationController,
                              decoration: InputDecoration(
                                labelText: 'Maintaining Inventory: *',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Master Items Section
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850]!.withOpacity(0.95) : Colors.white.withOpacity(0.95),
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
                                  color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
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
                                        onPressed: _importFromExcel,
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
                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withOpacity(0.3),
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
                                    backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
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
                                      subtitle: Text('${item.brand != null && item.brand!.isNotEmpty ? '${item.brand} - ' : ''}${item.location} - Qty: ${_masterItemQuantities[index]}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeMasterItem(index),
                                      ),
                                    ),
                                  );
                                }).toList(),
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
        onPressed: _isLoading ? null : _saveBranch,
        backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
        label: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Add Branch'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}