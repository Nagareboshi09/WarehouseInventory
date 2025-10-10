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
  bool _isLoading = false;
  List<Branch> _branches = [];
  List<MasterItem> _masterItems = [];
  Branch? _selectedBranch;
  Map<int, TextEditingController> _quantityControllers = {};
  Map<int, int> _orderQuantities = {};
  String _searchQuery = '';
  List<MasterItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final branches = await DatabaseHelper.instance.getAllBranches();
      setState(() {
        _branches = branches;
      });
      if (_selectedBranch != null) {
        await _loadMasterItems();
      }
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

  Future<void> _loadMasterItems() async {
    if (_selectedBranch == null) return;
    try {
      final masterItems = await DatabaseHelper.instance.getMasterItemsByBranch(
        _selectedBranch!.id!,
      );
      setState(() {
        _masterItems = masterItems;
        _filteredItems = masterItems;
        // Initialize controllers for each item
        _quantityControllers.clear();
        _orderQuantities.clear();
        for (var item in masterItems) {
          _quantityControllers[item.id!] = TextEditingController();
          _orderQuantities[item.id!] = 0;
        }
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

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _masterItems;
      } else {
        _filteredItems = _masterItems.where((item) {
          return item.sku.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              (item.brand?.toLowerCase() ?? '').contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one item has quantity > 0
    bool hasOrders = _orderQuantities.values.any((qty) => qty > 0);
    if (!hasOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity for at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Generate a unique batch ID for this order session
    final batchId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create orders for each item with quantity > 0
    List<Order> orders = [];
    for (var item in _masterItems) {
      int quantity = _orderQuantities[item.id!] ?? 0;
      if (quantity > 0) {
        final order = Order(
          branchId: _selectedBranch!.id!,
          location: _locationController.text.trim(),
          brand: item.brand ?? '',
          itemId: item.id!,
          quantity: quantity,
          dateOrdered: DateTime.now(),
          batchId: batchId,
        );
        orders.add(order);
      }
    }

    // Add orders to provider
    for (var order in orders) {
      context.read<OrderProvider>().addOrder(order);
    }

    // Simulate order submission
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${orders.length} order(s) submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset form
      _formKey.currentState!.reset();
      _locationController.clear();
      // Clear quantities
      for (var controller in _quantityControllers.values) {
        controller.clear();
      }
      setState(() {
        _orderQuantities.clear();
        for (var item in _masterItems) {
          _orderQuantities[item.id!] = 0;
        }
        _searchQuery = '';
        _filteredItems = _masterItems;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
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
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.blue.shade700,
                          ),
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
                          _loadMasterItems();
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
                      // Items List
                      if (_selectedBranch != null &&
                          _masterItems.isNotEmpty) ...[
                        const Text(
                          'Select Items to Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Search Items',
                            hintText: 'Search by SKU, name, or brand',
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
                        const SizedBox(height: 8),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.description,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'SKU: ${item.sku} | Brand: ${item.brand ?? 'N/A'}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller:
                                              _quantityControllers[item.id!],
                                          decoration: const InputDecoration(
                                            labelText: 'Qty',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _orderQuantities[item.id!] =
                                                  int.tryParse(value) ?? 0;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else if (_selectedBranch != null &&
                          _masterItems.isEmpty) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No items available for this branch'),
                          ),
                        ),
                      ],
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
