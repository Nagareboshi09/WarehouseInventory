import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/master_item.dart';

class AddInventoryItemScreen extends StatefulWidget {
  final Branch selectedBranch;

  const AddInventoryItemScreen({
    super.key,
    required this.selectedBranch,
  });

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemClassController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  List<MasterItem> _masterItems = [];
  MasterItem? _selectedMasterItem;

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final item = InventoryItem(
        sku: _skuController.text.trim(),
        itemClass: _itemClassController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        location: _locationController.text.trim(),
        dateAdded: DateTime.now(),
        branchId: widget.selectedBranch.id!,
      );

      await DatabaseHelper.instance.createInventoryItem(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: ${e.toString()}'),
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
  void initState() {
    super.initState();
    _loadMasterItems();
  }

  Future<void> _loadMasterItems() async {
    try {
      final items = await DatabaseHelper.instance.getMasterItemsByBranch(widget.selectedBranch.id!);
      setState(() {
        _masterItems = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading master items: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMasterItemSelected(MasterItem? item) {
    setState(() {
      _selectedMasterItem = item;
      if (item != null) {
        _skuController.text = item.sku;
        _descriptionController.text = item.description;
        _itemClassController.text = item.itemClass;
        _locationController.text = item.location;
      } else {
        _skuController.clear();
        _descriptionController.clear();
        _itemClassController.clear();
        _locationController.clear();
      }
    });
  }

  @override
  void dispose() {
    _skuController.dispose();
    _descriptionController.dispose();
    _itemClassController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Item to ${widget.selectedBranch.name}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Branch:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.selectedBranch.name} - ${widget.selectedBranch.location}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Master Item Selection Dropdown
              if (_masterItems.isNotEmpty) ...[
                DropdownButtonFormField<MasterItem>(
                  value: _selectedMasterItem,
                  decoration: const InputDecoration(
                    labelText: 'Select Master Item',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  items: _masterItems.map((MasterItem item) {
                    return DropdownMenuItem<MasterItem>(
                      value: item,
                      child: Text('${item.sku} - ${item.description}'),
                    );
                  }).toList(),
                  onChanged: _onMasterItemSelected,
                  validator: (value) {
                    if (value == null && _masterItems.isNotEmpty) {
                      return 'Please select a master item or enter details manually';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU *',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
                readOnly: _selectedMasterItem != null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter SKU';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                readOnly: _selectedMasterItem != null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
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
                readOnly: _selectedMasterItem != null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item class';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value.trim()) == null || int.parse(value.trim()) < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                readOnly: _selectedMasterItem != null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}