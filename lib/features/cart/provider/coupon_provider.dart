import 'package:flutter/material.dart';
import '../../../services/coupon_service.dart';

class CouponProvider extends ChangeNotifier {
  List<dynamic> _availableCoupons = [];
  Map<String, dynamic>? _appliedCoupon;
  double _discountAmount = 0;
  bool _isLoading = false;

  List<dynamic> get availableCoupons => _availableCoupons;
  Map<String, dynamic>? get appliedCoupon => _appliedCoupon;
  double get discountAmount => _discountAmount;
  bool get isLoading => _isLoading;

  Future<void> fetchAvailableCoupons() async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableCoupons = await CouponService.getAvailableCoupons();
    } catch (e) {
      _availableCoupons = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> applyCoupon(String code, double orderAmount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await CouponService.validateCoupon(code, orderAmount);
      if ((res['status'] == 'success' || res['success'] == true)) {
        _appliedCoupon = res['data']['coupon'];
        _discountAmount = (res['data']['discountAmount'] as num).toDouble();
        _isLoading = false;
        notifyListeners();
        return null; // Success
      } else {
        return res['message'] ?? "Invalid coupon code.";
      }
    } catch (e) {
      return e.toString().contains('400') ? e.toString().split(':').last.trim() : "Unable to apply coupon. Please try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _discountAmount = 0;
    notifyListeners();
  }

  void clear() {
    _availableCoupons = [];
    _appliedCoupon = null;
    _discountAmount = 0;
    notifyListeners();
  }
}
