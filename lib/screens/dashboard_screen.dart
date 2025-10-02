import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/inventory_item.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<InventoryItem> _lowStockItems = [];
  int _totalItems = 0;
  int _lowStockCount = 0;
  Map<String, int> _itemsByClass = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all inventory items
      final allItems = await DatabaseHelper.instance.getAllInventoryItems();
      
      // Get low stock items (threshold set to 10)
      final lowStockItems = await DatabaseHelper.instance.getLowStockItems(10);
      
      // Calculate items by class
      final itemsByClass = <String, int>{};
      for (var item in allItems) {
        if (itemsByClass.containsKey(item.itemClass)) {
          itemsByClass[item.itemClass] = itemsByClass[item.itemClass]! + 1;
        } else {
          itemsByClass[item.itemClass] = 1;
        }
      }

      if (mounted) {
        setState(() {
          _totalItems = allItems.length;
          _lowStockItems = lowStockItems;
          _lowStockCount = lowStockItems.length;
          _itemsByClass = itemsByClass;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Items',
                            _totalItems.toString(),
                            Icons.inventory,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Low Stock Items',
                            _lowStockCount.toString(),
                            Icons.warning,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Low stock items
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Low Stock Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _lowStockItems.isEmpty
                                ? const Center(
                                    child: Text('No low stock items'),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _lowStockItems.length > 5
                                        ? 5
                                        : _lowStockItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _lowStockItems[index];
                                      return ListTile(
                                        title: Text(item.description),
                                        subtitle: Text('SKU: ${item.sku}'),
                                        trailing: Text(
                                          'Qty: ${item.quantity}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            if (_lowStockItems.length > 5) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    // Navigate to inventory screen with low stock filter
                                  },
                                  child: const Text('View All'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Item distribution by class
                    if (_itemsByClass.isNotEmpty)
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Item Distribution by Class',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: _buildPieChart(),
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    
    int colorIndex = 0;
    _itemsByClass.forEach((className, count) {
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '$className\n${count.toString()}',
          color: colors[colorIndex % colors.length],
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}