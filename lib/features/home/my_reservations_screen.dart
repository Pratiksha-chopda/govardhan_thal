import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../services/socket_service.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();

    // Real-time sync: refresh list when status updates are emitted
    SocketService().onBookingStatusUpdated = (data) {
      if (mounted) _loadBookings();
    };
  }

  @override
  void dispose() {
    // Clean up socket listener
    SocketService().onBookingStatusUpdated = null;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await BookingService.getBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filterBookings(String type) {
    final now = DateTime.now();
    return _bookings.where((b) {
      final date = DateTime.tryParse(b['bookingDate'] ?? '') ?? now;
      final status = b['status'] ?? 'PENDING';
      
      if (type == 'Upcoming') {
        return status == 'PENDING' || status == 'APPROVED';
      } else if (type == 'Past') {
        return status == 'COMPLETED' || (status == 'APPROVED' && date.isBefore(now.subtract(const Duration(days: 1))));
      } else {
        return status == 'CANCELLED' || status == 'REJECTED';
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text("My Reservations", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6B00),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6B00),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [Tab(text: "Upcoming"), Tab(text: "Past"), Tab(text: "Cancelled")],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList('Upcoming'),
              _buildBookingList('Past'),
              _buildBookingList('Cancelled'),
            ],
          ),
    );
  }

  Widget _buildBookingList(String type) {
    final list = _filterBookings(type);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No $type Reservations", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final b = list[i];
        return _buildBookingCard(b);
      },
    );
  }

  Widget _buildBookingCard(dynamic b) {
    final status = b['status'] ?? 'PENDING';
    final dateStr = b['bookingDate'] ?? '';
    final timeStr = b['timeSlot'] ?? '';
    final guests = b['guestCount'] ?? 0;
    final occasion = b['occasion'];

    Color statusColor;
    switch (status) {
      case 'APPROVED': statusColor = const Color(0xFF22C55E); break;
      case 'PENDING': statusColor = const Color(0xFFFF6B00); break;
      case 'REJECTED': statusColor = const Color(0xFFEF4444); break;
      default: statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  status, 
                  style: GoogleFonts.poppins(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                ),
              ),
              if (occasion != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    occasion.toUpperCase(), 
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, DateFormat('dd MMM, yyyy').format(DateTime.tryParse(dateStr) ?? DateTime.now())),
              _buildInfoItem(Icons.access_time_rounded, timeStr),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.people_outline_rounded, "$guests Guests"),
          if (status == 'PENDING' || status == 'APPROVED') ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    status == 'PENDING' 
                      ? "Waiting for restaurant to confirm..." 
                      : "Booking is confirmed! See you then.",
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic)
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _handleCancel(b['_id']),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                  label: Text("Cancel", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.red.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCancel(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cancel Reservation?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to cancel this booking?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("No", style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Yes, Cancel", style: GoogleFonts.poppins(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await BookingService.cancelBooking(bookingId);
        if (mounted) {
          scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(content: Text("Reservation cancelled successfully")));
          _loadBookings();
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(content: Text("Failed to cancel reservation")));
          _loadBookings();
        }
      }
    }
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF6B00)),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
      ],
    );
  }
}
