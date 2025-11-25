import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
// Using Drift-generated classes instead of old model classes
import 'package:warehouse_inventory/screens/home_screen.dart';
import 'package:warehouse_inventory/screens/order_list_screen.dart';

class OrderScreen extends StatefulWidget {
   final Order? editOrder;

    const OrderScreen({super.key, this.editOrder});

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
    if (widget.editOrder != null) {
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
    if (widget.editOrder == null) return;

    final order = widget.editOrder!;

    // Wait for branches to be loaded if not already loaded
    if (_branches.isEmpty) {
      await _loadData();
    }

    // Find the branch for this order
    final branch = _branches.firstWhere(
      (b) => b.id == order.branchId,
      orElse: () => Branch(id: order.branchId, name: 'Branch ${order.branchId}', location: ''),
    );

    setState(() {
      _selectedBranch = branch;
      _locationController.text = order.location;
    });

    // Load master items for the branch
    await _loadMasterItems();

    // For editing, only show the specific order item
    setState(() {
      _quantityControllers.clear();
      _orderQuantities.clear();
      
      try {
        // Check if the order item exists in current master items
        final orderItem = _masterItems.firstWhere(
          (item) => item.id == order.itemId,
        );

        // Only show the order item
        _filteredItems = [orderItem];
        
        // Initialize controller and quantity for the order item
        _quantityControllers[order.itemId] = TextEditingController(text: order.quantity.toString());
        _orderQuantities[order.itemId] = order.quantity;
      } catch (e) {
        // Item not found in current master items - show warning and create a temporary item
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: The ordered item is no longer available in the current branch inventory. You can still update the order details.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Create a temporary item with order details for display
        final tempItem = MasterItem(
          id: order.itemId,
          sku: 'Unknown SKU',
          description: 'Item ID: ${order.itemId}',
          location: order.location,
          brand: order.brand,
          branchId: order.branchId,
        );

        _filteredItems = [tempItem];
        
        // Initialize controller and quantity for the order item
        _quantityControllers[order.itemId] = TextEditingController(text: order.quantity.toString());
        _orderQuantities[order.itemId] = order.quantity;
      }
    });
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

    try {
      String? batchId;
      List<OrdersCompanion>? orderCompanions;
      String? savedLocation;

      if (widget.editOrder != null) {
        // If editing, update the existing order
        final updatedOrder = widget.editOrder!.copyWith(
          branchId: _selectedBranch?.id ?? widget.editOrder!.branchId,
          location: _locationController.text.trim(),
          quantity: _orderQuantities[widget.editOrder!.itemId] ?? widget.editOrder!.quantity,
          dateOrdered: DateTime.now().toIso8601String(),
        );
        await AppDatabase.instance.updateOrder(updatedOrder);
      } else {
        // Generate a unique batch ID for this order session
        batchId = DateTime.now().millisecondsSinceEpoch.toString();

        // Preserve the location value before form reset
        savedLocation = _locationController.text.trim();

        // Create orders for each item with quantity > 0
        orderCompanions = [];
        // Use all master items for new orders
        for (var item in _masterItems) {
          int quantity = _orderQuantities[item.id ?? 0] ?? 0;
          if (quantity > 0) {
            final orderCompanion = OrdersCompanion.insert(
              branchId: _selectedBranch?.id ?? 0,
              location: _locationController.text.trim(),
              brand: item.brand ?? '',
              itemId: item.id ?? 0,
              quantity: quantity,
              dateOrdered: DateTime.now().toIso8601String(),
              status: const drift.Value('pending'),
              batchId: drift.Value(batchId),
            );
            orderCompanions.add(orderCompanion);
          }
        }

        // Add orders to database (only for new orders)
        for (var orderCompanion in orderCompanions) {
          await AppDatabase.instance.into(AppDatabase.instance.orders).insert(orderCompanion);
        }
      }

      // Simulate order submission
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Success!',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Text(
                widget.editOrder != null ? 'Order updated successfully!' : '${orderCompanions?.length ?? 0} order(s) submitted successfully!',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              actions: widget.editOrder != null
                  ? [
                      // Cancel button for edit mode
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                          foregroundColor: isDarkMode ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // View Order List button for edit mode - directs to order list screen
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const OrderListScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'View Order List',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ]
                  : [
                      // Two buttons for create mode
                      // Stay on current screen button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog

                          // Reset form for new orders
                          _formKey.currentState!.reset();
                          // Don't clear location - keep it for continuity
                          // Clear quantities
                          for (var controller in _quantityControllers.values) {
                            controller.clear();
                          }
                          setState(() {
                            _orderQuantities.clear();
                            // For new orders, reset all master items
                            for (var item in _masterItems) {
                              _orderQuantities[item.id ?? 0] = 0;
                            }
                            _searchQuery = '';
                            _filteredItems = _masterItems;
                            _inventoryStock.clear();
                            _itemSales.clear();
                            // Restore the location field with the saved value
                            if (savedLocation != null) {
                              _locationController.text = savedLocation;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                          foregroundColor: isDarkMode ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Go to orders list button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog

                          // Navigate to order list screen with the submitted batch ID
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => OrderListScreen(initialBatchId: batchId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'View Orders',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
            );
          },
        );

        // Reset form for new orders (only for create mode)
        if (widget.editOrder == null) {
          _formKey.currentState!.reset();
          // Don't clear location - keep it for continuity
          // Clear quantities
          for (var controller in _quantityControllers.values) {
            controller.clear();
          }
          setState(() {
            _orderQuantities.clear();
            // For new orders, reset all master items
            for (var item in _masterItems) {
              _orderQuantities[item.id ?? 0] = 0;
            }
            _searchQuery = '';
            _filteredItems = _masterItems;
            _inventoryStock.clear();
            _itemSales.clear();
            // Restore the location field with the saved value
            if (savedLocation != null) {
              _locationController.text = savedLocation;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${widget.editOrder != null ? 'updating' : 'saving'} orders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                            if (widget.editOrder != null) {
                              // If editing, navigate to order list screen
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const OrderListScreen(),
                                ),
                              );
                            } else {
                              // If creating new order, navigate to home screen
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(initialIndex: 0),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.editOrder != null ? 'Edit Order' : 'Create Order',
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
                                        widget.editOrder != null
                                            ? 'Edit Order Items'
                                            : 'Select Items to Order',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                        ),
                                      ),
                                      if (widget.editOrder != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'You are editing an existing order. Modify quantities as needed.',
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (widget.editOrder == null) ...[
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
                                      ],
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
                                            final isOrderedItem = widget.editOrder != null && item.id == widget.editOrder!.itemId;
                                            final hasQuantity = _orderQuantities[item.id ?? 0] != null && _orderQuantities[item.id ?? 0]! > 0;

                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              elevation: isOrderedItem ? 8 : 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                side: isOrderedItem ? BorderSide(
                                                  color: Colors.blue,
                                                  width: 2,
                                                ) : BorderSide.none,
                                              ),
                                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                                              shadowColor: isOrderedItem ? Colors.blue.withValues(alpha: 0.3) : const Color(
                                                0xFF0651A4,
                                              ).withValues(alpha: isDarkMode ? 0.5 : 0.2),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (isOrderedItem) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        margin: const EdgeInsets.only(bottom: 8),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.edit, size: 16, color: Colors.blue),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Currently Ordered',
                                                              style: TextStyle(
                                                                color: Colors.blue.shade700,
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    item.description,
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 14,
                                                                      color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                                                    ),
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  Container(
                                                                    width: double.infinity,
                                                                    child: Wrap(
                                                                      spacing: 12,
                                                                      runSpacing: 4,
                                                                      children: [
                                                                        _buildInfoChip(
                                                                          'SKU: ${item.sku}',
                                                                          isDarkMode,
                                                                          Icons.tag,
                                                                        ),
                                                                        _buildInfoChip(
                                                                          'Brand: ${item.brand ?? 'N/A'}',
                                                                          isDarkMode,
                                                                          Icons.label,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Container(
                                                          width: double.infinity,
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: isDarkMode ? Colors.grey[700] : Colors.grey.shade100,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            'Current Stock: ${_inventoryStock[item.sku] ?? 0}',
                                                            style: TextStyle(
                                                              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: _buildQuantitySection(
                                                            'Needed',
                                                            _quantityControllers[item.id ?? 0],
                                                            (value) {
                                                              setState(() {
                                                                _orderQuantities[item.id ?? 0] = int.tryParse(value) ?? 0;
                                                              });
                                                            },
                                                            isDarkMode,
                                                            Icons.add_shopping_cart,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: _buildQuantitySection(
                                                            'Replenishment',
                                                            null,
                                                            null,
                                                            isDarkMode,
                                                            Icons.refresh,
                                                            value: '${((_itemSales[item.sku] ?? 0) * (double.tryParse(_selectedBranch?.maintainingInventory ?? '0') ?? 0) - (_inventoryStock[item.sku] ?? 0))}',
                                                            readOnly: true,
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
                                _isLoading ? 'Submitting...' : (widget.editOrder != null ? 'Update Order' : 'Submit Order'),
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

  Widget _buildInfoChip(String text, bool isDarkMode, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection(
    String title,
    TextEditingController? controller,
    Function(String)? onChanged,
    bool isDarkMode,
    IconData icon, {
    String? value,
    bool readOnly = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title with icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Value/Input area
        if (readOnly && value != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Color(0xFF0651A4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ] else if (controller != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white38 : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Color(0xFF0651A4),
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ],
    );
  }
}
