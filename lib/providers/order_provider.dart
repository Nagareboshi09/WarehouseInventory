import 'package:flutter/material.dart';
import 'package:warehouse_inventory/models/order.dart';
import 'package:warehouse_inventory/database/database_helper.dart';

class OrderProvider with ChangeNotifier {
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
      _orders = await DatabaseHelper.instance.getAllOrders();
    } catch (e) {
      print('Error loading orders: $e');
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOrder(Order order) async {
    try {
      final savedOrder = await DatabaseHelper.instance.createOrder(order);
      _orders.add(savedOrder);
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> removeOrder(Order order) async {
    if (order.id != null) {
      try {
        await DatabaseHelper.instance.deleteOrder(order.id!);
        _orders.remove(order);
        notifyListeners();
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> clearOrders() async {
    try {
      for (final order in _orders) {
        if (order.id != null) {
          await DatabaseHelper.instance.deleteOrder(order.id!);
        }
      }
      _orders.clear();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<List<Order>> getOrdersByBranch(int branchId) async {
    try {
      return await DatabaseHelper.instance.getOrdersByBranch(branchId);
    } catch (e) {
      return [];
    }
  }
}