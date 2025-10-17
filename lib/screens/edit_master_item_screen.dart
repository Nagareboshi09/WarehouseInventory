import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/master_item.dart';
import 'package:warehouse_inventory/models/branch.dart';

class EditMasterItemScreen extends StatefulWidget {
  final Branch branch;

  const EditMasterItemScreen({super.key, required this.branch});

  @override
  State<EditMasterItemScreen> createState() => _EditMasterItemScreenState();
}

class _EditMasterItemScreenState extends State<EditMasterItemScreen> {
  bool _isLoading = true;
  List<MasterItem> _masterItems = [];
  String _searchQuery = '';
 final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMasterItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterItems() async {
    try {
      final items = await DatabaseHelper.instance.getMasterItemsByBranch(widget.branch.id!);
      if (mounted) {
        setState(() {
          _masterItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading master items: \$e')),
      );
    }
  }

  void _editItem(MasterItem item) {
    showDialog(
      context: context,
      builder: (context) {
        final skuController = TextEditingController(text: item.sku);
        final descController = TextEditingController(text: item.description);
        final locationController = TextEditingController(text: item.location);
        final brandController = TextEditingController(text: item.brand ?? '');

        return AlertDialog(
          title: const Text('Edit Master Item'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Item'),
                    content: const Text('Are you sure you want to delete this item?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  _deleteItem(item.id!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = MasterItem(
                  id: item.id,
                  sku: skuController.text.trim(),
                  description: descController.text.trim(),
                  location: locationController.text.trim(),
                  brand: brandController.text.trim(),
                  branchId: item.branchId,
                );
                await DatabaseHelper.instance.updateMasterItem(updated);
                Navigator.pop(context);
                _loadMasterItems();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteMasterItem(id);
    _loadMasterItems();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        final skuController = TextEditingController();
        final descController = TextEditingController();
        final brandController = TextEditingController();
        final locationController = TextEditingController(text: widget.branch.location);

        return AlertDialog(
          title: const Text('Add New Master Item'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newItem = MasterItem(
                  sku: skuController.text.trim(),
                  description: descController.text.trim(),
                  location: locationController.text.trim(),
                  brand: brandController.text.trim(),
                  branchId: widget.branch.id!,
                );
                await DatabaseHelper.instance.createMasterItem(newItem);
                Navigator.pop(context);
                _loadMasterItems();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<MasterItem> _getFilteredItems() {
    if (_searchQuery.isEmpty) {
      return _masterItems;
    }
    return _masterItems.where((item) {
      return item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (item.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Master Items - \${widget.branch.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                          child: Container(
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
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search items...',
                                hintStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
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
                              child: _getFilteredItems().isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Text(
                                          _searchQuery.isNotEmpty ? 'No items match your search' : 'No master items found',
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16.0),
                                      itemCount: _getFilteredItems().length,
                                      itemBuilder: (context, index) {
                                        final item = _getFilteredItems()[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          shadowColor: const Color(0xFF0651A4).withValues(alpha: isDarkMode ? 0.5 : 0.2),
                                          elevation: 4,
                                          child: ListTile(
                                            title: Text(
                                              item.sku,
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${item.description} • ${item.brand ?? 'No Brand'}',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                                  onPressed: () => _editItem(item),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                  onPressed: () => _deleteItem(item.id!),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
        child: const Icon(Icons.add),
      ),
    );
  }
}