import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/app_database.dart';

class OrderProvider with ChangeNotifier {
  static const String _tag = 'OrderProvider';
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await AppDatabase.instance.getAllOrders();
    } catch (e) {
      developer.log('Error loading orders from database',
          error: e.toString(),
          stackTrace: StackTrace.current,
          name: _tag);
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOrder(Order order) async {
    try {
      await AppDatabase.instance.insertOrder(order);
      
      // Reload orders from database
      await loadOrders();
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeOrder(Order order) async {
    await AppDatabase.instance.deleteOrder(order.id);
    await loadOrders(); // Reload orders from database
    notifyListeners();
  }

  Future<void> clearOrders() async {
    try {
      for (final order in _orders) {
        await AppDatabase.instance.deleteOrder(order.id);
      }
      await loadOrders(); // Reload orders from database
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<List<Order>> getOrdersByBranch(int branchId) async {
    try {
      return await AppDatabase.instance.getOrdersByBranch(branchId);
    } catch (e) {
      return [];
    }
  }
}