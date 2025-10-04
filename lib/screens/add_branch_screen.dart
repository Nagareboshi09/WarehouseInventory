import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/master_item.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemClassController = TextEditingController();
  final _itemLocationController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  bool _addingItem = false;
  final List<MasterItem> _masterItems = [];
  final List<int> _masterItemQuantities = [];

  void _addMasterItem() {
    if (_skuController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _itemClassController.text.trim().isEmpty ||
        _itemLocationController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all item fields including quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final masterItem = MasterItem(
      sku: _skuController.text.trim(),
      description: _descriptionController.text.trim(),
      itemClass: _itemClassController.text.trim(),
      location: _itemLocationController.text.trim(),
      branchId: 0, // Will be updated after branch is created
    );

    setState(() {
      _masterItems.add(masterItem);
      _masterItemQuantities.add(quantity);
      _skuController.clear();
      _descriptionController.clear();
      _itemClassController.clear();
      _itemLocationController.clear();
      _quantityController.clear();
      _addingItem = false;
    });
  }

  void _removeMasterItem(int index) {
    setState(() {
      _masterItems.removeAt(index);
    });
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
          'location': _locationController.text.trim(),
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
            'itemClass': item.itemClass,
            'location': item.location,
            'branchId': branchId,
          };
          await txn.insert('master_items', masterItemMap);

          // Insert into inventory_items
          final inventoryItemMap = {
            'sku': item.sku,
            'itemClass': item.itemClass,
            'description': item.description,
            'quantity': quantity,
            'location': item.location,
            'dateAdded': DateTime.now().toIso8601String(),
            'branchId': branchId,
          };
          await txn.insert('inventory_items', inventoryItemMap);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch, master items, and inventory added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding branch and items: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
    _locationController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _itemClassController.dispose();
    _itemLocationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Branch'),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
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
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Master Items Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Master Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(_addingItem ? Icons.remove : Icons.add),
                            onPressed: () {
                              setState(() {
                                _addingItem = !_addingItem;
                              });
                            },
                          ),
                        ],
                      ),
                      
                      if (_addingItem) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU *',
                            prefixIcon: Icon(Icons.qr_code),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _itemClassController,
                          decoration: const InputDecoration(
                            labelText: 'Item Class *',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _itemLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Location *',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity *',
                            prefixIcon: Icon(Icons.inventory_2),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _addMasterItem,
                          child: const Text('Add Item'),
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
                          return ListTile(
                            title: Text('${item.sku} - ${item.description}'),
                            subtitle: Text('${item.itemClass} - ${item.location} - Qty: ${_masterItemQuantities[index]}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeMasterItem(index),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBranch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Branch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}