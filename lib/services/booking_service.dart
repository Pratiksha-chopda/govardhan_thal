import 'api_service.dart';

/// ─────────────────────────────────────────────────────────────
/// BookingService — Production Service Layer for Table Booking.
/// ─────────────────────────────────────────────────────────────
class BookingService {
  static Future<Map<String, dynamic>> createBooking({
    required String date,
    required String timeSlot,
    required int guestCount,
    String? occasion,
    String? specialRequest,
    String? mobile,
  }) async {
    return await ApiService.createBooking(
      date: date,
      timeSlot: timeSlot,
      guestCount: guestCount,
      occasion: occasion,
      specialRequest: specialRequest,
      mobile: mobile,
    );
  }

  static Future<List<dynamic>> getBookings() async {
    return await ApiService.getBookings();
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    return await ApiService.cancelBooking(bookingId);
  }
}
