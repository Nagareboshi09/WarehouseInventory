import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warehouse_inventory/screens/dashboard_screen.dart';
import 'package:warehouse_inventory/screens/inventory_screen.dart';
import 'package:warehouse_inventory/screens/master_data_screen.dart';
import 'package:warehouse_inventory/screens/settings_screen.dart';
import 'package:warehouse_inventory/screens/order_screen.dart';
import 'package:warehouse_inventory/screens/order_list_screen.dart';
import 'package:warehouse_inventory/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  String _username = '';
  String _role = '';

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MasterDataScreen(),
    const InventoryScreen(),
    const OrderScreen(),
    const OrderListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _role = prefs.getString('role') ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');
    await prefs.remove('role');

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: isSelected
            ? Border.all(color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.white, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75, // Make drawer wider
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Color(0xFF1E1E1E), Color(0xFF2D2D2D), Color(0xFF3A3A3A)]
                  : [Color(0xFF0651A4), Color(0xFF0A7BFF), Color(0xFF42A5F5)],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.white,
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : '',
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Role: $_role',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      isSelected: _selectedIndex == 0,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 0;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.category,
                      title: 'Master Data',
                      isSelected: _selectedIndex == 1,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.inventory,
                      title: 'Inventory',
                      isSelected: _selectedIndex == 2,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 2;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.shopping_cart,
                      title: 'Orders',
                      isSelected: _selectedIndex == 3,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 3;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.list_alt,
                      title: 'Order List',
                      isSelected: _selectedIndex == 4,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 4;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      isSelected: _selectedIndex == 5,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 5;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white30, thickness: 1),
                    const SizedBox(height: 10),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isSelected: false,
                      onTap: _logout,
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
