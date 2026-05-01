import 'package:flutter/material.dart';
import '../../../services/order_service.dart';
import '../../../services/socket_service.dart';
import '../../../core/globals.dart'; // To access the scaffoldMessengerKey

class OrderProvider extends ChangeNotifier {
  List<dynamic> _orders = [];
  bool _isLoading = false;

  OrderProvider() {
    SocketService().onOrderStatusUpdated = (order, message) {
      if (message != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      fetchOrders();
    };

    SocketService().onDiningOrderStatusUpdated = (order, message) {
      if (message != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      fetchOrders();
    };
  }

  List<dynamic> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await OrderService.getOrders(status: status);
    } catch (e) {
      _orders = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    try {
      final order = await OrderService.getOrderDetail(orderId);
      return order;
    } catch (e) {
      return null;
    }
  }
}
