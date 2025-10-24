import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/widgets/filter_widget.dart';
import 'add_inventory_item_screen.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.initialBranch});

  final Branch? initialBranch;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> _filteredItems = [];
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  bool _isLoading = true;
  bool _branchSelected = false;
  String _searchQuery = '';
  String _branchSearchQuery = '';
  StreamSubscription<String>? _updateSubscription;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _updateSubscription = DatabaseHelper.instance.updateStream.listen((event) {
      if (event == 'master_item_updated' && _selectedBranch != null) {
        _loadInventoryItems();
      } else if (event == 'branch_updated') {
        _loadBranches();
      }
    });
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await DatabaseHelper.instance.getAllBranches();
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
      final items = await DatabaseHelper.instance.getInventoryItemsByBranch(
        _selectedBranch!.id!,
      );
      if (mounted) {
        setState(() {
          _inventoryItems = items;
          _filteredItems = items;
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  Future<void> _exportInventoryToFile() async {
    if (_selectedBranch == null || _inventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No inventory data to export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Try different storage locations for better compatibility
      Directory? directory;

      // Try external storage first (Android)
      try {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadDir = Directory('${directory.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          directory = downloadDir;
        }
      } catch (e) {
        // Fallback to application documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Unable to access storage directory');
      }

      final fileName = '${_selectedBranch!.name.replaceAll(' ', '_')}_inventory_${DateTime.now().toIso8601String().split('T')[0]}.csv';
      final file = File('${directory.path}/$fileName');

      // Create CSV header
      String csvContent = 'SKU,Description,Brand,Location,Quantity,Date Added\n';

      // Add inventory items
      for (var item in _inventoryItems) {
        final brand = item.brand ?? 'N/A';
        final dateAdded = '${item.dateAdded.year}-${item.dateAdded.month.toString().padLeft(2, '0')}-${item.dateAdded.day.toString().padLeft(2, '0')}';
        csvContent += '${item.sku},"${item.description}",$brand,${item.location},${item.end},$dateAdded\n';
      }

      await file.writeAsString(csvContent);

      final filePath = '${directory.path}/$fileName';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inventory exported successfully!\nFile: $fileName\nLocation: ${directory.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Show Path',
              textColor: Colors.white,
              onPressed: () async {
                // Show the file path in another snackbar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File location: $filePath\nUse your file manager to navigate to this path and open the CSV file.'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 15),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting inventory: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showQuantityUpdateDialog(InventoryItem item) async {
    final TextEditingController quantityController = TextEditingController(
      text: item.end.toString(),
    );
    bool isLoading = false;

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
                      color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Color(0xFF0651A4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SKU: ${item.sku}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Description: ${item.description}',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.branding_watermark,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Brand: ${item.brand}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Location: ${item.location}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Branch: ${_selectedBranch?.name ?? 'Unknown'}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Weekly Order Offtake: ${_selectedBranch?.weeklyOrderOfftake ?? 'N/A'}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reorder Point: ${_selectedBranch?.weeklyReorderPoint ?? 'N/A'}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Maintaining Inventory: ${_selectedBranch?.maintainingInventory ?? 'N/A'}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                              ),
                            ],
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
                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'New Quantity',
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                          hintText: 'Enter quantity',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.numbers,
                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                          ),
                        ),
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

                                    final newQuantity = int.tryParse(
                                      quantityController.text.trim(),
                                    );
                                    if (newQuantity != null &&
                                        newQuantity >= 0) {
                                      try {
                                        final updatedItem = InventoryItem(
                                          id: item.id,
                                          sku: item.sku,
                                          description: item.description,
                                          end: newQuantity,
                                          location: item.location,
                                          brand: item.brand,
                                          dateAdded: item.dateAdded,
                                          branchId: item.branchId,
                                        );

                                        await DatabaseHelper.instance
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
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Please enter a valid quantity',
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
                              ).withOpacity(isDarkMode ? 0.5 : 0.3),
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
              color: isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Color(0xFF0651A4).withOpacity(0.1),
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
                color: Colors.red.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                                ? '${_selectedBranch?.name} Inventory'
                                : 'Warehouse Inventory',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.3),
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
                                            '${_selectedBranch?.name} Inventory',
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
                                              final formattedDate =
                                                  '${item.dateAdded.year}-${item.dateAdded.month.toString().padLeft(2, '0')}-${item.dateAdded.day.toString().padLeft(2, '0')}';
                                              return formattedDate.contains(
                                                    filterValue,
                                                  ) ||
                                                  item.dateAdded
                                                      .toIso8601String()
                                                      .contains(filterValue);
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
                                                ).withOpacity(isDarkMode ? 0.5 : 0.2),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        const Color(
                                                          0xFF0651A4,
                                                        ).withOpacity(isDarkMode ? 0.3 : 0.1),
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
                                                    'SKU: ${item.sku} | Brand: ${item.brand}\nLast Updated: ${item.dateUpdated != null ? '${item.dateUpdated!.year}-${item.dateUpdated!.month.toString().padLeft(2, '0')}-${item.dateUpdated!.day.toString().padLeft(2, '0')} ${_formatTime(item.dateUpdated!)}' : 'Never'}',
                                                    style: TextStyle(
                                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  trailing: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: item.end <= 10
                                                          ? Colors.red
                                                                .withOpacity(
                                                                  isDarkMode ? 0.3 : 0.1,
                                                                )
                                                          : Colors.green
                                                                .withOpacity(
                                                                  isDarkMode ? 0.3 : 0.1,
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
                                                        color: item.end <= 10
                                                            ? Colors.red
                                                            : Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                  isThreeLine: true,
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
    );
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
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
            border: Border.all(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
          border: Border.all(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
