import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/master_item.dart';
import 'package:warehouse_inventory/widgets/item_form_fields.dart';

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
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _brandController = TextEditingController();
  bool _isLoading = false;
  List<MasterItem> _masterItems = [];
  MasterItem? _selectedMasterItem;

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sku = _skuController.text.trim();
      final branchId = widget.selectedBranch.id!;

      // Check if SKU already exists in this branch
      final skuExists = await DatabaseHelper.instance.checkSkuExistsInBranch(sku, branchId);
      if (skuExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SKU "$sku" already exists in ${widget.selectedBranch.name}. Please use a different SKU.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final item = InventoryItem(
        sku: sku,
        description: _descriptionController.text.trim(),
        end: int.parse(_quantityController.text.trim()),
        location: _locationController.text.trim(),
        brand: _brandController.text.trim(),
        dateAdded: DateTime.now(),
        branchId: branchId,
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
        _locationController.text = item.location;
        _brandController.text = item.brand ?? '';
      } else {
        _skuController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _brandController.clear();
      }
    });
  }

  @override
  void dispose() {
    _skuController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Item to ${widget.selectedBranch.name}'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branch Information Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.store,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Branch',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.selectedBranch.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.selectedBranch.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Master Item Selection Section
              if (_masterItems.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Select from Master Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose an existing item or enter manually',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<MasterItem>(
                          initialValue: _selectedMasterItem,
                          decoration: InputDecoration(
                            labelText: 'Master Item',
                            prefixIcon: const Icon(Icons.inventory),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          menuMaxHeight: 300,
                          isExpanded: true,
                          items: _masterItems.map((MasterItem item) {
                            return DropdownMenuItem<MasterItem>(
                              value: item,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'SKU: ${item.sku}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 2),
                                    if (item.brand != null && item.brand!.isNotEmpty) ...[
                                      Flexible(
                                        child: Text(
                                          'Brand: ${item.brand}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Item Details Section
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Item Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ItemFormFields(
                        skuController: _skuController,
                        descriptionController: _descriptionController,
                        brandController: _brandController,
                        quantityController: _quantityController,
                        isReadonly: _selectedMasterItem != null,
                        skuValidator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter SKU';
                          }
                          return null;
                        },
                        descriptionValidator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                        brandValidator: (value) {
                          return null; // Brand is optional
                        },
                        quantityValidator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value.trim()) == null || int.parse(value.trim()) < 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                        quantityInputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location *',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        readOnly: _selectedMasterItem != null,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(
                  _isLoading ? 'Adding Item...' : 'Add Item to Inventory',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}