import 'api_service.dart';

/// ─────────────────────────────────────────────────────────────
/// OrderService — Production Service Layer for Order operations.
/// Depends on ApiService for authenticated requests.
/// ─────────────────────────────────────────────────────────────
class OrderService {
  static Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    String orderType = 'ONLINE',
    String? tableId,
    String paymentMethod = 'UPI',
    Map<String, dynamic>? deliveryAddress,
    String? addressId,
    double discountAmount = 0,
    String? couponCode,
    double deliveryFee = 0,
    double gst = 0,
  }) async {
    return await ApiService.placeOrder(
      items: items,
      orderType: orderType,
      tableId: tableId,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      addressId: addressId,
      discountAmount: discountAmount,
      couponCode: couponCode,
      deliveryFee: deliveryFee,
      gst: gst,
    );
  }

  static Future<Map<String, dynamic>> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? paymentMethod,
    String? transactionId,
  }) async {
    return await ApiService.updatePaymentStatus(
      orderId: orderId,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
    );
  }

  static Future<List<dynamic>> getOrders({String? status}) async {
    return await ApiService.getOrders(status: status);
  }

  static Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    return await ApiService.getOrderDetail(orderId);
  }
}
