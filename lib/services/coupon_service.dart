import '../services/api_service.dart';

class CouponService {
  static Future<List<dynamic>> getAvailableCoupons() async {
    return await ApiService.getAvailableCoupons();
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, double orderAmount) async {
    return await ApiService.validateCoupon(code, orderAmount);
  }
}
