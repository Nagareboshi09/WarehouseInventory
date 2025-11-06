import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
// Using Drift-generated classes instead of old model classes
import 'package:warehouse_inventory/providers/order_provider.dart';
import 'package:warehouse_inventory/screens/home_screen.dart';

class OrderScreen extends StatefulWidget {
   final List<Order>? editBatch;

   const OrderScreen({super.key, this.editBatch});

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
  Map<String, int> _inventoryStock = {};
  Map<String, int> _itemSales = {};
  String _searchQuery = '';
  List<MasterItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.editBatch != null) {
      _loadEditData();
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final branches = await AppDatabase.instance.getAllBranches();
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

  Future<void> _loadEditData() async {
    if (widget.editBatch == null || widget.editBatch!.isEmpty) return;

    final firstOrder = widget.editBatch!.first;

    // Wait for branches to be loaded if not already loaded
    if (_branches.isEmpty) {
      await _loadData();
    }

    // Find the branch for this order
    final branch = _branches.firstWhere(
      (b) => b.id == firstOrder.branchId,
      orElse: () => Branch(id: firstOrder.branchId, name: 'Branch ${firstOrder.branchId}', location: ''),
    );

    setState(() {
      _selectedBranch = branch;
      _locationController.text = firstOrder.location;
    });

    // Load master items for the branch
    await _loadMasterItems();

    // Pre-fill quantities from the edit batch
    for (final order in widget.editBatch!) {
      if (_orderQuantities.containsKey(order.itemId)) {
        _quantityControllers[order.itemId]?.text = order.quantity.toString();
        _orderQuantities[order.itemId] = order.quantity;
      }
    }
  }

  Future<void> _loadMasterItems() async {
    if (_selectedBranch == null) return;
    try {
      final masterItems = await AppDatabase.instance.getMasterItemsByBranch(
        _selectedBranch?.id ?? 0,
      );
      final inventoryItems = await AppDatabase.instance.getInventoryItemsByBranch(
        _selectedBranch?.id ?? 0,
      );

      // Create a map of SKU to stock quantity and sales
      final stockMap = <String, int>{};
      final salesMap = <String, int>{};
      for (var invItem in inventoryItems) {
        stockMap[invItem.sku] = invItem.end;
        salesMap[invItem.sku] = invItem.sales ?? 0;
      }

      setState(() {
        _masterItems = masterItems;
        _filteredItems = masterItems;
        _inventoryStock = stockMap;
        _itemSales = salesMap;
        // Initialize controllers for each item
        _quantityControllers.clear();
        _orderQuantities.clear();
        for (var item in masterItems) {
          _quantityControllers[item.id ?? 0] = TextEditingController();
          _orderQuantities[item.id ?? 0] = 0;
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

    // If editing, delete existing orders first
    if (widget.editBatch != null) {
      try {
        for (final order in widget.editBatch!) {
          await AppDatabase.instance.deleteOrder(order.id);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating orders: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    // Generate a unique batch ID for this order session (or use existing if editing)
    final batchId = widget.editBatch != null
        ? widget.editBatch!.first.batchId ?? DateTime.now().millisecondsSinceEpoch.toString()
        : DateTime.now().millisecondsSinceEpoch.toString();

    // Preserve the location value before form reset
    final savedLocation = _locationController.text.trim();

    // Create orders for each item with quantity > 0
    List<OrdersCompanion> orderCompanions = [];
    for (var item in _masterItems) {
      int quantity = _orderQuantities[item.id ?? 0] ?? 0;
      if (quantity > 0) {
        final orderCompanion = OrdersCompanion.insert(
          branchId: _selectedBranch?.id ?? 0,
          location: _locationController.text.trim(),
          brand: item.brand ?? '',
          itemId: item.id ?? 0,
          quantity: quantity,
          dateOrdered: widget.editBatch != null ? widget.editBatch!.first.dateOrdered : DateTime.now().toIso8601String(),
          status: const drift.Value('pending'),
          batchId: drift.Value(batchId),
        );
        orderCompanions.add(orderCompanion);
      }
    }

    // Add orders to provider
    try {
      for (var orderCompanion in orderCompanions) {
        await AppDatabase.instance.into(AppDatabase.instance.orders).insert(orderCompanion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving orders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Simulate order submission
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editBatch != null ? 'Order updated successfully!' : '${orderCompanions.length} order(s) submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // If editing, go back to order list
      if (widget.editBatch != null) {
        Navigator.of(context).pop();
        return;
      }

      // Reset form for new orders
      _formKey.currentState!.reset();
      // Don't clear location - keep it for continuity
      // Clear quantities
      for (var controller in _quantityControllers.values) {
        controller.clear();
      }
      setState(() {
        _orderQuantities.clear();
        for (var item in _masterItems) {
          _orderQuantities[item.id ?? 0] = 0;
        }
        _searchQuery = '';
        _filteredItems = _masterItems;
        _inventoryStock.clear();
        _itemSales.clear();
        // Restore the location field with the saved value
        _locationController.text = savedLocation;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
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
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.editBatch != null ? 'Edit Order' : 'Create Order',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withValues(alpha: 0.3),
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
                                color: isDarkMode ? (Colors.grey[850] ?? Colors.grey).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
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
                                        color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
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
                                        color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: DropdownButtonFormField<Branch>(
                                        initialValue: _selectedBranch,
                                        decoration: InputDecoration(
                                          labelText: 'Branch *',
                                          labelStyle: TextStyle(
                                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                          ),
                                          prefixIcon: Icon(
                                            Icons.store,
                                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                                        color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _locationController,
                                        decoration: InputDecoration(
                                          labelText: 'Location *',
                                          labelStyle: TextStyle(
                                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                          ),
                                          prefixIcon: Icon(
                                            Icons.location_on,
                                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                                      Text(
                                        'Select Items to Order',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Search Items',
                                            labelStyle: TextStyle(
                                              color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                            ),
                                            hintText:
                                                'Search by SKU, name, or brand',
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3),
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
                                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                                              shadowColor: const Color(
                                                0xFF0651A4,
                                              ).withValues(alpha: isDarkMode ? 0.5 : 0.2),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF0651A4,
                                                              ).withValues(alpha: isDarkMode ? 0.3 : 0.1),
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
                                                                    TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                                                    ),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    'SKU: ${item.sku}',
                                                                    style: TextStyle(
                                                                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                                                      fontSize: 12,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 16),
                                                                  Text(
                                                                    'Brand: ${item.brand ?? 'N/A'}',
                                                                    style: TextStyle(
                                                                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                                                      fontSize: 12,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Text(
                                                                'Current Stock: ${_inventoryStock[item.sku] ?? 0}',
                                                                style: TextStyle(
                                                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                            height: 60,
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: isDarkMode ? Colors.grey[700] : Colors.grey.shade50,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3),
                                                              ),
                                                            ),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Text(
                                                                  'Needed',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                                                  ),
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                                const SizedBox(height: 2),
                                                                SizedBox(
                                                                  height: 24,
                                                                  child: TextField(
                                                                    controller: _quantityControllers[item.id ?? 0],
                                                                    textAlign: TextAlign.center,
                                                                    style: TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                                                    ),
                                                                    decoration: InputDecoration(
                                                                      hintText: '0',
                                                                      border: InputBorder.none,
                                                                      contentPadding: EdgeInsets.zero,
                                                                      isDense: true,
                                                                    ),
                                                                    keyboardType: TextInputType.number,
                                                                    inputFormatters: [
                                                                      FilteringTextInputFormatter.digitsOnly,
                                                                    ],
                                                                    onChanged: (value) {
                                                                      setState(() {
                                                                        _orderQuantities[item.id ?? 0] = int.tryParse(value) ?? 0;
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Container(
                                                            height: 60,
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: isDarkMode ? Colors.grey[700] : Colors.grey.shade50,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: isDarkMode ? Colors.white70 : Color(0xFF0651A4).withValues(alpha: 0.3),
                                                              ),
                                                            ),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Text(
                                                                  'Replenishment',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                                                  ),
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  '${((_itemSales[item.sku] ?? 0) * (double.tryParse(_selectedBranch?.maintainingInventory ?? '0') ?? 0) - (_inventoryStock[item.sku] ?? 0))}',
                                                                  style: TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                                                  ),
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
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
                                          color: Colors.red.withValues(alpha: 0.1),
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
                                backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
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
                                ).withValues(alpha: isDarkMode ? 0.5 : 0.3),
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
                                _isLoading ? 'Submitting...' : (widget.editBatch != null ? 'Update Order' : 'Submit Order'),
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
