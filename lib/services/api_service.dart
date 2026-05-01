import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'token_manager.dart';

/// ─────────────────────────────────────────────────────────────
/// ApiService — Central API client for all backend communication.
///
/// Features:
///   • Auto-attaches JWT Authorization header
///   • Auto-refreshes expired tokens (401 → retry)
///   • Uses /api/v1/ base URL
///   • All IDs are String (MongoDB ObjectId)
/// ─────────────────────────────────────────────────────────────
class ApiService {
  /// ⚠️ Change this to your computer's local IPv4 address when debugging on physical mobile devices
  static const String backendIp = '10.54.30.101'; // Target computer's Wi-Fi IP for physical devices

  /// 🌐 Set this to true and provide your Render.com URL to go production-ready!
  static const bool isProduction = false;
  static const String productionUrl =
      'https://your-govardhan-backend.onrender.com';

  static String get baseUrl => isProduction
      ? '$productionUrl/api/v1'
      : (kIsWeb
          ? 'http://localhost:3000/api/v1'
          : 'http://$backendIp:3000/api/v1');

  static String get imgHost => isProduction
      ? productionUrl
      : (kIsWeb ? 'http://localhost:3000' : 'http://$backendIp:3000');

  // ══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════

  /// Build headers with JWT token attached
  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenManager.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Auto-refresh logic: if response is 401, try refreshing the token
  /// and retry the request once.
  static Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _authHeaders();
    var response = await request(headers);

    // If 401, try refreshing the token
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _authHeaders();
        response = await request(headers); // Retry with new token
      }
    }

    return response;
  }

  /// Attempt to refresh the access token
  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          await TokenManager.saveTokens(
            accessToken: data['data']['accessToken'],
            refreshToken: data['data']['refreshToken'],
          );
          return true;
        }
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        // Refresh token itself is invalid or expired — clear everything
        await TokenManager.clearAll();
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════════
  // 1. AUTHENTICATION
  // ══════════════════════════════════════════════════════════════

  /// Firebase Google Login
  static Future<Map<String, dynamic>> firebaseLogin({
    required String firebaseUID,
    required String email,
    required String name,
    required String profileImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseUID': firebaseUID,
          'email': email,
          'name': name,
          'profileImage': profileImage,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  /// Mobile Login
  static Future<Map<String, dynamic>> login(
      String mobile, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  /// Register
  static Future<Map<String, dynamic>> register(
      String name, String email, String mobile, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'mobile': mobile,
          'password': password
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  /// Admin Login
  static Future<Map<String, dynamic>> adminLogin(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error. Check connection.'};
    }
  }

  /// Forgot Password
  static Future<Map<String, dynamic>> forgotPassword(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  /// Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  /// Reset Password (Email OTP Fallback)
  static Future<Map<String, dynamic>> resetPassword(String mobile, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp, 'newPassword': newPassword}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  /// Reset Password (Firebase Phone Auth)
  static Future<Map<String, dynamic>> resetPasswordFirebase(String mobile, String newPassword, String firebaseUID) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password-firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'newPassword': newPassword, 'firebaseUID': firebaseUID}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 2. MENU
  // ══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getMenu(
      {String? category, String? search}) async {
    try {
      final params = <String, String>{};
      if (category != null) params['category'] = category;
      if (search != null) params['search'] = search;

      final uri = Uri.parse('$baseUrl/menu')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] ?? [];
        return data.map((item) {
          for (var key in ['image', 'image_url', 'imageUrl']) {
            if (item[key] != null && item[key].toString().startsWith('/')) {
              item[key] = '$imgHost${item[key]}';
            }
          }
          return item;
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Menu fetch error: $e');
      return [];
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu/categories'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 2B. MENU - ADMIN OPERATIONS
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createMenu(
      Map<String, dynamic> data) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/menu'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateMenu(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/menu/$id'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> deleteMenu(String id) async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.delete(Uri.parse('$baseUrl/menu/$id'), headers: headers),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 3. CART (Authenticated)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/cart'), headers: headers),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] ?? {};
        final items = (data['items'] as List? ?? []).map((item) {
          // Prepend imgHost if image or image_url starts with /
          for (var key in ['image', 'image_url']) {
            if (item[key] != null && item[key].toString().startsWith('/')) {
              item[key] = '$imgHost${item[key]}';
            }
          }
          return item;
        }).toList();
        data['items'] = items;
        return data;
      }
      return {'items': [], 'totalPrice': 0};
    } catch (e) {
      return {'items': [], 'totalPrice': 0};
    }
  }

  static Future<bool> addToCart(String menuId, int quantity) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/cart/add'),
          headers: headers,
          body: jsonEncode({
            'menuId': menuId,
            'menu_id': menuId, // Support both formats
            'quantity': quantity,
          }),
        ),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFromCart(String menuId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.delete(Uri.parse('$baseUrl/cart/item/$menuId'),
            headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateCartQuantity(String menuId, int quantity) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/cart/item/$menuId'),
          headers: headers,
          body: jsonEncode({'quantity': quantity}),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearCart() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.delete(Uri.parse('$baseUrl/cart'), headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 4. ORDERS (Authenticated)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    String orderType = 'ONLINE',
    String? tableId,
    String paymentMethod = 'UPI',
    String? paymentStatus,
    String? transactionId,
    String? addressId,
    Map<String, dynamic>? deliveryAddress,
    double discountAmount = 0,
    String? couponCode,
    double deliveryFee = 0,
    double gst = 0,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/orders'),
          headers: headers,
          body: jsonEncode({
            'items': items,
            'orderType': orderType,
            'paymentMethod': paymentMethod,
            if (paymentStatus != null) 'paymentStatus': paymentStatus,
            if (transactionId != null) 'transactionId': transactionId,
            'discountAmount': discountAmount,
            if (couponCode != null) 'couponCode': couponCode,
            'deliveryFee': deliveryFee,
            'gst': gst,
            if (addressId != null) 'addressId': addressId,
            if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
            if (tableId != null) 'tableId': tableId,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  /// Update payment status after successful transaction (S2 Fix)
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/orders/update-payment'),
          headers: headers,
          body: jsonEncode({
            'orderId': orderId,
            'paymentStatus': paymentStatus,
            'paymentMethod': paymentMethod,
            'transactionId': transactionId,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to sync payment status.'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 4B. COUPONS (S3-S7)
  // ══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getAvailableCoupons() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/coupons/available'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, double orderAmount) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/coupons/validate'),
          headers: headers,
          body: jsonEncode({'code': code, 'orderAmount': orderAmount}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<List<dynamic>> getOrders({String? status}) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;

      final uri = Uri.parse('$baseUrl/orders')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await _authenticatedRequest(
        (headers) => http.get(uri, headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.get(Uri.parse('$baseUrl/orders/$orderId'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Order not found'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ENHANCED ORDER FLOWS (S2 Professional Pipeline)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> cancelOrder(String orderId, {String? reason}) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.patch(
          Uri.parse('$baseUrl/order-enhanced/$orderId/cancel'),
          headers: headers,
          body: jsonEncode({'reason': reason}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/order-enhanced/$orderId/tracking'), headers: headers),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> submitRating(String orderId, int rating, {String? review}) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/order-enhanced/$orderId/rating'),
          headers: headers,
          body: jsonEncode({'rating': rating, 'review': review}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> submitComplaint(String orderId, String issueType, {String? description}) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/order-enhanced/$orderId/complaint'),
          headers: headers,
          body: jsonEncode({'issueType': issueType, 'description': description}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> reorder(String orderId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/order-enhanced/$orderId/reorder'),
          headers: headers,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> getDeliveryFee(String addressId, double subtotal) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(
          Uri.parse('$baseUrl/orders/calculate/delivery-fee?addressId=$addressId&subtotal=$subtotal'),
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
         return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to calculate fee'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // (Admin order methods moved to ADMIN APIs section below)

  // ══════════════════════════════════════════════════════════════
  // 5. BOOKINGS (Authenticated)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createBooking({
    required String date,
    required String timeSlot,
    required int guestCount,
    String? occasion,
    String? specialRequest,
    String? mobile,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/bookings'),
          headers: headers,
          body: jsonEncode({
            'date': date,
            'timeSlot': timeSlot,
            'guestCount': guestCount,
            if (occasion != null) 'occasion': occasion,
            if (specialRequest != null) 'specialRequest': specialRequest,
            if (mobile != null) 'mobile': mobile,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<List<dynamic>> getBookings() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/bookings'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/bookings/cancel/$bookingId'),
          headers: headers,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 6. DINING (Complete Table QR Flow)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> verifyTable(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dining/verify-table'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qrCode': qrCode}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to connect to server. Please check your internet.'};
    }
  }

  static Future<Map<String, dynamic>> startDiningSession(String tableId, {bool confirmSwitch = false}) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/dining/start-session'),
          headers: headers,
          body: jsonEncode({'tableId': tableId, 'confirmSwitch': confirmSwitch}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Place a dining order attached to the active session
  static Future<Map<String, dynamic>> placeDiningOrder({
    required String sessionId,
    required String tableId,
    required List<Map<String, dynamic>> items,
    String? couponCode,
    double? discountAmount,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/dining/order'),
          headers: headers,
          body: jsonEncode({
            'sessionId': sessionId,
            'tableId': tableId,
            'items': items,
            if (couponCode != null) 'couponCode': couponCode,
            if (discountAmount != null) 'discountAmount': discountAmount,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Get dining session with all orders
  static Future<Map<String, dynamic>> getDiningSession(String sessionId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(
          Uri.parse('$baseUrl/dining/session/$sessionId'),
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'Session not found'};
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  /// Get full bill for a session (subtotal + GST + total)
  static Future<Map<String, dynamic>> getDiningBill(String sessionId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(
          Uri.parse('$baseUrl/dining/bill/$sessionId'),
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'Bill not found'};
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  /// Section 8: "REQUEST BILL" - Set status to WAITING_PAYMENT
  static Future<Map<String, dynamic>> requestDiningBill({
    required String sessionId,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/dining/request-bill'),
          headers: headers,
          body: jsonEncode({
            'sessionId': sessionId,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  /// Alias for compatibility
  static Future<Map<String, dynamic>> submitDiningPayment({
    required String sessionId,
    required String paymentMethod,
    String? transactionId,
  }) async {
    return requestDiningBill(sessionId: sessionId);
  }

  /// Alias for submitDiningPayment to match UI usage
  static Future<Map<String, dynamic>> payDiningBill({
    required String sessionId,
    required String paymentMethod,
    String? transactionId,
  }) async {
    return submitDiningPayment(
      sessionId: sessionId,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
    );
  }

  static Future<Map<String, dynamic>> getActiveDiningSession() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/dining/active-session'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'No active session'};
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  /// Close dining session and free the table
  static Future<Map<String, dynamic>> closeDiningSession(
      String sessionId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/dining/close-session'),
          headers: headers,
          body: jsonEncode({'sessionId': sessionId}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 7. PAYMENT (Mock)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> processPayment(
      double amount, String paymentMethod) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/payment/process'),
          headers: headers,
          body: jsonEncode({'amount': amount, 'payment_method': paymentMethod}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Payment Gateway Network Error.'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 7B. RAZORPAY PAYMENT GATEWAY
  // ══════════════════════════════════════════════════════════════

  /// Create a Razorpay order on the backend (returns order_id + key_id)
  static Future<Map<String, dynamic>> createRazorpayOrder(double amount) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/razorpay/create-order'),
          headers: headers,
          body: jsonEncode({'amount': amount}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create payment order.'};
    }
  }

  /// Verify Razorpay payment signature on the backend
  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/razorpay/verify-payment'),
          headers: headers,
          body: jsonEncode({
            'razorpay_order_id': orderId,
            'razorpay_payment_id': paymentId,
            'razorpay_signature': signature,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Payment verification failed.'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 8. PROFILE (Authenticated)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = await TokenManager.getUserId();
      if (userId == null) {
        return {'status': 'error', 'message': 'Not logged in'};
      }

      final response = await _authenticatedRequest(
        (headers) =>
            http.get(Uri.parse('$baseUrl/profile/$userId'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'Profile not found'};
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      String name, String email, String mobile) async {
    try {
      final userId = await TokenManager.getUserId();
      if (userId == null) {
        return {'status': 'error', 'message': 'Not logged in'};
      }

      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/profile/$userId'),
          headers: headers,
          body: jsonEncode({'name': name, 'email': email, 'mobile': mobile}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  /// Delete Account — permanently removes user and all associated data
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.delete(
          Uri.parse('$baseUrl/profile/delete-account'),
          headers: headers,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 9. SETTINGS & ADDRESSES (Authenticated)
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSettings(int userId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/settings'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'Settings not found'};
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateSettings(
      int userId, bool notif, bool orders, bool promo) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/settings'),
          headers: headers,
          body: jsonEncode({
            'notifications_enabled': notif,
            'order_updates': orders,
            'promotions': promo
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<List<dynamic>> getAddresses(String userId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.get(Uri.parse('$baseUrl/addresses/$userId'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addAddress({
    required String userId,
    required String label,
    required String houseNo,
    required String street,
    required String area,
    required String city,
    required String pincode,
    String? landmark,
    double? latitude,
    double? longitude,
    required bool isDefault,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/addresses'),
          headers: headers,
          body: jsonEncode({
            'user_id': userId,
            'label': label,
            'house': houseNo,
            'street': street,
            'area': area,
            'city': city,
            'pincode': pincode,
            'landmark': landmark,
            'latitude': latitude,
            'longitude': longitude,
            'is_default': isDefault,
            'type': label,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String userId,
    required String label,
    required String houseNo,
    required String street,
    required String area,
    required String city,
    required String pincode,
    String? landmark,
    double? latitude,
    double? longitude,
    required bool isDefault,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/addresses/$addressId'),
          headers: headers,
          body: jsonEncode({
            'user_id': userId,
            'label': label,
            'house': houseNo,
            'street': street,
            'area': area,
            'city': city,
            'pincode': pincode,
            'landmark': landmark,
            'latitude': latitude,
            'longitude': longitude,
            'is_default': isDefault,
            'type': label,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.delete(Uri.parse('$baseUrl/address/$addressId'),
            headers: headers),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> setDefaultAddress(
      String addressId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.patch(
          Uri.parse('$baseUrl/address/$addressId/default'),
          headers: headers,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BACKWARD COMPATIBILITY HELPERS
  // ══════════════════════════════════════════════════════════════

  static Future<void> saveUserSession(
      Map<String, dynamic> user, String token) async {
    await TokenManager.saveSession(
      accessToken: token,
      refreshToken: '',
      user: user,
    );
  }

  static Future<String?> getStoredUserId() async {
    return TokenManager.getUserId();
  }

  static Future<void> clearSession() async {
    await TokenManager.clearAll();
  }

  // ────────────────────────────────────────────────────────────
  // WISHLIST
  // ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> toggleWishlist(String menuId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(Uri.parse('$baseUrl/profile/wishlist/$menuId'),
            headers: headers),
      );
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Wishlist toggle error: $e');
    }
  }

  static Future<List<dynamic>> getWishlist() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/profile/wishlist/all'),
            headers: headers),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] ?? [];
        return (data as List).map((item) {
          if (item['image_url'] != null &&
              item['image_url'].toString().startsWith('/')) {
            item['image_url'] = '$imgHost${item['image_url']}';
          }
          return item;
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Get wishlist error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ADMIN APIs
  // ══════════════════════════════════════════════════════════════

  /// Admin Dashboard
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.get(Uri.parse('$baseUrl/admin/dashboard'), headers: headers),
      );
      final body = jsonDecode(response.body);
      return body['data'] ?? {};
    } catch (e) {
      debugPrint('Admin dashboard error: $e');
      return {};
    }
  }

  /// Admin: Get all menu items (including deleted ones for admin view)
  static Future<List<dynamic>> getAdminMenu() async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.get(Uri.parse('$baseUrl/menu?limit=200'), headers: headers),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data'] ?? [];
        return (items as List).map((item) {
          if (item['image_url'] != null &&
              item['image_url'].toString().startsWith('/')) {
            item['image_url'] = '$imgHost${item['image_url']}';
          }
          return item;
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin: Create menu item
  static Future<bool> createMenuItem(Map<String, dynamic> data) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/admin/menu'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Update menu item
  static Future<bool> updateMenuItem(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/admin/menu/$id'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Delete menu item
  static Future<bool> deleteMenuItem(String id) async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.delete(Uri.parse('$baseUrl/admin/menu/$id'), headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Get all orders
  static Future<List<dynamic>> getAdminOrders({String? status}) async {
    try {
      final query = status != null ? '?status=$status' : '';
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/admin/orders$query'),
            headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin: Update order status
  static Future<bool> updateOrderStatus(String orderId, String status,
      {String? note}) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/admin/orders/$orderId/status'),
          headers: headers,
          body: jsonEncode({'status': status, 'note': note ?? ''}),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Get all bookings
  static Future<List<dynamic>> getAdminBookings() async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.get(Uri.parse('$baseUrl/admin/bookings'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin: Update booking status (APPROVED, REJECTED, CANCELLED)
  static Future<bool> updateBookingStatus(
      String bookingId, String status) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/admin/bookings/$bookingId/status'),
          headers: headers,
          body: jsonEncode({'status': status}),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Get all tables
  static Future<List<dynamic>> getAdminTables() async {
    try {
      final response = await _authenticatedRequest(
        (headers) =>
            http.get(Uri.parse('$baseUrl/admin/tables'), headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin: Create table
  static Future<bool> createTable(Map<String, dynamic> data) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/admin/tables'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Update table
  static Future<bool> updateTable(String id, Map<String, dynamic> data) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/admin/tables/$id'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Delete table
  static Future<bool> deleteTable(String id) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.delete(Uri.parse('$baseUrl/admin/tables/$id'),
            headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Get all users
  static Future<List<dynamic>> getAdminUsers(
      {int page = 1, int limit = 50}) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(
            Uri.parse('$baseUrl/admin/users?page=$page&limit=$limit'),
            headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Admin Dining ──

  /// Admin: Get occupied tables with active sessions
  static Future<List<dynamic>> getAdminActiveTables() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/admin/active-tables'),
            headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin: Get all dining sessions (optionally filtered by status)
  static Future<List<dynamic>> getAdminDiningSessions({String? status}) async {
    try {
      final q = status != null ? '?status=$status' : '';
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/admin/dining-sessions$q'),
            headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin: Get all dining orders
  static Future<List<dynamic>> getAdminDiningOrders({String? status}) async {
    try {
      final q = status != null ? '?status=$status' : '';
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse('$baseUrl/admin/dining-orders$q'),
            headers: headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin: Update dining order status
  static Future<bool> updateAdminDiningOrderStatus(
      String orderId, String status,
      {String? note}) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.put(
          Uri.parse('$baseUrl/admin/dining-orders/$orderId/status'),
          headers: headers,
          body: jsonEncode({'status': status, 'note': note ?? ''}),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Force-close a dining session
  static Future<bool> adminCloseDiningSession(String sessionId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.post(
          Uri.parse('$baseUrl/admin/dining/close-session'),
          headers: headers,
          body: jsonEncode({'sessionId': sessionId}),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
