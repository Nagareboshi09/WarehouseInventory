import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/models/order.dart';
import 'package:warehouse_inventory/screens/inventory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  int _totalItems = 0;
  int _lowStockItems = 0;
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final branches = await DatabaseHelper.instance.getAllBranches();
      setState(() {
        _branches = branches;
        if (_branches.isNotEmpty) {
          _selectedBranch = _branches.first;
          _loadDataForBranch(_selectedBranch!);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  Future<void> _loadDataForBranch(Branch branch) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await DatabaseHelper.instance.getInventoryItemsByBranch(branch.id!);
      final orders = await DatabaseHelper.instance.getOrdersByBranch(branch.id!);
      int total = items.length;
      int lowStock = items.where((item) => item.end <= 10).length;
      setState(() {
        _totalItems = total;
        _lowStockItems = lowStock;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1),
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
                  color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.15),
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
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1),
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
                  color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.12),
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
                        Expanded(
                          child: Text(
                            'Dashboard',
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850]!.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: DropdownButton<Branch>(
                                      value: _selectedBranch,
                                      hint: Text(
                                        'Select Branch',
                                        style: TextStyle(color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                                      ),
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Color(0xFF0651A4)),
                                      items: _branches.map((Branch branch) {
                                        return DropdownMenuItem<Branch>(
                                          value: branch,
                                          child: Text(
                                            '${branch.name} (${branch.location})',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (Branch? newBranch) {
                                        if (newBranch != null) {
                                          setState(() {
                                            _selectedBranch = newBranch;
                                          });
                                          _loadDataForBranch(newBranch);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24.0),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildAnimatedInfoCard(
                                                'Total Items',
                                                _totalItems.toString(),
                                                Icons.inventory,
                                                Colors.blue.shade400,
                                              ),
                                              const SizedBox(width: 16.0),
                                              _buildAnimatedInfoCard(
                                                'Low Stock Items',
                                                _lowStockItems.toString(),
                                                Icons.warning,
                                                Colors.orange.shade400,
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => InventoryScreen(initialBranch: _selectedBranch)),
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
                                                itemCount: _orders.length,
                                                itemBuilder: (context, index) {
                                                  final order = _orders[index];
                                                  return Card(
                                                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.shopping_cart,
                                                        color: Colors.green.shade600,
                                                      ),
                                                      title: Text('${order.brand} - Item ${order.itemId}'),
                                                      subtitle: Text('Quantity: ${order.quantity} • Status: ${order.status}'),
                                                      trailing: Text(
                                                        '${order.dateOrdered.day}/${order.dateOrdered.month}/${order.dateOrdered.year}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
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
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
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