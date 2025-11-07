import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:warehouse_inventory/screens/inventory_screen.dart';
import 'package:warehouse_inventory/screens/master_data_screen.dart';
import 'package:warehouse_inventory/screens/order_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Use Drift-generated classes directly - imported from app_database.dart
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  int _totalMasterItems = 0;
  int _totalInventoryQuantity = 0;
  int _lowStockItems = 0;
  int _totalOrders = 0;
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadAllData();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final branches = await AppDatabase.instance.getAllBranches();
      setState(() {
        _branches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load branches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final allMasterItems = await AppDatabase.instance.getAllMasterItems();
      final allInventoryItems = await AppDatabase.instance.getAllInventoryItems();
      final allOrders = await AppDatabase.instance.getAllOrders();
      
      int totalMaster = allMasterItems.length;
      int totalInventoryQuantity = allInventoryItems.fold(0, (sum, item) => sum + item.end);
      int lowStock = allInventoryItems.where((item) => item.end <= 10).length;
      int totalOrders = allOrders.length;
      
      setState(() {
        _totalMasterItems = totalMaster;
        _totalInventoryQuantity = totalInventoryQuantity;
        _lowStockItems = lowStock;
        _totalOrders = totalOrders;
        _orders = allOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDataForBranch(Branch branch) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final masterItems = await AppDatabase.instance.getMasterItemsByBranch(branch.id);
      final items = await AppDatabase.instance.getInventoryItemsByBranch(branch.id);
      final orders = await AppDatabase.instance.getOrdersByBranch(branch.id);

      int totalMaster = masterItems.length;
      // Parse maintainingInventory as int, default to 10 if null or invalid
      int maintainingInventory = branch.maintainingInventory != null
          ? int.tryParse(branch.maintainingInventory!) ?? 10
          : 10;
      int lowStockThreshold = maintainingInventory - 1;
      int lowStock = items.where((item) => item.end <= lowStockThreshold).length;
      int totalInventoryQuantity = items.fold(0, (sum, item) => sum + item.end);
      int totalOrders = orders.length;

      setState(() {
        _totalMasterItems = totalMaster;
        _totalInventoryQuantity = totalInventoryQuantity;
        _lowStockItems = lowStock;
        _totalOrders = totalOrders;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load branch data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<List<Order>> _getOrderBatches() {
    final orderBatches = <String, List<Order>>{};
    for (final order in _orders) {
      final batchId = order.batchId ?? 'single_${order.id}';
      if (!orderBatches.containsKey(batchId)) {
        orderBatches[batchId] = [];
      }
      orderBatches[batchId]!.add(order);
    }

    final batchList = orderBatches.values.toList()
      ..sort((a, b) => b.first.dateOrdered.compareTo(a.first.dateOrdered));

    return batchList;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        titleSpacing: 16.0,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D), const Color(0xFF3A3A3A)]
                      : [const Color(0xFF0651A4), const Color(0xFF0A7BFF), const Color(0xFF42A5F5)],
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: DropdownButton<Branch>(
                                value: _selectedBranch,
                                hint: Text('Select Branch', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                                isExpanded: true,
                                underline: const SizedBox(),
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
                                items: _branches.map((Branch branch) {
                                  return DropdownMenuItem<Branch>(
                                    value: branch,
                                    child: Text('${branch.name} (${branch.location})', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                  );
                                }).toList(),
                                onChanged: (Branch? newBranch) {
                                  if (newBranch != null) {
                                    setState(() {
                                      _selectedBranch = newBranch;
                                    });
                                    _loadDataForBranch(newBranch);
                                  } else {
                                    setState(() {
                                      _selectedBranch = null;
                                    });
                                    _loadAllData();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAnimatedInfoCard(
                                  'Total Items',
                                  _totalMasterItems.toString(),
                                  Icons.inventory,
                                  Colors.blue.shade400,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => InventoryScreen(initialBranch: _selectedBranch)),
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                _buildAnimatedInfoCard(
                                  'Total Inventory',
                                  _totalInventoryQuantity.toString(),
                                  Icons.storage,
                                  Colors.green.shade400,
                                  null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAnimatedInfoCard(
                                  'Total Orders',
                                  _totalOrders.toString(),
                                  Icons.shopping_cart,
                                  Colors.purple.shade400,
                                  null,
                                ),
                                const SizedBox(width: 16.0),
                                _buildAnimatedInfoCard(
                                  'Low Stock Items',
                                  _lowStockItems.toString(),
                                  Icons.warning,
                                  Colors.orange.shade400,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => InventoryScreen(initialBranch: _selectedBranch, showLowStockOnly: true)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            if (_orders.isNotEmpty) ...[
                              Text(
                                'Ordered Products',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _getOrderBatches().length,
                                  itemBuilder: (context, index) {
                                    final batch = _getOrderBatches()[index];
                                    final firstOrder = batch.first;
                                    final totalItems = batch.length;
                                    final totalQuantity = batch.fold(0, (sum, order) => sum + order.quantity);

                                    // Parse date string to DateTime for display
                                    DateTime? orderDate;
                                    try {
                                      orderDate = DateTime.parse(firstOrder.dateOrdered);
                                    } catch (e) {
                                      orderDate = null;
                                    }

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: InkWell(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OrderListScreen(initialBatchId: firstOrder.batchId ?? 'single_${firstOrder.id}'),
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.inventory_2,
                                            color: Colors.green.shade600,
                                          ),
                                          title: Text('Order Batch • $totalItems item${totalItems > 1 ? 's' : ''}'),
                                          subtitle: Text('Total: $totalQuantity units • Status: ${firstOrder.status}'),
                                          trailing: Text(
                                            orderDate != null
                                                ? '${orderDate.day}/${orderDate.month}/${orderDate.year}'
                                                : firstOrder.dateOrdered,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ] else ...[
                              Text(
                                'No orders for this branch',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnimatedInfoCard(String title, String value, IconData icon, Color color, [VoidCallback? onTap]) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 150,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4.0),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}