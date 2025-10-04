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

  @override
  void initState() {
    super.initState();
    _loadMasterItems();
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
        final classController = TextEditingController(text: item.itemClass);
        final locationController = TextEditingController(text: item.location);

        return AlertDialog(
          title: const Text('Edit Master Item'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: classController, decoration: const InputDecoration(labelText: 'Item Class')),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final updated = MasterItem(
                  id: item.id,
                  sku: skuController.text.trim(),
                  description: descController.text.trim(),
                  itemClass: classController.text.trim(),
                  location: locationController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Master Items - \${widget.branch.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _masterItems.isEmpty
              ? const Center(child: Text('No master items found'))
              : ListView.builder(
                  itemCount: _masterItems.length,
                  itemBuilder: (context, index) {
                    final item = _masterItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(item.sku),
                        subtitle: Text('\${item.itemClass} • \${item.description}\nLocation: \${item.location}'),
                        isThreeLine: true,
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
    );
  }
}