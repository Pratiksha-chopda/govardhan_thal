import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'provider/cart_provider.dart';
import 'provider/coupon_provider.dart';
import '../orders/provider/order_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final String orderType;
  final String? sessionId;
  final String? tableId;
  final String? tableNumber;

  const CartScreen({
    super.key,
    this.orderType = 'ONLINE',
    this.sessionId,
    this.tableId,
    this.tableNumber,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late String _currentOrderType;

  @override
  void initState() {
    super.initState();
    _currentOrderType = widget.orderType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  String _emojiForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('thali')) return '🍱';
    if (c.contains('sweet')) return '🍮';
    if (c.contains('farsan') || c.contains('snack')) return '🥘';
    if (c.contains('bread')) return '🫓';
    if (c.contains('drink')) return '🥛';
    if (c.contains('dal') || c.contains('rice')) return '🍚';
    if (c.contains('sabzi')) return '🥦';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text("Order Summary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.items.isEmpty
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () => _confirmClear(cart),
                      child: Text("Clear Cart", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading) {
            return _buildLoading();
          }
          if (cart.items.isEmpty) {
            return _buildEmpty();
          }
          return _buildCartContent(cart);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets2.lottiefiles.com/packages/lf20_ws4guz7r.json', 
              width: 220,
              repeat: true,
              errorBuilder: (_, __, ___) => Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              widget.orderType == 'DINING' ? "Fresh Table, Empty Cart" : "Your cart is lonely", 
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const SizedBox(height: 12),
            Text(
              widget.orderType == 'DINING' 
                  ? "Select items from the menu and they'll appear here for your table." 
                  : "Explore our categories and add something delicious to start your feast!", 
              textAlign: TextAlign.center, 
              style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 15, height: 1.6)
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text("Add Items", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartProvider cart) {
    final cp = context.watch<CouponProvider>();
    final subtotal = cart.subtotal;
    final deliveryFee = cart.deliveryFee;
    final gstAmount = cart.gstAmount;
    final discount = cp.discountAmount;
    
    // SECTION 1/5: Dynamic totals based on type
    final double activeDeliveryFee = _currentOrderType == 'ONLINE' ? deliveryFee : 0;
    final finalAmount = (subtotal + gstAmount + activeDeliveryFee) - discount;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 200),
          physics: const BouncingScrollPhysics(),
          children: [
            // Mode Header / Type Selector (Section 1)
            if (widget.orderType == 'DINING')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.restaurant_rounded, color: Colors.indigo.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text("Order for Table ${widget.tableNumber ?? widget.tableId ?? '...'}", 
                          style: GoogleFonts.poppins(color: Colors.indigo.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
                child: Row(
                  children: [
                    Expanded(child: _orderTypeTab('ONLINE', 'Delivery', Icons.delivery_dining_rounded)),
                    Expanded(child: _orderTypeTab('TAKEAWAY', 'Takeaway', Icons.shopping_bag_rounded)),
                  ],
                ),
              ),

            // Cart Items
            ...cart.items.map((item) => _CartItemTile(
                  item: item,
                  emoji: _emojiForCategory(item.category),
                )),

            const SizedBox(height: 12),
            
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFF6A00), size: 18),
              label: Text("Add more items", style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                alignment: Alignment.centerLeft,
              ),
            ),

            const SizedBox(height: 24),

            // Coupons & Offers
            Consumer<CouponProvider>(
              builder: (context, cp, _) {
                final hasCoupon = cp.appliedCoupon != null;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: InkWell(
                    onTap: () => _showCouponSheet(context, cart.subtotal),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFF6A00).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.local_offer_rounded, color: Color(0xFFFF6A00), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hasCoupon ? cp.appliedCoupon!['code'] : "Coupons & Offers", 
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(hasCoupon ? "₹${cp.discountAmount.toInt()} saved with this code" : "Save more with coupons", 
                                  style: GoogleFonts.poppins(fontSize: 11, color: hasCoupon ? Colors.green.shade600 : Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (hasCoupon)
                          TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              cp.removeCoupon();
                            },
                            child: Text("REMOVE", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        else
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Bill Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bill Summary", style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                  const SizedBox(height: 18),
                  _billRow("Item Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
                  if (_currentOrderType == 'ONLINE') ...[
                    _billRow("Delivery Partner Fee", "₹${deliveryFee.toStringAsFixed(0)}"),
                  ],
                  _billRow(cart.gstSummaryLabel, "₹${gstAmount.toStringAsFixed(0)}"),
                  if (discount > 0) ...[
                    _billRow("Coupon Discount", "-₹${discount.toStringAsFixed(0)}", color: Colors.green.shade600),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  ),
                  _billRow("Grand Total", "₹${finalAmount.toStringAsFixed(0)}", bold: true),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            // Cancellation Policy
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Cancellation policy applies once order is confirmed.",
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Bottom Bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 25, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Total Amount", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("₹${finalAmount.toStringAsFixed(0)}", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder ? null : () {
                          if (widget.orderType == 'DINING') {
                            _placeDiningOrder(cart);
                          } else {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  cartItems: cart.items,
                                  subtotal: subtotal,
                                  deliveryFee: deliveryFee,
                                  gstAmount: gstAmount,
                                  total: subtotal + gstAmount + activeDeliveryFee,
                                  orderType: _currentOrderType,
                                ),
                              ),
                            ).then((_) => context.read<OrderProvider>().fetchOrders());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.orderType == 'DINING' ? Colors.indigo.shade700 : const Color(0xFFFF6A00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 4,
                          shadowColor: (widget.orderType == 'DINING' ? Colors.indigo : const Color(0xFFFF6A00)).withValues(alpha: 0.4),
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(widget.orderType == 'DINING' ? "Send to Kitchen" : "Checkout", 
                                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderTypeTab(String type, String label, IconData icon) {
    final active = _currentOrderType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _currentOrderType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6A00) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.grey, size: 16),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  bool _isPlacingOrder = false;

  Future<void> _placeDiningOrder(CartProvider cart) async {
    if (widget.sessionId == null || widget.tableId == null) return;
    HapticFeedback.heavyImpact();
    setState(() => _isPlacingOrder = true);

    final cp = context.read<CouponProvider>();
    final couponCode = cp.appliedCoupon?['code'];
    final discount = cp.discountAmount;

    final ok = await cart.placeAsDiningOrder(
      sessionId: widget.sessionId!,
      tableId: widget.tableId!,
      couponCode: couponCode,
      discountAmount: discount,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (ok) {
      cp.clear();
      scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
        content: Text('Order sent successfully! 🍲', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    } else {
      scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
        content: Text('Failed to place order. Please try again.', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showCouponSheet(BuildContext context, double currentSubtotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CouponSheet(subtotal: currentSubtotal),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: bold ? Colors.black87 : Colors.grey.shade600, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14)),
          Text(value, style: GoogleFonts.poppins(color: color ?? (bold ? const Color(0xFFFF6A00) : Colors.black87), fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }

  void _confirmClear(CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Clear Cart?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove all items from your cart?", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () { 
              Navigator.pop(context); 
              cart.clearCart(); 
              context.read<CouponProvider>().clear(); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text("Clear All", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  final String emoji;
  const _CartItemTile({required this.item, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('cart_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return await context.read<CartProvider>().removeItem(item.menuId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 70, height: 70,
                child: CachedNetworkImage(
                  imageUrl: item.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade100,
                    highlightColor: Colors.white,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.05),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("₹${item.price.toStringAsFixed(0)}", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _qtyBtn(Icons.remove_rounded, () {
                    if (item.quantity > 1) {
                      context.read<CartProvider>().updateQuantity(item.menuId, item.quantity - 1);
                    } else {
                      context.read<CartProvider>().removeItem(item.menuId);
                    }
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.quantity}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFFFF6A00))),
                  ),
                  _qtyBtn(Icons.add_rounded, () {
                    context.read<CartProvider>().updateQuantity(item.menuId, item.quantity + 1);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 18, color: const Color(0xFFFF6A00)),
      ),
    );
  }
}

class _CouponSheet extends StatefulWidget {
  final double subtotal;
  const _CouponSheet({required this.subtotal});

  @override
  State<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends State<_CouponSheet> {
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
    final cp = context.watch<CouponProvider>();
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20))),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Apply Coupon", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) { if (_error != null) setState(() => _error = null); },
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                          decoration: InputDecoration(hintText: "ENTER CODE", border: InputBorder.none, hintStyle: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
                        ),
                      ),
                      _isValidating 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6A00)))
                        : TextButton(
                            onPressed: () => _apply(_codeController.text),
                            child: Text("APPLY", style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold)),
                          ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(padding: const EdgeInsets.only(top: 8, left: 4), child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500))),
                
                const SizedBox(height: 32),
                Text("AVAILABLE OFFERS", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.5)),
                const SizedBox(height: 16),
                
                if (cp.availableCoupons.isEmpty)
                   Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("No offers available at the moment", style: GoogleFonts.poppins(color: Colors.grey)))),
                
                ...cp.availableCoupons.map((c) {
                  final code = c['code'] ?? '';
                  final desc = c['description'] ?? 'Save more with this offer';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFFF6A00).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                              child: Text(code, style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.w900, fontSize: 13)),
                            ),
                            TextButton(
                              onPressed: () => _apply(code),
                              child: Text("APPLY", style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(desc, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
