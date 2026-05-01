import 'dart:async';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../cart/provider/coupon_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';



/// DiningBillScreen — Shows itemised bill with GST, subtotal, and total.
/// Customer can proceed to payment or place more orders.
/// Real-time: Socket notifies when admin confirms/prepares orders.
class DiningBillScreen extends StatefulWidget {
  final String sessionId;
  final String tableNumber;

  const DiningBillScreen({
    super.key,
    required this.sessionId,
    required this.tableNumber,
  });

  @override
  State<DiningBillScreen> createState() => _DiningBillScreenState();
}

class _DiningBillScreenState extends State<DiningBillScreen> {
  Map<String, dynamic>? _bill;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchBill();
    _setupSocketListeners();
    _startPolling();
    _saveSessionToLocal();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isLoading) {
        _fetchBill(isBackground: true);
      }
    });
  }

  Future<void> _saveSessionToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_session_id', widget.sessionId);
    await prefs.setString('table_id', widget.tableNumber); // Assuming tableNumber is the identifier needed
  }


  void _setupSocketListeners() {
    // When admin updates dining order status, show notification & refresh
    SocketService().onDiningOrderStatusUpdated = (order, message) {
      if (!mounted) return;
      final status = order?['orderStatus'] ?? '';
      final statusMsg = message ?? 'Order status updated to $status';
      _showStatusNotification(status, statusMsg);
      _fetchBill(); // Auto-refresh bill to show updated statuses
    };

    // When session is closed by admin
    SocketService().onDiningSessionClosed = (session) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text('Session closed by restaurant. Thank you!',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      _fetchBill();
    };
  }

  void _showStatusNotification(String status, String message) {
    Color bgColor;
    IconData icon;
    switch (status) {
      case 'CONFIRMED':
        bgColor = Colors.indigo.shade700;
        icon = Icons.check_circle;
        break;
      case 'PREPARING':
        bgColor = Colors.orange.shade700;
        icon = Icons.soup_kitchen;
        break;
      case 'READY':
        bgColor = Colors.purple.shade700;
        icon = Icons.local_dining;
        break;
      case 'SERVED':
        bgColor = Colors.teal.shade700;
        icon = Icons.check;
        break;
      case 'COMPLETED':
        bgColor = Colors.green.shade700;
        icon = Icons.done_all;
        break;
      default:
        bgColor = Colors.blueGrey.shade700;
        icon = Icons.info_outline;
    }
    scaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    // Clear dining order listeners when leaving this screen
    SocketService().onDiningOrderStatusUpdated = null;
    SocketService().onDiningSessionClosed = null;
    super.dispose();
  }

  Future<void> _fetchBill({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() { _isLoading = true; _error = null; });
    }
    final res = await ApiService.getDiningBill(widget.sessionId);
    if (!mounted) return;
    if (res['status'] == 'success' || res['success'] == true) {
      setState(() { _bill = res['data']; _isLoading = false; });
    } else {
      if (!isBackground) {
        setState(() { _error = res['message'] ?? 'Failed to load bill'; _isLoading = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('Table #${widget.tableNumber} — Bill',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF6A00)),
            onPressed: _fetchBill,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)))
          : _error != null
              ? _buildError()
              : _buildBill(),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 56),
        const SizedBox(height: 12),
        Text(_error!, style: GoogleFonts.poppins(fontSize: 16, color: Colors.red)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchBill,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6A00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _buildBill() {
    final bill      = _bill!;
    final orders    = (bill['orders'] as List? ?? []);
    final subtotal  = (bill['subtotal'] as num? ?? 0).toDouble();
    final gstPct    = (bill['gst_percent'] as num? ?? 5).toDouble();
    final gstAmt    = (bill['gst_amount'] as num? ?? 0).toDouble();
    final total     = (bill['total'] as num? ?? 0).toDouble();
    final isPaid    = bill['payment_status'] == 'PAID';
    final isClosed  = bill['session_status'] == 'CLOSED';

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFEE0979)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Govardhan Thal', 
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Table #${widget.tableNumber}', 
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isPaid || bill['session_status'] == 'PAID_WAITING_EXIT')
                    _buildStatusChip('PAID', Colors.green.shade700)
                  else if (orders.any((o) => o['orderStatus'] == 'WAITING_PAYMENT'))
                    _buildStatusChip('WAITING', Colors.purple.shade700)
                  else if (orders.any((o) => o['orderStatus'] == 'SERVED'))
                    _buildStatusChip('SERVED', Colors.teal.shade700)
                  else if (orders.any((o) => o['orderStatus'] == 'READY'))
                    _buildStatusChip('READY', Colors.purple.shade700)
                ],

              ),
            ),

            const SizedBox(height: 20),

            // Orders breakdown
            ...orders.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final order = entry.value as Map<String, dynamic>;
              final orderItems = (order['items'] as List? ?? []);
              return _buildOrderCard(i, order, orderItems);
            }),

            const SizedBox(height: 12),

            // Apply Coupon Section
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Consumer<CouponProvider>(
                builder: (context, cp, _) {
                  final applied = cp.appliedCoupon;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: applied != null ? Colors.green.shade200 : Colors.transparent),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: (applied != null ? Colors.green : Colors.amber).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.confirmation_num, color: applied != null ? Colors.green : Colors.amber.shade800, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(applied != null ? "Coupon Applied: ${applied['code']}" : "Have a coupon?", 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: applied != null ? Colors.green.shade800 : Colors.black87)),
                              Text(applied != null ? "₹${cp.discountAmount.toStringAsFixed(0)} saved on this bill" : "Apply to get discount on your bill", 
                                style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (applied != null)
                          IconButton(onPressed: () => cp.removeCoupon(), icon: const Icon(Icons.cancel, color: Colors.grey, size: 20))
                        else
                          TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _DiningCouponSheet(subtotal: subtotal),
                              );
                            }, 
                            child: Text("APPLY", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFFF6A00)))
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bill summary
            Consumer<CouponProvider>(
              builder: (context, cp, _) {
                final discount = cp.discountAmount;
                final finalTotal = total - discount;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bill Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      _billRow('Item Total', '₹${subtotal.toStringAsFixed(0)}'),
                      _billRow('GST (${gstPct.toStringAsFixed(0)}%)', '₹${gstAmt.toStringAsFixed(0)}'),
                      if (discount > 0)
                        _billRow('Discount', '-₹${discount.toStringAsFixed(0)}', accent: true),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(thickness: 1),
                      ),
                      _billRow('Total Amount', '₹${finalTotal.toStringAsFixed(0)}', bold: true, accent: true),
                    ],
                  ),
                );
              },
            ),
            if (isPaid) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Payment received via ${bill['payment_method'] ?? 'Counter'}',
                          style: GoogleFonts.poppins(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        // Bottom action area (MODIFIED FOR MODEL-2)
        if (!isPaid && !isClosed)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Consumer<CouponProvider>(
                builder: (context, cp, _) {
                  final isWaiting = orders.any((o) => o['orderStatus'] == 'WAITING_PAYMENT');
                  final hasServed = orders.any((o) => o['orderStatus'] == 'SERVED');
                  
                  if (isWaiting) {
                    return _buildWaitingArea();
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: Text('Add More', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6A00),
                            side: const BorderSide(color: Color(0xFFFF6A00)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (hasServed)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _requestBill,
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: Text('Request Bill',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

        // Paid: show message (MODIFIED FOR MODEL-2)
        if (isPaid && !isClosed)
           Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildPostPaymentArea(),
          ),
      ],
    );
  }

  Widget _buildOrderCard(int index, Map<String, dynamic> order, List items) {
    final status     = order['orderStatus'] ?? 'PLACED';
    final payStatus  = order['paymentStatus'] ?? 'PENDING';
    final orderTotal = (order['totalAmount'] as num? ?? 0).toDouble();
    final statusColor = _statusColor(status);
    final timeStr    = _formatTime(order['createdAt']);
    final isPaid     = payStatus == 'SUCCESS' || payStatus == 'PAID';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order $index ${timeStr.isNotEmpty ? '($timeStr)' : ''}', 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isPaid || status == 'CANCELLED' || status == 'COMPLETED')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: (isPaid ? Colors.green : statusColor).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(isPaid ? 'PAID' : status, 
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : statusColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

              ],
            ),
          ),
          if (status != 'CANCELLED' && status != 'COMPLETED')
            _buildOrderTimeline(status),
          const Divider(height: 0, thickness: 0.5),
          // Items
          ...items.map((item) {
            final qty   = (item['quantity'] as num? ?? 1).toInt();
            final price = (item['price'] as num? ?? 0).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Text('$qty×', style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item['name'] ?? '', style: GoogleFonts.poppins(fontSize: 13))),
                  Text('₹${(price * qty).toStringAsFixed(0)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            );
          }),
          const Divider(height: 0, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Order Total: ', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
                Text('₹${orderTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false, bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.poppins(
                color: bold ? Colors.black87 : Colors.grey.shade600,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontSize: bold ? 16 : 14)),
          ),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.poppins(
              color: accent ? const Color(0xFFFF6A00) : Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 16 : 14)),
        ],
      ),
    );

  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PLACED':          return Colors.blue;
      case 'ORDERED':         return Colors.blue;
      case 'CONFIRMED':       return Colors.indigo;
      case 'PREPARING':       return Colors.orange;
      case 'READY':           return Colors.purple;
      case 'SERVED':          return Colors.teal;
      case 'WAITING_PAYMENT': return Colors.purple.shade900;
      case 'COMPLETED':       return Colors.green;
      case 'CANCELLED':       return Colors.red;
      default:                return Colors.grey;
    }
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }

  Widget _buildOrderTimeline(String status) {
    const statuses = ['PLACED', 'PREPARING', 'READY', 'SERVED'];
    int currentIndex = statuses.indexOf(status);
    if (currentIndex == -1) {
      if (status == 'COMPLETED') currentIndex = 3;
      else currentIndex = 0;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(statuses.length * 2 - 1, (i) {
          if (i.isOdd) { // Divider
            return Expanded(
              child: Container(
                height: 2,
                color: (i ~/ 2) < currentIndex ? Colors.indigo.shade700 : Colors.indigo.shade100,
              ),
            );
          }
          // Dot
          final stepIndex = i ~/ 2;
          final isPast = stepIndex <= currentIndex;
          final isCurrent = stepIndex == currentIndex;
          final label = statuses[stepIndex];

          return Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPast ? Colors.indigo.shade700 : Colors.white,
                  border: Border.all(color: isPast ? Colors.indigo.shade700 : Colors.indigo.shade200, width: 2),
                ),
                child: isCurrent ? Center(child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, color: isPast ? Colors.indigo.shade700 : Colors.grey.shade400),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWaitingArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.purple.shade700, size: 20),
              const SizedBox(width: 10),
              Text('WAITING FOR PAYMENT', style: GoogleFonts.poppins(color: Colors.purple.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Please proceed to the counter to pay your bill. Use UPI, Cash, or Card.',
              style: GoogleFonts.poppins(color: Colors.purple.shade700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPostPaymentArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAYMENT SUCCESSFUL', style: GoogleFonts.poppins(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Thank you for dining with us! Our team will close your session shortly.',
                      style: GoogleFonts.poppins(color: Colors.green.shade700, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestBill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Request Bill?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('This will notify the staff that you are ready to pay.',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Request', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final res = await ApiService.requestDiningBill(sessionId: widget.sessionId);
    if (!mounted) return;
    
    if (res['status'] == 'success' || res['success'] == true) {
      _fetchBill();
      scaffoldMessengerKey.currentState!.showSnackBar(
        const SnackBar(content: Text('Bill requested! Please pay at the counter.')),
      );
    } else {
      _fetchBill();
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Error requesting bill')),
      );
    }
  }

}

class _DiningCouponSheet extends StatefulWidget {
  final double subtotal;
  const _DiningCouponSheet({required this.subtotal});

  @override
  State<_DiningCouponSheet> createState() => _DiningCouponSheetState();
}

class _DiningCouponSheetState extends State<_DiningCouponSheet> {
  final _codeController = TextEditingController();
  bool _isValidating = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _apply(String code) async {
    if (code.isEmpty) return;
    setState(() { _isValidating = true; _error = null; });
    final error = await context.read<CouponProvider>().applyCoupon(code, widget.subtotal);
    if (!mounted) return;
    setState(() => _isValidating = false);
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text("Apply Coupon", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: "Enter coupon code",
                      errorText: _error,
                      suffixIcon: _isValidating 
                        ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        : TextButton(onPressed: () => _apply(_codeController.text.toUpperCase()), child: const Text("APPLY")),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }
}
