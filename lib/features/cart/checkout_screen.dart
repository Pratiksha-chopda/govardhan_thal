import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../payment/payment_screens.dart';
import '../../services/payment_service.dart';
import '../../services/razorpay_service.dart';
import '../../services/token_manager.dart';

import 'provider/coupon_provider.dart';

import '../../services/api_service.dart';
import '../cart/provider/cart_provider.dart';
import '../orders/provider/order_provider.dart';
import '../address/provider/address_provider.dart';
import '../address/address_selection_screen.dart';
import '../main/main_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List cartItems;
  final double subtotal;
  final double deliveryFee;
  final double gstAmount;
  final double total;
  final String orderType;
  final String? tableId;
  final String? sessionId;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.gstAmount,
    required this.total,
    this.orderType = 'ONLINE',
    this.tableId,
    this.sessionId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0; // 0=UPI, 1=Card, 2=Cash
  bool _isProcessing = false;

  late final List<Map<String, dynamic>> _paymentMethods;

  @override
  void initState() {
    super.initState();
    _paymentMethods = [
      {"icon": "💳", "label": "UPI", "desc": "Google Pay, PhonePe, Paytm"},
      {"icon": "🏦", "label": "Card", "desc": "Credit / Debit Card"},
      {"icon": "💵", "label": widget.orderType == 'TAKEAWAY' ? "Pay at Counter" : "Cash", "desc": widget.orderType == 'TAKEAWAY' ? "Pay when you pick up" : "Pay on delivery"},
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addrProv = context.read<AddressProvider>();
      final cartProv = context.read<CartProvider>();
      final activeAddr = addrProv.selectedAddress ?? addrProv.defaultAddress;
      if (activeAddr != null && widget.orderType == 'ONLINE') {
        cartProv.updateDeliveryAddress(activeAddr.id!);
      }
    });
  }

  @override
  void dispose() {
    RazorpayService.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    HapticFeedback.mediumImpact();

    final addrProv = context.read<AddressProvider>();
    final activeAddr = addrProv.selectedAddress ?? addrProv.defaultAddress;
    
    // SECTION 16/4: ONLINE only requires address
    if (widget.orderType == 'ONLINE' && activeAddr == null) {
      _showError("Please add a delivery address to proceed.");
      return;
    }

    final cart = context.read<CartProvider>();
    final cp = context.read<CouponProvider>();
    final discount = cp.discountAmount;
    
    // SECTION 5: Live totals from provider
    final double actualDeliveryFee = widget.orderType == 'ONLINE' ? cart.deliveryFee : 0;
    final totalToPay = cart.subtotal + cart.gstAmount + actualDeliveryFee - discount;
    
    final payMethod = _paymentMethods[_selectedPayment]['label'] as String;

    if (payMethod.contains('Cash') || payMethod.contains('Counter')) {
       // COD Flow: Skip payment screen, create order directly
       await _createOrderRecord(
         paymentStatus: 'PENDING',
         paymentMethod: 'CASH',
         transactionId: 'CASH',
         totalAmount: totalToPay,
         discount: discount,
       );
    } else {
       // UPI / Card → Open Razorpay native checkout (handles all methods)
       final userName = await TokenManager.getUserName();
       final userEmail = await TokenManager.getUserEmail();

       RazorpayService.openCheckout(
         amount: totalToPay,
         userName: userName,
         userEmail: userEmail.isNotEmpty ? userEmail : 'customer@govardhanthal.com',
         userPhone: '',
         onSuccess: (transactionId) {
           _createOrderRecord(
             paymentStatus: 'PAID',
             paymentMethod: payMethod == 'UPI' ? 'UPI' : 'CARD',
             transactionId: transactionId,
             totalAmount: totalToPay,
             discount: discount,
           );
         },
         onFailure: (errorMessage) {
           _showError(errorMessage);
         },
       );
    }
  }

  Future<void> _createOrderRecord({
    required String paymentStatus,
    required String paymentMethod,
    required String? transactionId,
    required double totalAmount,
    required double discount,
  }) async {
    setState(() => _isProcessing = true);
    final addrProv = context.read<AddressProvider>();
    final cp = context.read<CouponProvider>();
    final cart = context.read<CartProvider>();
    final activeAddr = addrProv.selectedAddress ?? addrProv.defaultAddress;

    try {
      final itemsPayload = widget.cartItems.map((item) => {
        "menuId": item.menuId,
        "quantity": item.quantity,
        "price": item.price,
      }).toList();

      final double actualDeliveryFee = widget.orderType == 'ONLINE' ? cart.deliveryFee : 0;

      final orderResult = await ApiService.placeOrder(
        items: itemsPayload,
        orderType: widget.orderType,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        addressId: widget.orderType == 'ONLINE' ? activeAddr?.id : null,
        discountAmount: discount,
        couponCode: cp.appliedCoupon?['code'],
        tableId: widget.tableId,
        deliveryFee: actualDeliveryFee,
        gst: cart.gstAmount,
      );

      if ((orderResult['status'] == 'success' || orderResult['success'] == true) && mounted) {
        // SECTION 7/17: Clear cart, coupon, totals
        context.read<CartProvider>().clearLocalCart();
        context.read<OrderProvider>().fetchOrders();
        cp.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(
            total: totalAmount, 
            payMethod: paymentMethod,
            orderType: widget.orderType,
          )),
        );
      } else {
        _showError(orderResult['message'] ?? "Failed to create order.");
      }
    } catch (e) {
      _showError("Connection error. Please check your internet.");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text("Checkout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
            children: [
              // SECTION 16: Address only for ONLINE
              if (widget.orderType == 'ONLINE') ...[
                _sectionHeader("📍 Delivery Address"),
                _addressCard(),
                const SizedBox(height: 20),
              ],

              // Order Summary
              _sectionHeader("🧾 Order Summary"),
              _orderSummaryCard(),
              const SizedBox(height: 20),

              // Payment
              _sectionHeader("💳 Payment Method"),
              ..._paymentMethods.asMap().entries.map((e) => _paymentOptionTile(e.key, e.value)),
              const SizedBox(height: 20),

              // Bill breakdown
              _sectionHeader("💰 Bill Details"),
              Consumer2<CouponProvider, CartProvider>(
                builder: (context, cp, cart, _) {
                  final discount = cp.discountAmount;
                  final double actualDeliveryFee = widget.orderType == 'ONLINE' ? cart.deliveryFee : 0;
                  final totalToPay = cart.subtotal + cart.gstAmount + actualDeliveryFee - discount;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
                    child: Column(
                      children: [
                        _billRow("Subtotal", "₹${cart.subtotal.toStringAsFixed(0)}"),
                        if (widget.orderType == 'ONLINE')
                          _billRow("Delivery", "₹${actualDeliveryFee.toStringAsFixed(0)}"),
                        _billRow(cart.gstSummaryLabel, "₹${cart.gstAmount.toStringAsFixed(0)}"),
                        if (discount > 0)
                          _billRow("Discount", "-₹${discount.toStringAsFixed(0)}", color: Colors.green),
                        const Divider(height: 20),
                        _billRow("Total", "₹${totalToPay.toStringAsFixed(0)}", bold: true),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // Bottom Place Order button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Consumer2<CouponProvider, CartProvider>(
                builder: (context, cp, cart, _) {
                  final double actualDeliveryFee = widget.orderType == 'ONLINE' ? cart.deliveryFee : 0;
                  final totalToPay = cart.subtotal + cart.gstAmount + actualDeliveryFee - cp.discountAmount;
                  return ElevatedButton(
                    onPressed: _isProcessing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text("Place Order • ₹${totalToPay.toStringAsFixed(0)}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // FULL SCREEN PROCESSING OVERLAY
          if (_isProcessing)
            Container(
              color: Colors.white.withValues(alpha: 0.95),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Lottie.network(
                    'https://assets2.lottiefiles.com/packages/lf20_m6cu96ze.json',
                    width: 200,
                    errorBuilder: (_, __, ___) => const CircularProgressIndicator(color: Color(0xFFFF6A00)),
                  ),
                  const SizedBox(height: 30),
                  Text("Securely Processing Payment...", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text("Please do not close the app", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
  );

  Widget _addressCard() {
    return Consumer<AddressProvider>(
      builder: (context, addrProv, _) {
        final activeAddr = addrProv.selectedAddress ?? addrProv.defaultAddress;
        final addressLabel = activeAddr != null ? activeAddr.label : "Delivering to";
        final addressString = activeAddr != null 
            ? activeAddr.fullAddress
            : "No address selected. Please add one.";

        if (widget.orderType == 'ONLINE' && activeAddr != null) {
          // Sync delivery fee when address changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CartProvider>().updateDeliveryAddress(activeAddr.id!);
          });
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFF6A00).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: Color(0xFFFF6A00), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addressLabel, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 11)),
                    Text(addressString, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressSelectionScreen()),
                  );
                },
                child: Text("Change", style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
      child: Column(
        children: widget.cartItems.take(3).map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("${item.quantity}× ${item.name}", style: GoogleFonts.poppins(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text("₹${item.subtotal.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          );
        }).toList()
          ..addAll(widget.cartItems.length > 3 ? [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("+${widget.cartItems.length - 3} more items", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            )
          ] : []),
      ),
    );
  }

  Widget _paymentOptionTile(int index, Map<String, dynamic> method) {
    final selected = _selectedPayment == index;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedPayment = index); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFFFF6A00) : Colors.grey.shade200, width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.1), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Text(method['icon'], style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method['label'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(method['desc'], style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFFFF6A00), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: bold ? Colors.black87 : Colors.grey.shade600, fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: bold ? 15 : 13)),
          Text(value, style: GoogleFonts.poppins(color: color ?? (bold ? const Color(0xFFFF6A00) : Colors.black87), fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 15 : 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Order Success Screen
// ─────────────────────────────────────────────────
class OrderSuccessScreen extends StatefulWidget {
  final double total;
  final String payMethod;
  final String orderType;
  const OrderSuccessScreen({super.key, required this.total, required this.payMethod, this.orderType = 'ONLINE'});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _contentController;
  late Animation<double> _checkScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _checkController.forward().then((_) => _contentController.forward());
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = "GT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Lottie celebration
              ScaleTransition(
                scale: _checkScale,
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 100,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Content
              SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      Text(widget.orderType == 'DINING' ? "Order Sent! 🍲" : "Order Placed! 🎉", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 10),
                      Text(
                        widget.orderType == 'DINING' 
                          ? "The kitchen is preparing your feast.\nIt will be served at your table shortly." 
                          : widget.orderType == 'TAKEAWAY'
                            ? "Your takeaway order is confirmed.\nCollect at our counter in 20-30m."
                            : "Your order has been placed\nsuccessfully and is being prepared.", 
                        textAlign: TextAlign.center, 
                        style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, height: 1.6)
                      ),
                      const SizedBox(height: 30),

                      // Order details card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _detailRow("Order ID", "#$orderId"),
                            const SizedBox(height: 10),
                            _detailRow("Amount", "₹${widget.total.toStringAsFixed(0)}"),
                            const SizedBox(height: 10),
                            _detailRow("Type", widget.orderType),
                            const SizedBox(height: 10),
                            _detailRow("Status", "Confirmed"),
                            if (widget.orderType == 'ONLINE') ...[
                               const SizedBox(height: 10),
                               _detailRow("Est. Delivery", "30-45m"),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Track order button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Ensure MainScreen is pushed with index 3 (Orders tab)
                            Navigator.pushAndRemoveUntil(
                               context, 
                               MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)), 
                               (route) => false
                            );
                          },
                          icon: const Icon(Icons.receipt_long, color: Colors.white),
                          label: Text("Track Order", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6A00),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFFF6A00)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("Back to Home", style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13)),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}
