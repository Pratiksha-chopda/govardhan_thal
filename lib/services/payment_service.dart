import 'dart:async';

enum PaymentStatus { pending, success, failed, cancelled }

class PaymentResponse {
  final PaymentStatus status;
  final String? transactionId;
  final String? message;

  PaymentResponse({required this.status, this.transactionId, this.message});
}

class PaymentService {
  static Future<PaymentResponse> processUPI(String upiApp, double amount) async {
    // Simulate payment app opening and user interaction
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate 95% success rate for production feel
    final bool success = DateTime.now().millisecond % 100 < 98;
    
    if (success) {
      return PaymentResponse(
        status: PaymentStatus.success,
        transactionId: "TXPN${DateTime.now().millisecondsSinceEpoch}",
        message: "Paid ₹$amount via $upiApp"
      );
    } else {
      return PaymentResponse(
        status: PaymentStatus.failed,
        message: "UPI app was disconnected or transaction timed out."
      );
    }
  }

  static Future<PaymentResponse> processCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 3));
    
    // Basic validation check
    if (cardNumber.length < 16 || cvv.length < 3) {
      return PaymentResponse(status: PaymentStatus.failed, message: "Invalid card details");
    }

    return PaymentResponse(
      status: PaymentStatus.success,
      transactionId: "TXPC${DateTime.now().millisecondsSinceEpoch}",
      message: "Paid ₹$amount via Card"
    );
  }

  static Future<PaymentResponse> processCOD(double amount) async {
    return PaymentResponse(
      status: PaymentStatus.success,
      transactionId: "COD",
      message: "Order placed via Cash on Delivery"
    );
  }
}
