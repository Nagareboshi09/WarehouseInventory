import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/branch.dart';
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
      int total = items.length;
      int lowStock = items.where((item) => item.end <= 10).length;
      setState(() {
        _totalItems = total;
        _lowStockItems = lowStock;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        titleSpacing: isSmallScreen ? 0.0 : 16.0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownButton<Branch>(
                        value: _selectedBranch,
                        hint: const Text('Select Branch'),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _branches.map((Branch branch) {
                          return DropdownMenuItem<Branch>(
                            value: branch,
                            child: Text('${branch.name} (${branch.location})'),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoCard(
                              'Total Items',
                              _totalItems.toString(),
                              Icons.inventory,
                              Colors.blue.shade400,
                            ),
                            const SizedBox(width: 16.0),
                            _buildInfoCard(
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, [VoidCallback? onTap]) {
    final card = Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
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
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    } else {
      return card;
    }
  }

}