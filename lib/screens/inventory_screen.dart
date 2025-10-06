import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/widgets/filter_widget.dart';
import 'add_inventory_item_screen.dart';
import 'dart:async';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

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
              final updatedBranch = branches.firstWhere((branch) => branch.id == _selectedBranch!.id);
              _selectedBranch = updatedBranch;
            } catch (e) {
              // Branch not found, might be deleted, so set to null
              _selectedBranch = null;
              _branchSelected = false;
              _inventoryItems = [];
              _filteredItems = [];
            }
          }
          _isLoading = false;
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
      final items = await DatabaseHelper.instance.getInventoryItemsByBranch(_selectedBranch!.id!);
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
              item.itemClass.toLowerCase().contains(query.toLowerCase()) ||
              (item.brand?.toLowerCase() ?? '').contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _showQuantityUpdateDialog(InventoryItem item) async {
    final TextEditingController quantityController = TextEditingController(text: item.quantity.toString());
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Quantity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SKU: ${item.sku}'),
                  const SizedBox(height: 8),
                  Text('Description: ${item.description}'),
                  const SizedBox(height: 8),
                  Text('Item Class: ${item.itemClass}'),
                  const SizedBox(height: 8),
                  Text('Brand: ${item.brand}'),
                  const SizedBox(height: 8),
                  Text('Location: ${item.location}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() {
                      isLoading = true;
                    });

                    final newQuantity = int.tryParse(quantityController.text.trim());
                    if (newQuantity != null && newQuantity >= 0) {
                      try {
                        final updatedItem = InventoryItem(
                          id: item.id,
                          sku: item.sku,
                          itemClass: item.itemClass,
                          description: item.description,
                          quantity: newQuantity,
                          location: item.location,
                          brand: item.brand,
                          dateAdded: item.dateAdded,
                          branchId: item.branchId,
                        );

                        await DatabaseHelper.instance.updateInventoryItem(updatedItem);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quantity updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(context).pop();
                          _loadInventoryItems(); // Refresh the list
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating quantity: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid quantity'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }

                    setDialogState(() {
                      isLoading = false;
                    });
                  },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBranchSelectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a Branch',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please select a branch to view inventory items',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_branches.isNotEmpty) ..._getBranchSelectionWidgets(),
          if (_branches.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'No branches available',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_branchSelected ? '${_selectedBranch?.name} Inventory' : 'Warehouse Inventory'),
        leading: _branchSelected
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _resetBranchSelection,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_branchSelected
              ? _buildBranchSelectionView()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Inventory',
                          hintText: 'Search by SKU, name, or class',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _filterItems('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                        ),
                        onChanged: _filterItems,
                      ),
                    ),
                    buildFilterWidget(
                      filterOptions: const [
                        DropdownMenuItem(value: 'name', child: Text('Name / Description')),
                        DropdownMenuItem(value: 'date', child: Text('Date Created')),
                        DropdownMenuItem(value: 'sku', child: Text('SKU')),
                        DropdownMenuItem(value: 'branch', child: Text('Branch')),
                      ],
                      onFilterApplied: (filterType, filterValue) {
                        setState(() {
                          _filteredItems = _inventoryItems.where((item) {
                            switch (filterType) {
                              case 'sku':
                                return item.sku.toLowerCase().contains(filterValue.toLowerCase());
                              case 'name':
                                return item.description.toLowerCase().contains(filterValue.toLowerCase());
                              case 'date':
                                final formattedDate = '${item.dateAdded.year}-${item.dateAdded.month.toString().padLeft(2, '0')}-${item.dateAdded.day.toString().padLeft(2, '0')}';
                                return formattedDate.contains(filterValue) || item.dateAdded.toIso8601String().contains(filterValue);
                              case 'branch':
                                return _selectedBranch?.name.toLowerCase().contains(filterValue.toLowerCase()) ?? false;
                              default:
                                return true;
                            }
                          }).toList();
                        });
                      },
                    ),
                    Expanded(
                      child: _filteredItems.isEmpty
                          ? const Center(child: Text('No inventory items found'))
                          : RefreshIndicator(
                              onRefresh: _loadInventoryItems,
                              child: ListView.builder(
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: ListTile(
                                      onTap: () => _showQuantityUpdateDialog(item),
                                      title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        'SKU: ${item.sku} | Class: ${item.itemClass} | Brand: ${item.brand}',
                                      ),
                                      trailing: Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: item.quantity <= 10 ? Colors.red : Colors.green,
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
      floatingActionButton: null,
    );
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }

  List<Widget> _getBranchSelectionWidgets() {
    List<Branch> filteredBranches = _branches.where((branch) {
      return branch.name.toLowerCase().contains(_branchSearchQuery.toLowerCase()) ||
          branch.location.toLowerCase().contains(_branchSearchQuery.toLowerCase());
    }).toList();
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Search Branches',
            hintText: 'Search by name or location',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: _branchSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _branchSearchQuery = '';
                      });
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
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
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredBranches.length,
            itemBuilder: (context, index) {
              final branch = filteredBranches[index];
              return ListTile(
                title: Text('${branch.name} (${branch.location})'),
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
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: DropdownButton<Branch>(
          value: _selectedBranch,
          isExpanded: true,
          hint: const Text('Select a branch'),
          underline: Container(),
          items: _branches.map((Branch branch) {
            return DropdownMenuItem<Branch>(
              value: branch,
              child: Text(
                '${branch.name} (${branch.location})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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