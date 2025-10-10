import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/master_item.dart';
import 'package:warehouse_inventory/models/order.dart';
import 'package:warehouse_inventory/providers/order_provider.dart';
import 'package:warehouse_inventory/screens/home_screen.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0651A4), Color(0xFF0A7BFF), Color(0xFF42A5F5)],
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
                  color: Colors.white.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.15),
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
                  color: Colors.white.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const HomeScreen(initialIndex: 0),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Create Order',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0651A4),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.shopping_cart,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Order Details',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Branch Dropdown
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF0651A4,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: DropdownButtonFormField<Branch>(
                                        value: _selectedBranch,
                                        decoration: InputDecoration(
                                          labelText: 'Branch *',
                                          labelStyle: const TextStyle(
                                            color: Color(0xFF0651A4),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.store,
                                            color: Color(0xFF0651A4),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                        ),
                                        menuMaxHeight: 200,
                                        items: _branches.map((Branch branch) {
                                          return DropdownMenuItem<Branch>(
                                            value: branch,
                                            child: Text(
                                              branch.name,
                                              style: const TextStyle(
                                                color: Color(0xFF0651A4),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (Branch? value) {
                                          setState(() {
                                            _selectedBranch = value;
                                            _locationController.text =
                                                value?.location ?? '';
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
                                    ),
                                    const SizedBox(height: 16),
                                    // Location TextField
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF0651A4,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _locationController,
                                        decoration: InputDecoration(
                                          labelText: 'Location *',
                                          labelStyle: const TextStyle(
                                            color: Color(0xFF0651A4),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                            color: Color(0xFF0651A4),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter location';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Items List
                                    if (_selectedBranch != null &&
                                        _masterItems.isNotEmpty) ...[
                                      const Text(
                                        'Select Items to Order',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0651A4),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Search Items',
                                            labelStyle: const TextStyle(
                                              color: Color(0xFF0651A4),
                                            ),
                                            hintText:
                                                'Search by SKU, name, or brand',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              color: Color(0xFF0651A4),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                          onChanged: _filterItems,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 300,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(
                                              0xFF0651A4,
                                            ).withOpacity(0.3),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: ListView.builder(
                                          itemCount: _filteredItems.length,
                                          itemBuilder: (context, index) {
                                            final item = _filteredItems[index];
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              color: Colors.white,
                                              shadowColor: const Color(
                                                0xFF0651A4,
                                              ).withOpacity(0.2),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF0651A4,
                                                          ).withOpacity(0.1),
                                                      child: const Icon(
                                                        Icons.inventory,
                                                        color: Color(
                                                          0xFF0651A4,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item.description,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                    0xFF0651A4,
                                                                  ),
                                                                ),
                                                          ),
                                                          Text(
                                                            'SKU: ${item.sku} | Brand: ${item.brand ?? 'N/A'}',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 80,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.grey.shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFF0651A4,
                                                          ).withOpacity(0.3),
                                                        ),
                                                      ),
                                                      child: TextField(
                                                        controller:
                                                            _quantityControllers[item
                                                                .id!],
                                                        decoration: InputDecoration(
                                                          labelText: 'Qty',
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly,
                                                        ],
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _orderQuantities[item
                                                                    .id!] =
                                                                int.tryParse(
                                                                  value,
                                                                ) ??
                                                                0;
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
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.warning,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'No items available for this branch',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
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
                                backgroundColor: const Color(0xFF0651A4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 6,
                                shadowColor: const Color(
                                  0xFF0651A4,
                                ).withOpacity(0.3),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
