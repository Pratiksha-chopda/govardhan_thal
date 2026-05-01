import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../menu/provider/menu_provider.dart';
import '../cart/provider/cart_provider.dart';
import '../cart/cart_screen.dart';
import 'package:restaurant/features/address/address_selection_screen.dart';
import 'package:restaurant/features/address/add_address_screen.dart';
import 'package:restaurant/features/address/provider/address_provider.dart';
import '../dining/qr_scanner_screen.dart';
import 'booking_screen.dart';
import 'provider/home_provider.dart';
import 'widgets/banner_widget.dart';
import 'widgets/category_widget.dart';
import 'widgets/food_card.dart';
import 'widgets/special_food_card.dart';
import '../notification/notification_screen.dart';
import '../notification/notification_service.dart';
import '../menu/menu_screen.dart';
import '../splash/thali_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = '';
  bool _hasShownDialog = false;
  int _unreadCount = 0;

  bool _isSearchFocused = false;
  bool _isBellPressed = false;
  late AnimationController _qrIconController;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchUnreadCount();
    
    // Check for active dining session on load + pre-fetch addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().checkActiveSession();
      // Pre-fetch addresses in background so "Order Online" loads fast
      context.read<AddressProvider>().fetchAddresses();
    });

    _qrIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownDialog) _showSelectionDialog();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUnreadCount();
  }

  @override
  void dispose() {
    _qrIconController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Guest';
      });
    }
  }

  void _showSelectionDialog() {
    _hasShownDialog = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order Selection',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, anim, secondAnim) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 15)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6A00), Color(0xFFFF8C38)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 14),
                          Text("Place Your Order",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text("Choose your dining experience",
                              style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // Cards Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _modeCard(
                              icon: Icons.qr_code_scanner_rounded,
                              title: "Dine In",
                              subtitle: "At Restaurant",
                              emoji: "🍽️",
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _modeCard(
                              icon: Icons.delivery_dining_rounded,
                              title: "Order Online",
                              subtitle: "Home Delivery",
                              emoji: "🛵",
                              onTap: () async {
                                Navigator.pop(context);
                                _handleOnlineOrderFlow();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dismiss hint
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text("Skip for now",
                            style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500, decoration: TextDecoration.underline, decorationColor: Colors.grey.shade400)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleOnlineOrderFlow() async {
    final addrProv = context.read<AddressProvider>();
    
    // Show a non-blocking loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(color: Color(0xFFFF6A00), strokeWidth: 3.5),
              ),
              const SizedBox(height: 16),
              Text("Finding addresses...", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
    
    await addrProv.fetchAddresses();
    if (context.mounted) Navigator.pop(context); // Close loader

    if (!context.mounted) return;

    if (addrProv.addresses.isNotEmpty) {
      _showAddressSelectionSheet(context);
    } else {
      _showLocationPermissionChoice(context);
    }
  }

  void _showAddressSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const AddressSelectionScreen(),
      ),
    );
  }

  void _showLocationPermissionChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: const Color(0xFFFF6A00).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded, color: Color(0xFFFF6A00), size: 32),
            ),
            const SizedBox(height: 20),
            Text("Allow location access for delivery?", 
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Enabling your location helps us provide faster and more accurate delivery to your doorstep.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFFF6A00)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text("Add Manually", style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressSelectionScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                    ),
                    child: Text("Allow Location", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _modeCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, String emoji = "", bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7F2) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFF6A00) : Colors.grey.shade200, width: isSelected ? 2 : 1.5),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFFF6A00).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFF6A00).withValues(alpha: 0.12), const Color(0xFFFF8C38).withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFFFF6A00), size: 28),
            ),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87, letterSpacing: -0.3)),
            const SizedBox(height: 3),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Softer background
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: const Color(0xFFFF6A00),
              onRefresh: () async {
                await context.read<HomeProvider>().loadHomeData();
                await context.read<CartProvider>().fetchCart();
                await context.read<MenuProvider>().loadMenuData();
                await _fetchUnreadCount();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActiveSessionBanner(),
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 28),
                    const HomeBannerCarousel(),
                    const SizedBox(height: 36),
                    _buildCategoriesSection(),
                    const SizedBox(height: 40),
                    _buildHorizontalFoodList(
                      title: "🔥 Popular Items",
                      itemsSelector: (provider) => provider.popularItems,
                    ),
                    const SizedBox(height: 40),
                    _buildDineInScannerBanner(),
                    const SizedBox(height: 40),
                    _buildHorizontalFoodList(
                      title: "⭐ Today's Special",
                      itemsSelector: (provider) => provider.todaySpecials,
                      isSpecial: true,
                    ),
                    const SizedBox(height: 40),
                    _buildReserveTableBanner(),
                  ],
                ),
              ),
            ),
            _buildFloatingCartBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCartBar() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final hasItems = cart.items.isNotEmpty;
        
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          bottom: hasItems ? 20 : -120,
          left: 16,
          right: 16,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(cart.itemCount),
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${cart.itemCount} Item${cart.itemCount > 1 ? 's' : ''}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("₹${cart.total.toStringAsFixed(0)}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text("View Cart", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20)
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const ThaliLogo(size: 44),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                    const SizedBox(height: 2),
                    Text(
                      _userName.isEmpty ? 'Guest' : _userName,
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTapDown: (_) => setState(() => _isBellPressed = true),
              onTapUp: (_) => setState(() => _isBellPressed = false),
              onTapCancel: () => setState(() => _isBellPressed = false),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const NotificationScreen()),
                ).then((_) => _fetchUnreadCount());
              },
              child: AnimatedScale(
                scale: _isBellPressed ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 26),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(_unreadCount),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: Text(
                              _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MenuScreen(autoFocusSearch: true)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFFFF6A00), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Search for delicious thali...",
                  style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              const Icon(Icons.tune_rounded, color: Color(0xFFFF6A00), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Special Categories", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: const Color(0xFF1A1A1A))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.categories.length,
                itemBuilder: (_, i) => CategoryWidget(category: provider.categories[i], index: i),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalFoodList({required String title, required List Function(HomeProvider) itemsSelector, bool isSpecial = false}) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          // Skeleton loader
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(width: 150, height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)))),
               const SizedBox(height: 16),
               SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: Row(
                   children: List.generate(3, (i) => Container(
                     width: isSpecial ? 240 : 160,
                     height: isSpecial ? 340 : 250,
                     margin: const EdgeInsets.only(right: 12),
                     decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(22)),
                   )),
                 ),
               ),
            ],
          );
        }

        final items = itemsSelector(provider);
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_menu, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text("No items available currently", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: const Color(0xFF1A1A1A))),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen())),
                    child: Text("View all", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF6A00))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  return _buildAnimatedChild(
                    index: i,
                    child: isSpecial 
                        ? SpecialFoodCard(item: entry.value)
                        : FoodCard(item: entry.value),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveSessionBanner() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.activeSession == null) return const SizedBox.shrink();
        
        final session = cart.activeSession!;
        final tableNum = session['tableId']?['tableNumber'] ?? '?';
        
        return GestureDetector(
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(
              orderType: 'DINING',
              tableId: session['tableId']?['_id'] ?? '',
              sessionId: session['_id'] ?? '',
             )));
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.deepOrange.shade800]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dining at Table $tableNum", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      Text("Session Active • #${session['_id']?.toString().substring(session['_id'].toString().length - 4).toUpperCase()}", style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Leave Table?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        content: Text("Do you want to leave this session? This won't cancel any unpaid bills.", style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
                          TextButton(onPressed: () {
                            Provider.of<CartProvider>(context, listen: false).clearActiveSession();
                            Navigator.pop(context);
                          }, child: const Text("YES")),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedChild({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 80).clamp(0, 600)),
      curve: Curves.fastOutSlowIn,
      builder: (context, value, wg) {
        return Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Opacity(opacity: value, child: wg),
        );
      },
      child: child,
    );
  }

  Widget _buildDineInScannerBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF2B32B2), Color(0xFF1488CC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: const Color(0xFF1488CC).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, bottom: -20,
                child: Icon(Icons.qr_code_scanner, color: Colors.white.withValues(alpha: 0.1), size: 160),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Expanded(
                       child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text("AT THE RESTAURANT?", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(height: 12),
                          Text("Scan to Order", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                                           ),
                     ),
                    const SizedBox(width: 16),
                    AnimatedBuilder(
                      animation: _qrIconController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -8 * _qrIconController.value),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8))]),
                        child: const Icon(Icons.qr_code_scanner, color: Color(0xFF2B32B2), size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReserveTableBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&q=80&w=800'),
              fit: BoxFit.cover,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.7)]
                  )
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("CELEBRATE WITH US", style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text("Reserve a Table", style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6A00),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Row(
                            children: [
                              Text("Book", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12)
                            ],
                          )
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
