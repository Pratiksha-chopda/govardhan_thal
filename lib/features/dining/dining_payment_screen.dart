import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../payment/payment_screens.dart';

/// DiningPaymentScreen — Pay at counter or online for a dining session.
class DiningPaymentScreen extends StatefulWidget {
  final String sessionId;
  final String tableNumber;
  final double total;

  const DiningPaymentScreen({
    super.key,
    required this.sessionId,
    required this.tableNumber,
    required this.total,
  });

  @override
  State<DiningPaymentScreen> createState() => _DiningPaymentScreenState();
}

class _DiningPaymentScreenState extends State<DiningPaymentScreen> {
  String _selectedMethod = 'COUNTER';
  bool _isProcessing = false;

  final _methods = [
    {'id': 'COUNTER', 'label': 'Pay at Counter', 'icon': Icons.storefront, 'desc': 'Pay with cash or card at the billing counter'},
    {'id': 'UPI',     'label': 'UPI / QR Pay',   'icon': Icons.qr_code_scanner, 'desc': 'Scan & pay via any UPI app'},
    {'id': 'CARD',    'label': 'Debit / Credit Card', 'icon': Icons.credit_card, 'desc': 'Swipe your card at the counter'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text('Secure Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            physics: const BouncingScrollPhysics(),
            children: [
              // Amount card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFFEE0979)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    Text('TOTAL AMOUNT DUE', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text('₹${widget.total.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 44, letterSpacing: -1)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text('Table #${widget.tableNumber}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text('Choose Payment Method', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 16),

              ..._methods.map((method) => _buildMethodCard(method)),

              const SizedBox(height: 12),

              // Info note
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.blue.shade600, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your transaction is secure. After payment confirmation, your session will be finalized and the table will be freed.',
                        style: GoogleFonts.poppins(color: Colors.blue.shade800, fontSize: 12, height: 1.6, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Pay button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, -10))],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 5,
                  shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('I HAVE PAID ₹${widget.total.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMethod = method['id'] as String);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6A00).withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6A00) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFFF6A00).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15, offset: const Offset(0, 5)
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6A00).withValues(alpha: 0.12) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(method['icon'] as IconData,
                  color: isSelected ? const Color(0xFFFF6A00) : Colors.grey.shade600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method['label'] as String,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15,
                          color: isSelected ? const Color(0xFFFF6A00) : Colors.black87)),
                  Text(method['desc'] as String,
                      style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, 
                 color: isSelected ? const Color(0xFFFF6A00) : Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    HapticFeedback.heavyImpact();

    if (_selectedMethod == 'COUNTER') {
       await _finalizePayment(method: 'COUNTER', transactionId: 'COUNTER');
    } else if (_selectedMethod == 'UPI') {
       Navigator.push(context, MaterialPageRoute(builder: (_) => UPIPaymentScreen(
         amount: widget.total,
         upiApp: 'PhonePe',
         onPaymentComplete: (res) {
           Navigator.pop(context);
           if (res.status == PaymentStatus.success) {
             _finalizePayment(method: 'UPI', transactionId: res.transactionId);
           } else {
             _showError(res.message ?? "Payment failed");
           }
         },
       )));
    } else { // CARD
       Navigator.push(context, MaterialPageRoute(builder: (_) => CardPaymentScreen(
         amount: widget.total,
         onPaymentComplete: (res) {
           Navigator.pop(context);
           if (res.status == PaymentStatus.success) {
             _finalizePayment(method: 'CARD', transactionId: res.transactionId);
           } else {
             _showError(res.message ?? "Payment failed");
           }
         },
       )));
    }
  }

  Future<void> _finalizePayment({required String method, String? transactionId}) async {
    setState(() => _isProcessing = true);
    final res = await ApiService.payDiningBill(
      sessionId: widget.sessionId,
      paymentMethod: method,
      transactionId: transactionId,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['status'] == 'success' || res['success'] == true) {
      _showSuccessDialog(method);
    } else {
      _showError(res['message'] ?? 'Payment failed');
    }
  }

  void _showError(String msg) {
    scaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showSuccessDialog(String method) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 24),
              Text('Payment Successful!', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black)),
              const SizedBox(height: 8),
              Text('₹${widget.total.toStringAsFixed(0)} paid via $method',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close payment screen → back to bill
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text('Perfect!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
