import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';

/// ─────────────────────────────────────────────────────────────
/// RazorpayService — Handles Razorpay checkout for Online & Takeaway orders.
///
/// Flow:
///   1. Backend creates a Razorpay order → returns order_id + key_id
///   2. Razorpay SDK opens the native checkout (UPI, Card, Net Banking)
///   3. On success → backend verifies the payment signature
///   4. Returns transactionId to the caller
/// ─────────────────────────────────────────────────────────────
class RazorpayService {
  static Razorpay? _razorpay;

  /// Opens Razorpay checkout for the given amount.
  /// [amount] — Amount in INR (e.g., 450.0)
  /// [userName] — Customer's name (shown on checkout)
  /// [userEmail] — Customer's email
  /// [userPhone] — Customer's phone number
  /// [onSuccess] — Called with the verified transactionId
  /// [onFailure] — Called with an error message
  static Future<void> openCheckout({
    required double amount,
    required String userName,
    required String userEmail,
    required String userPhone,
    required Function(String transactionId) onSuccess,
    required Function(String errorMessage) onFailure,
  }) async {
    try {
      // Step 1: Create order on backend
      final orderData = await ApiService.createRazorpayOrder(amount);

      if (orderData['success'] != true) {
        onFailure(orderData['message'] ?? 'Failed to create payment order');
        return;
      }

      final String orderId = orderData['order_id'];
      final String keyId = orderData['key_id'];

      // Step 2: Initialize Razorpay
      _razorpay?.clear();
      _razorpay = Razorpay();

      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        debugPrint('[Razorpay] Payment Success: ${response.paymentId}');

        // Step 3: Verify on backend
        final verifyResult = await ApiService.verifyRazorpayPayment(
          orderId: response.orderId ?? orderId,
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
        );

        if (verifyResult['success'] == true) {
          onSuccess(verifyResult['transaction_id'] ?? response.paymentId ?? '');
        } else {
          onFailure(verifyResult['message'] ?? 'Payment verification failed');
        }

        _razorpay?.clear();
      });

      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        debugPrint('[Razorpay] Payment Error: ${response.code} - ${response.message}');
        onFailure(response.message ?? 'Payment was cancelled or failed');
        _razorpay?.clear();
      });

      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        debugPrint('[Razorpay] External Wallet: ${response.walletName}');
        // External wallets (e.g., Paytm wallet) — treat as pending
        onFailure('External wallet selected. Please complete payment in the ${response.walletName} app.');
        _razorpay?.clear();
      });

      // Step 4: Open Razorpay native checkout
      final options = {
        'key': keyId,
        'amount': orderData['amount'], // Already in paise from backend
        'currency': orderData['currency'] ?? 'INR',
        'order_id': orderId,
        'name': 'Govardhan Thal',
        'description': 'Food Order Payment',
        'prefill': {
          'name': userName,
          'email': userEmail,
          'contact': userPhone,
        },
        'theme': {
          'color': '#FF6A00', // Govardhan Thal orange
        },
        'modal': {
          'confirm_close': true,
        },
        // ── Payment Methods Enabled ──
        'method': {
          'upi': true,       // ✅ Google Pay, PhonePe, Paytm, BHIM
          'card': true,      // ✅ Debit & Credit Cards
          'netbanking': true, // ✅ All Banks
          'wallet': true,    // ✅ Paytm Wallet, Amazon Pay, etc.
          'paylater': true,  // ✅ Pay Later options
        },
      };

      _razorpay!.open(options);
    } catch (e) {
      debugPrint('[Razorpay] Error: $e');
      onFailure('Something went wrong. Please try again.');
    }
  }

  /// Dispose Razorpay instance (call when the screen is disposed)
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
