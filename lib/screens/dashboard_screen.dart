import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalItems = 1245;
  int lowStockItems = 28;
  int totalBranches = 5;
  int totalCategories = 12;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Using demo data for now
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final crossAxisCount = isSmallScreen ? 1 : 2;
    final childAspectRatio = isSmallScreen ? 3.0 : 1.8; // Increased for better fit
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        titleSpacing: isSmallScreen ? 0.0 : 16.0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Warehouse Overview',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16.0 : 22.0, // Reduced font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4.0 : 12.0), // Reduced spacing
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: isSmallScreen ? 6.0 : 12.0, // Reduced spacing
                        mainAxisSpacing: isSmallScreen ? 6.0 : 12.0, // Reduced spacing
                        children: [
                          _buildDashboardCard(
                            context,
                            'Total Items',
                            totalItems.toString(),
                            Icons.inventory,
                            Colors.blue,
                          ),
                          _buildDashboardCard(
                            context,
                            'Low Stock Items',
                            lowStockItems.toString(),
                            Icons.warning,
                            Colors.orange,
                          ),
                          _buildDashboardCard(
                            context,
                            'Total Branches',
                            totalBranches.toString(),
                            Icons.store,
                            Colors.green,
                          ),
                          _buildDashboardCard(
                            context,
                            'Total Categories',
                            totalCategories.toString(),
                            Icons.category,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32.0, // Further reduced icon size
                color: color,
              ),
              const SizedBox(height: 8.0), // Reduced spacing
              Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // Handle text overflow
                style: TextStyle(
                  fontSize: isSmallScreen ? 12.0 : 13.0, // Further reduced font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0), // Reduced spacing
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16.0 : 18.0, // Further reduced font size
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}