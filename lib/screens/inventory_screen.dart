import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'add_inventory_item_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await DatabaseHelper.instance.getAllBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
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
              item.location.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
          if (_branches.isNotEmpty)
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
        title: const Text('Warehouse Inventory'),
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
                          hintText: 'Search by SKU, name, class, or location',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Branch: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Branch? newBranch) {
                                  if (newBranch != null && newBranch != _selectedBranch) {
                                    setState(() {
                                      _selectedBranch = newBranch;
                                    });
                                    _loadInventoryItems();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadInventoryItems,
                        child: _filteredItems.isEmpty
                            ? const Center(
                                child: Text('No inventory items found'),
                              )
                            : ListView.builder(
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'SKU: ${item.sku} | Class: ${item.itemClass}\nLocation: ${item.location}',
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Qty: ${item.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: item.quantity <= 10
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          ),
                                        ],
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
      floatingActionButton: _selectedBranch != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddInventoryItemScreen(
                      selectedBranch: _selectedBranch!,
                    ),
                  ),
                ).then((_) => _loadInventoryItems()); // Refresh after adding
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}