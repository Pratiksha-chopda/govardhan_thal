import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../services/api_service.dart'; // Added import for ApiService
import 'my_reservations_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  int _guestCount = 2;
  String? _selectedOccasion;
  final TextEditingController _specialRequestController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isBooking = false;
  String? _userPhone;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await ApiService.getProfile();
      if ((profile['status'] == 'success' || profile['success'] == true)) {
        _userPhone = profile['data']['mobile'];
        _phoneController.text = _userPhone ?? "";
      }
    } catch (e) {
      debugPrint("Profile load error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  final List<String> _occasions = [
    'Birthday',
    'Anniversary',
    'Business Meeting',
    'Family Dinner',
    'Date Night',
    'Other'
  ];

  final List<String> _lunchSlots = ['12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM', '02:00 PM'];
  final List<String> _dinnerSlots = ['07:00 PM', '07:30 PM', '08:00 PM', '08:30 PM', '09:00 PM', '09:30 PM'];
  final List<String> _bookedSlots = []; // For demo, we can simulate some booked slots

  Future<void> _handleBooking() async {
    if (_selectedTimeSlot == null) {
      scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(content: Text("Please select a time slot!")));
      return;
    }

    // If phone is missing, ensure it's provided now
    if (_userPhone == null || _userPhone!.isEmpty) {
      if (_phoneController.text.trim().isEmpty) {
        scaffoldMessengerKey.currentState!.showSnackBar(
          const SnackBar(content: Text("Please provide your phone number for the reservation.")),
        );
        return;
      }
    }

    setState(() => _isBooking = true);
    HapticFeedback.mediumImpact();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await BookingService.createBooking(
        date: dateStr,
        timeSlot: _selectedTimeSlot!,
        guestCount: _guestCount,
        occasion: _selectedOccasion,
        specialRequest: _specialRequestController.text.trim(),
        mobile: (_userPhone == null || _userPhone!.isEmpty) ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        if ((result['status'] == 'success' || result['success'] == true)) {
          final data = result['data'] ?? {};
          final bookingId = data['booking_id'] ?? data['_id'] ?? 'RES-${DateTime.now().millisecond}';
          _showSuccessDialog(bookingId);
        } else {
          String errorMessage = result['message'] ?? 'Booking failed';
          if (result['errors'] != null && result['errors'] is List) {
            final List errList = result['errors'];
            if (errList.isNotEmpty) {
              errorMessage += ": ${errList.map((e) => e['message']).join(', ')}";
            }
          }
          scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(content: Text("Network Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog(String id) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Success",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 70),
                ),
                const SizedBox(height: 24),
                Text("Booking Requested", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Reservation ID: ", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                      Flexible(
                        child: Text(
                          id, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: const Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFFF6B00), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text("Status: Pending Approval", style: GoogleFonts.poppins(color: const Color(0xFFFF6B00), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Restaurant will confirm shortly.", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyReservationsScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text("View Bookings", style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  child: Text("Back to Home", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 14)),
                )
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => FadeTransition(opacity: anim1, child: ScaleTransition(scale: anim1, child: child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Reserve a Table", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDatePicker(),
            _buildGuestSelector(),
            _buildTimeSlots("Lunch (AM)", _lunchSlots),
            _buildTimeSlots("Dinner (PM)", _dinnerSlots),
            _buildOccasionSelector(),
            _buildSpecialRequest(),
            const SizedBox(height: 140), // Bottom padding
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomSummary(),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("Select Date", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 14,
              itemBuilder: (ctx, i) {
                final date = DateTime.now().add(Duration(days: i));
                final isToday = i == 0;
                final isSelected = DateFormat('yy-MM-dd').format(date) == DateFormat('yy-MM-dd').format(_selectedDate);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = date);
                  },
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 60,
                        height: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade200, width: 1.5),
                          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF6B00).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(DateFormat('EEE').format(date), style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(DateFormat('dd').format(date), style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (isToday)
                        Positioned(
                          top: 4, right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: isSelected ? Colors.white : const Color(0xFFFF6B00), borderRadius: BorderRadius.circular(4)),
                            child: Text("TODAY", style: GoogleFonts.poppins(color: isSelected ? const Color(0xFFFF6B00) : Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Number of Guests", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text("Tell us how many people are coming", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            width: 120,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _guestBtn(Icons.remove, () { if (_guestCount > 1) setState(() => _guestCount--); }),
                Text("$_guestCount", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                _guestBtn(Icons.add, () { setState(() => _guestCount++); }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFFFF6A00), size: 20),
      ),
    );
  }

  Widget _buildTimeSlots(String label, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: slots.length,
          itemBuilder: (ctx, i) {
            final slot = slots[i];
            final isSelected = _selectedTimeSlot == slot;
            final isBooked = _bookedSlots.contains(slot);
            final isUnavailable = false; 

            return GestureDetector(
              onTap: (isBooked || isUnavailable) ? null : () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTimeSlot = slot);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF6B00) : (isBooked || isUnavailable ? Colors.grey.shade100 : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : (isBooked || isUnavailable ? Colors.transparent : Colors.grey.shade200), width: 1.5),
                ),
                child: Center(
                  child: Text(slot, style: GoogleFonts.poppins(color: isSelected ? Colors.white : (isBooked || isUnavailable ? Colors.grey.shade400 : const Color(0xFF1A1A1A)), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14, decoration: (isBooked || isUnavailable) ? TextDecoration.lineThrough : null)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOccasionSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Occasion", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const SizedBox(width: 8),
              Text("(Optional)", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedOccasion,
                isExpanded: true,
                hint: Text("Select an occasion", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                borderRadius: BorderRadius.circular(16),
                items: _occasions.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
                onChanged: (v) => setState(() => _selectedOccasion = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequest() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Any special request?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const SizedBox(width: 8),
              Text("(Optional)", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specialRequestController,
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Decoration, Window seat, Baby chair...",
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    final isValid = _selectedTimeSlot != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isValid) ...[
            if (!_isLoadingProfile && (_userPhone == null || _userPhone!.isEmpty))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFEDD5))),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF9A3412)),
                  decoration: InputDecoration(
                    hintText: "Enter your mobile number",
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFC2410C).withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18, color: Color(0xFFC2410C)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFF6B00).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFFF6B00), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Reservation Summary", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Text(
                          "${DateFormat('dd MMM').format(_selectedDate)}  •  $_selectedTimeSlot  •  $_guestCount Guests",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1A1A1A)),
                        ),
                        Text(
                          "Estimated dining duration: 1.5 hr",
                          style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedOccasion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFF6B00), borderRadius: BorderRadius.circular(8)),
                      child: Text(_selectedOccasion!.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Selected Slot", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(
                      _selectedTimeSlot ?? "Select a time",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: isValid ? const Color(0xFF1A1A1A) : Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isValid ? _handleBooking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    elevation: isValid ? 8 : 0,
                    shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isBooking 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Confirm Booking", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
