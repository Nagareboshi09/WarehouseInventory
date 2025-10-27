import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse_inventory/models/order.dart';
import 'package:warehouse_inventory/providers/order_provider.dart';
import 'package:warehouse_inventory/screens/home_screen.dart';
import 'package:warehouse_inventory/screens/order_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<Order>? _recentlyDeletedBatch;
  bool _showUndoButton = false;
  void initState() {
    super.initState();
    // Refresh orders when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final orders = orderProvider.orders;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

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
                      // Undo button that appears after 5 seconds
                      if (_showUndoButton && _recentlyDeletedBatch != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
                            onPressed: _undoDelete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.undo),
                            label: const Text(
                              'Undo Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: batchList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[850]!.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Color(0xFF0651A4).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 60,
                                            color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No orders submitted yet',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Color(0xFF0651A4),
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
                                  return Card(
                                    elevation: 6,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                                    shadowColor: const Color(
                                      0xFF0651A4,
                                    ).withOpacity(isDarkMode ? 0.5 : 0.2),
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
                                                    color: isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Color(0xFF0651A4).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.inventory_2,
                                                    color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                                                          color: isDarkMode ? Colors.white : Color(0xFF0651A4),
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
                                                    color: isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Color(0xFF0651A4).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${firstOrder.dateOrdered.day}/${firstOrder.dateOrdered.month}/${firstOrder.dateOrdered.year}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                                                    'Branch ${firstOrder.branchId}',
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
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Color(0xFF0651A4).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                'Tap to view order details',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
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

  void _deleteBatch(BuildContext context, List<Order> batchOrders) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Batch'),
          content: Text('Are you sure you want to delete this batch of ${batchOrders.length} orders?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Store the batch for potential undo
      setState(() {
        _recentlyDeletedBatch = List.from(batchOrders);
        _showUndoButton = false; // Hide any existing undo button
      });

      try {
        for (final order in batchOrders) {
          await context.read<OrderProvider>().removeOrder(order);
        }
        Navigator.of(context).pop(); // Close the batch details dialog

        // Show undo snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Batch deleted successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: _undoDelete,
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        // Show undo button after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _recentlyDeletedBatch != null) {
            setState(() {
              _showUndoButton = true;
            });
          }
        });
      } catch (e) {
        // Clear the stored batch if deletion failed
        setState(() {
          _recentlyDeletedBatch = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting batch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editBatch(BuildContext context, List<Order> batchOrders) {
    Navigator.of(context).pop(); // Close the batch details dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderScreen(batchToEdit: batchOrders),
      ),
    );
  }

  void _saveBatch(BuildContext context, List<Order> batchOrders) {
    // For now, just show a message that the batch is already saved
    // In a real app, you might want to export or save to a file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Batch is already saved in the database'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _undoDelete() async {
    if (_recentlyDeletedBatch == null) return;

    try {
      for (final order in _recentlyDeletedBatch!) {
        await context.read<OrderProvider>().addOrder(order);
      }
      setState(() {
        _recentlyDeletedBatch = null;
        _showUndoButton = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring batch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBatchDetails(BuildContext context, List<Order> batchOrders) {
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
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                    color: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
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
                        shadowColor: const Color(0xFF0651A4).withOpacity(isDarkMode ? 0.5 : 0.2),
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
                                    ).withOpacity(isDarkMode ? 0.3 : 0.1),
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
                                            color: isDarkMode ? Colors.white : Color(0xFF0651A4),
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
                                      color: isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Color(0xFF0651A4).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      'Qty: ${order.quantity}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteBatch(context, batchOrders),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editBatch(context, batchOrders),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveBatch(context, batchOrders),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF0651A4).withOpacity(isDarkMode ? 0.5 : 0.3),
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
