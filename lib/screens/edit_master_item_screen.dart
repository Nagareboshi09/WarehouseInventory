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
  TextEditingController _searchController = TextEditingController();

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Master Items - \${widget.branch.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _getFilteredItems().isEmpty
                      ? Center(child: Text(_searchQuery.isNotEmpty ? 'No items match your search' : 'No master items found'))
                      : ListView.builder(
                          itemCount: _getFilteredItems().length,
                          itemBuilder: (context, index) {
                            final item = _getFilteredItems()[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(item.sku),
                                subtitle: Text('${item.description} • ${item.brand ?? 'No Brand'}'),
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
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}