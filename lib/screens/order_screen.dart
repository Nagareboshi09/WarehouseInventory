import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/master_item.dart';
import 'package:warehouse_inventory/models/order.dart';
import 'package:warehouse_inventory/providers/order_provider.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  List<Branch> _branches = [];
  List<MasterItem> _masterItems = [];
  Branch? _selectedBranch;
  MasterItem? _selectedItem;
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final branches = await DatabaseHelper.instance.getAllBranches();
      final masterItems = await DatabaseHelper.instance.getAllMasterItems();
      setState(() {
        _branches = branches;
        _masterItems = masterItems;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Create order object
    final order = Order(
      branchId: _selectedBranch!.id!,
      location: _locationController.text.trim(),
      brand: _selectedBrand!,
      itemId: _selectedItem!.id!,
      quantity: int.parse(_quantityController.text.trim()),
      dateOrdered: DateTime.now(),
    );

    // Add order to provider
    context.read<OrderProvider>().addOrder(order);

    // Simulate order submission
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset form
      _formKey.currentState!.reset();
      _locationController.clear();
      _quantityController.clear();
      setState(() {
        _selectedBranch = null;
        _selectedItem = null;
        _selectedBrand = null;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<String> get _availableBrands {
    return _masterItems
        .where((item) => item.brand != null && item.brand!.isNotEmpty)
        .map((item) => item.brand!)
        .toSet()
        .toList();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
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
                          Icon(Icons.shopping_cart, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Branch Dropdown
                      DropdownButtonFormField<Branch>(
                        value: _selectedBranch,
                        decoration: const InputDecoration(
                          labelText: 'Branch *',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                        menuMaxHeight: 200,
                        items: _branches.map((Branch branch) {
                          return DropdownMenuItem<Branch>(
                            value: branch,
                            child: Text(branch.name),
                          );
                        }).toList(),
                        onChanged: (Branch? value) {
                          setState(() {
                            _selectedBranch = value;
                            _locationController.text = value?.location ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a branch';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Location TextField
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Brand Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBrand,
                        decoration: const InputDecoration(
                          labelText: 'Brand *',
                          prefixIcon: Icon(Icons.branding_watermark),
                          border: OutlineInputBorder(),
                        ),
                        menuMaxHeight: 200,
                        items: _availableBrands.map((String brand) {
                          return DropdownMenuItem<String>(
                            value: brand,
                            child: Text(brand),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedBrand = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a brand';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Item Dropdown
                      DropdownButtonFormField<MasterItem>(
                        value: _selectedItem,
                        decoration: const InputDecoration(
                          labelText: 'Item *',
                          prefixIcon: Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                        ),
                        menuMaxHeight: 200,
                        items: _masterItems.map((MasterItem item) {
                          return DropdownMenuItem<MasterItem>(
                            value: item,
                            child: Text('${item.sku} - ${item.description}'),
                          );
                        }).toList(),
                        onChanged: (MasterItem? value) {
                          setState(() {
                            _selectedItem = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an item';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Quantity TextField
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter quantity';
                          }
                          final quantity = int.tryParse(value.trim());
                          if (quantity == null || quantity <= 0) {
                            return 'Please enter a valid quantity greater than 0';
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
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade600,
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
                    : const Icon(Icons.send),
                label: Text(
                  _isLoading ? 'Submitting...' : 'Submit Order',
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