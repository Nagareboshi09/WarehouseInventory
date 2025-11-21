import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:warehouse_inventory/providers/order_provider.dart';
import 'package:warehouse_inventory/screens/home_screen.dart';
import 'package:warehouse_inventory/screens/order_screen.dart';
import 'package:warehouse_inventory/utils/user_helper.dart';
import 'package:excel/excel.dart' as excel_package;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatefulWidget {
  final String? initialBatchId;

  const OrderListScreen({super.key, this.initialBatchId});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String? _selectedBranch;
  String? _selectedProduct;
  List<Branch> _branches = [];
  String _searchQuery = '';
  String? _filterBatchId;

  @override
  void initState() {
    super.initState();
    _filterBatchId = widget.initialBatchId;
    // Refresh orders when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderProvider>().loadOrders();
        _loadBranches();
      }
    });
  }

  Future<void> _loadBranches() async {
    final branches = await AppDatabase.instance.getAllBranches();
    if (mounted) {
      setState(() {
        _branches = branches..sort((a, b) => a.id.compareTo(b.id));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final allOrders = orderProvider.orders;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        // Filter orders based on selected branch, product, and search query
        final orders = allOrders.where((order) {
          final branchMatch = _selectedBranch == null || order.branchId.toString() == _selectedBranch;
          final productMatch = _selectedProduct == null || order.brand == _selectedProduct;
          final batchMatch = _filterBatchId == null || (order.batchId ?? 'single_${order.id}') == _filterBatchId;

          // Search filter
          final searchMatch = _searchQuery.isEmpty ||
              order.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order.itemId.toString().toLowerCase().contains(_searchQuery.toLowerCase());

          return branchMatch && productMatch && batchMatch && searchMatch;
        }).toList();

        // Get unique branches and products for filter dropdowns
        final branchIds = allOrders.map((o) => o.branchId).toSet().toList()..sort();
        final products = allOrders.map((o) => o.brand).toSet().toList()..sort();

        // Group orders by batchId
        final orderBatches = <String, List<Order>>{};
        for (final order in orders) {
          final batchId = order.batchId ?? 'single_${order.id}';
          if (!orderBatches.containsKey(batchId)) {
            orderBatches[batchId] = [];
          }
          orderBatches[batchId]!.add(order);
        }

        final batchList = orderBatches.entries.toList()
          ..sort(
            (a, b) =>
                b.value.first.dateOrdered.compareTo(a.value.first.dateOrdered),
          );

        return Scaffold(
          floatingActionButton: batchList.isEmpty ? FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OrderScreen(),
                ),
              ).then((_) {
                // Refresh orders after returning from order screen
                if (mounted) {
                  Provider.of<OrderProvider>(context, listen: false).loadOrders();
                }
              });
            },
            backgroundColor: const Color(0xFF0651A4),
            foregroundColor: Colors.white,
            elevation: 6,
            tooltip: 'Go to Order Screen',
            child: const Icon(Icons.shopping_cart),
          ) : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Download XLSX Floating Action Button
              FloatingActionButton(
                onPressed: () => _downloadBatchListAsXLSX(context, orders, _branches),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 6,
                tooltip: 'Send Batch List as XLSX',
                heroTag: "download_xlsx",
                child: const Icon(Icons.send),
              ),
              const SizedBox(width: 16),
              // Add Order Floating Action Button
              FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrderScreen(),
                    ),
                  ).then((_) {
                    // Refresh orders after returning from order screen
                    if (mounted) {
                      context.read<OrderProvider>().loadOrders();
                    }
                  });
                },
                backgroundColor: const Color(0xFF0651A4),
                foregroundColor: Colors.white,
                elevation: 6,
                tooltip: 'Go to Order Screen',
                heroTag: "add_order",
                child: const Icon(Icons.shopping_cart),
              ),
            ],
          ),
          body: Container(
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
                                'Submitted Orders',
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
                            IconButton(
                              onPressed: () => _showFilterDialog(context, branchIds, products, allOrders),
                              icon: Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search TextField
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Search Orders',
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                            ),
                            hintText: 'Search by brand, location, or item ID',
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[700] : Colors.white,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: batchList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[850]!.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : const Color(0xFF0651A4).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 60,
                                            color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No orders submitted yet',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Create your first order from the Orders screen',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 16.0 : 24.0,
                                ),
                                itemCount: batchList.length,
                                itemBuilder: (context, index) {
                                  final batchEntry = batchList[index];
                                  final batchOrders = batchEntry.value;
                                  final firstOrder = batchOrders.first;
                                  final totalItems = batchOrders.length;
                                  final totalQuantity = batchOrders.fold(
                                    0,
                                    (sum, order) => sum + order.quantity,
                                  );
                                  
                                  // Parse date string for display
                                  DateTime? firstOrderDate;
                                  try {
                                    firstOrderDate = DateTime.parse(firstOrder.dateOrdered);
                                  } catch (e) {
                                    firstOrderDate = null;
                                  }
                                  
                                  return Card(
                                    elevation: 6,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                                    shadowColor: const Color(
                                      0xFF0651A4,
                                    ).withValues(alpha: isDarkMode ? 0.5 : 0.2),
                                    child: InkWell(
                                      onTap: () => _showBatchDetails(
                                        context,
                                        batchOrders,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : const Color(0xFF0651A4).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.inventory_2,
                                                    color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Order Batch',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
                                                        ),
                                                      ),
                                                      Text(
                                                        '$totalItems item${totalItems > 1 ? 's' : ''} • Total: $totalQuantity units',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : const Color(0xFF0651A4).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    firstOrderDate != null 
                                                        ? '${firstOrderDate.day}/${firstOrderDate.month}/${firstOrderDate.year}'
                                                        : firstOrder.dateOrdered,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildInfoItem(
                                                    'Branch',
                                                    _branches.firstWhere(
                                                      (b) => b.id == firstOrder.branchId,
                                                      orElse: () => Branch(id: firstOrder.branchId, name: 'Branch ${firstOrder.branchId}', location: ''),
                                                    ).name,
                                                    isDarkMode: isDarkMode,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _buildInfoItem(
                                                    'Location',
                                                    firstOrder.location,
                                                    isDarkMode: isDarkMode,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : const Color(0xFF0651A4).withValues(alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(15),
                                                    ),
                                                    child: Text(
                                                      'Tap to view order details',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () => _editOrderBatch(batchOrders),
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Edit Order',
                                                ),
                                                IconButton(
                                                  onPressed: () => _deleteOrderBatch(batchOrders),
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Delete Order',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isDarkMode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _downloadBatchListAsXLSX(BuildContext buildContext, List<Order> orders, List<Branch> branches) async {
    if (orders.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          const SnackBar(
            content: Text('No orders to export'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: buildContext,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            if (!mounted) {
              return const SizedBox.shrink();
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }

      // Create Excel workbook
      final excel = excel_package.Excel.createExcel();
      
      // Get the default sheet or create if doesn't exist
      var sheetObject = excel['Sheet1'];
      
      // Add headers - SKU and Description as first two columns
      sheetObject.appendRow([
        'SKU',
        'Description',
        'Date Ordered',
        'Branch Code',
        'Location',
        'Brand',
        'Quantity',
        'Status'
      ]);

      // Group orders by batch ID for summary
      final orderBatches = <String, List<Order>>{};
      for (final order in orders) {
        final batchId = order.batchId ?? 'single_${order.id}';
        if (!orderBatches.containsKey(batchId)) {
          orderBatches[batchId] = [];
        }
        orderBatches[batchId]!.add(order);
      }

      // Get all master items and inventory items to look up SKU and Description
      final masterItems = await AppDatabase.instance.getAllMasterItems();
      final inventoryItems = await AppDatabase.instance.getAllInventoryItems();

      // Combine both lists for easier lookup
      final allItems = <int, Map<String, String>>{};
      
      // Add master items
      for (final item in masterItems) {
        allItems[item.id] = {
          'sku': item.sku,
          'description': item.description,
        };
      }
      
      // Add inventory items (will override if same ID exists in master)
      for (final item in inventoryItems) {
        allItems[item.id] = {
          'sku': item.sku,
          'description': item.description,
        };
      }

      // Add order data (SKU, Description, and all order information)
      for (final order in orders) {
        final branchCode = branches.firstWhere(
          (b) => b.id == order.branchId,
          orElse: () => Branch(id: order.branchId, name: 'Branch ${order.branchId}', location: '', code: 'N/A'),
        ).code ?? 'N/A';

        // Parse date for better formatting
        DateTime? orderDate;
        try {
          orderDate = DateTime.parse(order.dateOrdered);
        } catch (e) {
          orderDate = null;
        }

        // Get SKU and Description for this order item
        final itemDetails = allItems[order.itemId];
        final sku = itemDetails?['sku'] ?? 'Unknown SKU';
        final description = itemDetails?['description'] ?? 'Unknown Description';

        sheetObject.appendRow([
          sku,
          description,
          orderDate != null 
              ? DateFormat('yyyy-MM-dd HH:mm').format(orderDate) 
              : order.dateOrdered,
          branchCode,
          order.location,
          order.brand,
          order.quantity.toString(),
          order.status,
        ]);
      }

      // Add user information section at the very end
      final currentUser = await UserHelper.getCurrentUser();
      final username = currentUser?['username'] ?? 'Unknown User';
      final role = currentUser?['role'] ?? 'user';
      final exportTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      // Add empty row for separation before user info
      sheetObject.appendRow(['', '', '', '', '', '', '', '']);
      
      // Add user information as separate rows (after all order data)
      sheetObject.appendRow(['Exported By: $username', '', '', '', '', '', '', '']);
      sheetObject.appendRow(['Role: $role', '', '', '', '', '', '', '']);
      sheetObject.appendRow(['Export Time: $exportTime', '', '', '', '', '', '', '']);

      // Add a summary sheet
      var summarySheet = excel['Summary'];
      
      // Add summary headers
      summarySheet.appendRow([
        'Batch ID',
        'Order Count',
        'Total Quantity',
        'Date Ordered',
        'Branch Code',
        'Location'
      ]);

      // Add batch summary data
      final batchList = orderBatches.entries.toList()
        ..sort((a, b) => b.value.first.dateOrdered.compareTo(a.value.first.dateOrdered));

      for (final batchEntry in batchList) {
        final batchOrders = batchEntry.value;
        final firstOrder = batchOrders.first;
        final totalItems = batchOrders.length;
        final totalQuantity = batchOrders.fold(0, (sum, order) => sum + order.quantity);
        
        final branchCode = branches.firstWhere(
          (b) => b.id == firstOrder.branchId,
          orElse: () => Branch(id: firstOrder.branchId, name: 'Branch ${firstOrder.branchId}', location: '', code: 'N/A'),
        ).code ?? 'N/A';

        // Parse date for better formatting
        DateTime? orderDate;
        try {
          orderDate = DateTime.parse(firstOrder.dateOrdered);
        } catch (e) {
          orderDate = null;
        }

        summarySheet.appendRow([
          batchEntry.key,
          totalItems.toString(),
          totalQuantity.toString(),
          orderDate != null 
              ? DateFormat('yyyy-MM-dd HH:mm').format(orderDate) 
              : firstOrder.dateOrdered,
          branchCode,
          firstOrder.location,
        ]);
      }

      // Generate filename with timestamp
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final filename = 'batch_list_$timestamp.xlsx';

      // Save the file
      final bytes = excel.encode();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes!);

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Share the file using Share Plus
      final xFile = XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      await Share.shareXFiles(
        [xFile],
        subject: 'Order Batch List - $timestamp',
        text: 'Please find attached the order batch list generated on ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          const SnackBar(
            content: Text('Batch list are sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clean up temporary file after sharing (optional)
      // Uncomment if you want to delete the file after sharing
      /*
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
      */

    } catch (e) {
      // Close loading indicator if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating XLSX file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterDialog(BuildContext buildContext, List<int> branchIds, List<String> products, List<Order> allOrders) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Local variables for dialog state
    String? localSelectedBranch = _selectedBranch;
    String? localSelectedProduct = _selectedProduct;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Filter Orders',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Branch Filter
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter by Branch',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: isDarkMode ? Colors.grey[700] : Colors.white,
                              ),
                              child: DropdownButton<String>(
                                value: localSelectedBranch,
                                isExpanded: true,
                                underline: const SizedBox(),
                                hint: const Text('Select Branch'),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Branches'),
                                  ),
                                  ...branchIds.map((branchId) {
                                    final branch = _branches.firstWhere(
                                      (b) => b.id == branchId,
                                      orElse: () => Branch(id: branchId, name: 'Branch $branchId', location: ''),
                                    );
                                    return DropdownMenuItem<String>(
                                      value: branchId.toString(),
                                      child: Text(branch.name),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    localSelectedBranch = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Product Filter
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter by Product',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
                            ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: isDarkMode ? Colors.grey[700] : Colors.white,
                              ),
                              child: DropdownButton<String>(
                                value: localSelectedProduct,
                                isExpanded: true,
                                underline: const SizedBox(),
                                hint: const Text('Select Product'),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Products'),
                                  ),
                                  ...products.map((product) => DropdownMenuItem<String>(
                                    value: product,
                                    child: Text(product),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    localSelectedProduct = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  localSelectedBranch = null;
                                  localSelectedProduct = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                foregroundColor: isDarkMode ? Colors.white : Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text('Clear Filters'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Apply filters and close dialog
                                this.setState(() {
                                  _selectedBranch = localSelectedBranch;
                                  _selectedProduct = localSelectedProduct;
                                });
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF0651A4).withValues(alpha: isDarkMode ? 0.5 : 0.3),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editOrderBatch(List<Order> batchOrders) {
    // Navigate to order screen with pre-filled data for editing
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderScreen(editBatch: batchOrders),
      ),
    ).then((_) {
      // Refresh orders after returning from edit screen
      if (mounted) {
        context.read<OrderProvider>().loadOrders();
      }
    });
  }

  void _deleteOrderBatch(List<Order> batchOrders) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text(
            'Delete Order Batch',
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this order batch with ${batchOrders.length} items?',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  for (final order in batchOrders) {
                    await AppDatabase.instance.deleteOrder(order.id);
                  }
                  // Refresh the orders list
                  if (mounted) {
                    context.read<OrderProvider>().loadOrders();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order batch deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting order batch: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBatchDetails(BuildContext buildContext, List<Order> batchOrders) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Order Batch Details (${batchOrders.length} items)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: batchOrders.length,
                    itemBuilder: (context, index) {
                      final order = batchOrders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                        shadowColor: const Color(0xFF0651A4).withValues(alpha: isDarkMode ? 0.5 : 0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF0651A4,
                                    ).withValues(alpha: isDarkMode ? 0.3 : 0.1),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF0651A4),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Item ${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
                                          ),
                                        ),
                                        Text(
                                          'Brand: ${order.brand}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          'Item ID: ${order.itemId}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.3) : const Color(0xFF0651A4).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      'Qty: ${order.quantity}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF0651A4).withValues(alpha: isDarkMode ? 0.5 : 0.3),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
