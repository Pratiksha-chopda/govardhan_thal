import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../cart/provider/cart_provider.dart';
import '../cart/cart_screen.dart';

import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/custom_empty_state.dart';
import 'provider/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        appBar: AppBar(
          title: Text("My Orders", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black)),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: const Color(0xFFFF6A00),
            labelColor: const Color(0xFFFF6A00),
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: "Online"),
              Tab(text: "Dining"),
              Tab(text: "Takeaway"),
            ],
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return const OrderShimmerList();
            }

            final onlineOrders = orderProvider.orders.where((o) => (o['order_type'] ?? o['orderType']) == 'ONLINE').toList();
            final diningOrders = orderProvider.orders.where((o) => (o['order_type'] ?? o['orderType']) == 'DINING').toList();
            final takeawayOrders = orderProvider.orders.where((o) => (o['order_type'] ?? o['orderType']) == 'TAKEAWAY').toList();

            return TabBarView(
              children: [
                _buildOrderList(onlineOrders),
                _buildOrderList(diningOrders),
                _buildOrderList(takeawayOrders),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List dynamicOrders) {
    if (dynamicOrders.isEmpty) {
      return CustomEmptyState(
        icon: Icons.receipt_long_rounded,
        title: "No Orders Yet",
        subtitle: "Looks like you haven't placed an order today.\nExplore our delicious menu!",
        buttonText: "Browse Menu",
        onButtonPressed: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: dynamicOrders.length,
      itemBuilder: (context, index) {
        final order = dynamicOrders[index];
        final status = order['status'] ?? order['orderStatus'] ?? 'PENDING';
              final rawId = order['_id'] != null ? order['_id'].toString().substring(0, 8).toUpperCase() : 'UNKNOWN';
              final orderNum = order['orderNumber'];
              final tableRecord = order['tableId'];
              final tableNum = (tableRecord != null && tableRecord is Map) ? tableRecord['tableNumber'] : null;

              String displayTitle = "Order #";
              if (orderNum != null) {
                displayTitle = tableNum != null ? "Table #$tableNum - Order #$orderNum" : "Order #$orderNum";
              } else {
                displayTitle = "Order #$rawId";
              }
              final total = order['totalAmount'] ?? 0;
              final dateStr = order['createdAt'] ?? '';
              
              String formattedDate = '';
              try {
                if (dateStr.isNotEmpty) {
                  final dt = DateTime.parse(dateStr).toLocal();
                  formattedDate = DateFormat('dd MMM, hh:mm a').format(dt);
                }
              } catch (_) {}

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildOrderCard(displayTitle, "₹$total  •  $formattedDate", status, order),
              );
            },
          );
  }

  Widget _buildOrderCard(String id, String details, String status, Map order) {
    Color statusColor;
    if (status == 'CANCELLED') statusColor = Colors.red.shade600;
    else if (status == 'COMPLETED') statusColor = Colors.green.shade600;
    else statusColor = const Color(0xFFFF6A00);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderData: order)));
      },
      child: Container(
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
                Expanded(child: Text(id, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(), style: GoogleFonts.poppins(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(details, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFF5F5F5), thickness: 1),
            ),
            
            Row(
              children: [
                const Icon(Icons.track_changes_rounded, color: Color(0xFFFF6A00), size: 18),
                const SizedBox(width: 8),
                Text(
                  "Track Live Status",
                  style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFFF6A00)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class OrderTrackingScreen extends StatefulWidget {
  final Map orderData;
  const OrderTrackingScreen({super.key, required this.orderData});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Map currentOrder;
  bool isRefreshing = false;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.orderData;
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLatestStatus();
    });
  }

  Future<void> _fetchLatestStatus() async {
    if (isRefreshing) return;
    try {
      if (mounted) setState(() => isRefreshing = true);
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final latestRes = await provider.getOrderDetail(currentOrder['_id']);
      if (mounted && latestRes != null) {
        setState(() {
          currentOrder = latestRes['data'] ?? latestRes;
          isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isRefreshing = false);
    }
  }

  List<dynamic> get timelineEntries => currentOrder['timeline'] ?? currentOrder['statusHistory'] ?? [];
  String get orderStatus => currentOrder['status'] ?? currentOrder['orderStatus'] ?? 'PLACED';

  @override
  Widget build(BuildContext context) {
    final rawId = currentOrder['_id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN';
    final orderNum = currentOrder['orderNumber'];
    final tableRecord = currentOrder['tableId'];
    final tableNum = (tableRecord != null && tableRecord is Map) ? tableRecord['tableNumber'] : null;

    String displayTitle = "Order #";
    if (orderNum != null) {
      displayTitle = tableNum != null ? "Table #$tableNum - Order #$orderNum" : "Order #$orderNum";
    } else {
      displayTitle = "Order #$rawId";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Live Tracking", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isRefreshing)
            const Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6A00)))),
        ],
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLatestStatus,
        color: const Color(0xFFFF6A00),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF212121), Color(0xFF424242)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayTitle, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.payments_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text("Total Price: ₹${currentOrder['totalAmount']}", style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(currentOrder['orderType'] == 'DINING' ? 'DINE IN' : 'DELIVERY', style: GoogleFonts.poppins(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ORDER JOURNEY", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.0)),
                    Text("Est: 30-40 min", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade600)),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildTimelineList(),

                const SizedBox(height: 48),

                Text("BILL SUMMARY", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.0)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Column(
                    children: [
                      ...(currentOrder['items'] as List? ?? []).map((item) {
                        final name = item['menuId']?['name'] ?? item['name'] ?? 'Dish';
                        final qty = item['quantity'] ?? 1;
                        final price = item['price'] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text("$qty x $name", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text("₹${price * qty}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
                            ],
                          ),
                        );
                      }).toList(),
                      if (currentOrder['discountAmount'] != null && currentOrder['discountAmount'] > 0) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Discount", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade600)),
                            Text("-₹${currentOrder['discountAmount']}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green.shade600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Enhanced Order Actions
                if (orderStatus == 'PLACED' || orderStatus == 'CONFIRMED') ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        final res = await ApiService.cancelOrder(currentOrder['_id']);
                        if (res['success'] == true) {
                          _fetchLatestStatus();
                          if (mounted) Provider.of<OrderProvider>(context, listen: false).fetchOrders();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to cancel')));
                        }
                      },
                      icon: const Icon(Icons.cancel_rounded, color: Colors.deepOrange),
                      label: Text("Cancel Order", style: GoogleFonts.poppins(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],

                if (orderStatus == 'DELIVERED' || orderStatus == 'COMPLETED') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final res = await ApiService.reorder(currentOrder['_id']);
                            if (res['success'] == true) {
                               if (mounted) Provider.of<CartProvider>(context, listen: false).fetchCart();
                               if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to reorder')));
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                          label: Text("Reorder", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6A00),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final res = await ApiService.submitRating(currentOrder['_id'], 5, review: "Great food!");
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Rated 5 Stars!')));
                          },
                          icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          label: Text("Rate 5 Star", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        final res = await ApiService.submitComplaint(currentOrder['_id'], 'OTHER', description: 'User opened complaint menu');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Support ticket created!')));
                      },
                      icon: const Icon(Icons.support_agent_rounded, color: Colors.grey),
                      label: Text("Report an Issue", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineList() {
    final type = currentOrder['order_type'] ?? currentOrder['orderType'] ?? 'ONLINE';
    List<String> flow;
    
    if (type == 'DINING') {
      flow = ['PLACED', 'CONFIRMED', 'PREPARING', 'SERVED', 'COMPLETED'];
    } else if (type == 'TAKEAWAY') {
      flow = ['PLACED', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'COMPLETED'];
    } else {
      flow = ['PLACED', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'COMPLETED'];
    }

    if (orderStatus == 'CANCELLED') {
       return _buildStep(
         title: "Order Cancelled", 
         isActive: true, 
         isLast: true, 
         icon: Icons.cancel_rounded, 
         color: Colors.red.shade600,
         timestamp: timelineEntries.isNotEmpty ? timelineEntries.last['timestamp'] : null,
       );
    }

    return Column(
      children: List.generate(flow.length, (index) {
        final stepStatus = flow[index];
        // Check if history contains this status
        final history = currentOrder['statusHistory'] as List? ?? [];
        final historyMatch = history.any((h) => h['status'] == stepStatus) 
            ? history.firstWhere((h) => h['status'] == stepStatus) 
            : null;
        
        // Also check timeline (backward compatibility or alternative field)
        final timelineMatch = timelineEntries.any((entry) => entry['status'] == stepStatus) 
            ? timelineEntries.firstWhere((entry) => entry['status'] == stepStatus) 
            : null;
            
        final activeEntry = historyMatch ?? timelineMatch;
        bool isActive = activeEntry != null;

        final currentIndex = flow.indexOf(orderStatus);
        if (!isActive && currentIndex != -1 && index <= currentIndex) {
          isActive = true;
        }
        
        IconData icon = Icons.receipt_long_rounded;
        if (stepStatus == 'CONFIRMED') icon = Icons.verified_rounded;
        if (stepStatus == 'PREPARING') icon = Icons.soup_kitchen_rounded;
        if (stepStatus == 'READY_FOR_PICKUP') icon = Icons.shopping_bag_rounded;
        if (stepStatus == 'SERVED') icon = Icons.flatware_rounded;
        if (stepStatus == 'OUT_FOR_DELIVERY') icon = Icons.delivery_dining_rounded;
        if (stepStatus == 'DELIVERED') icon = Icons.home_rounded;
        if (stepStatus == 'COMPLETED') icon = Icons.check_circle_rounded;

        return _buildStep(
          title: _getStepTitle(stepStatus),
          isActive: isActive,
          isLast: index == flow.length - 1,
          icon: icon,
          color: isActive ? const Color(0xFFFF6A00) : Colors.grey.shade300,
          timestamp: activeEntry?['timestamp'],
        );
      }),
    );
  }

  String _getStepTitle(String status) {
    switch(status) {
      case 'PLACED': return "Order Received";
      case 'CONFIRMED': return "Confirmed by Kitchen";
      case 'PREPARING': return "Chef is Cooking";
      case 'READY_FOR_PICKUP': return "Ready for Pickup";
      case 'SERVED': return "Food Served to Table";
      case 'OUT_FOR_DELIVERY': return "Our Buddy is on the Way";
      case 'DELIVERED': return "Delivered at your Door";
      case 'COMPLETED': 
        if ((currentOrder['order_type'] ?? currentOrder['orderType']) == 'DINING') return "Payment Completed";
        if ((currentOrder['order_type'] ?? currentOrder['orderType']) == 'TAKEAWAY') return "Picked Up";
        return "Enjoy your Meal!";
      default: return status.replaceAll('_', ' ');
    }
  }

  Widget _buildStep({required String title, required bool isActive, required bool isLast, required IconData icon, required Color color, String? timestamp}) {
    String formattedTime = '';
    if (timestamp != null) {
      final dt = DateTime.parse(timestamp).toLocal();
      formattedTime = DateFormat('hh:mm a').format(dt);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.12) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? color : Colors.grey.shade200, width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(color: isActive ? color : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                  ),
                )
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? Colors.black : Colors.grey.shade400)),
                  if (formattedTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(formattedTime, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

