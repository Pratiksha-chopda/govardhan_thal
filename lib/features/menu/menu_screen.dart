import 'dart:async';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../menu/provider/menu_provider.dart';
import '../cart/provider/cart_provider.dart';
import '../menu/model/menu_item.dart';
import 'item_detail_screen.dart';
import '../dining/dining_bill_screen.dart';
import '../cart/cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final String orderType; // 'ONLINE' or 'DINING'
  final String? sessionId;
  final String? tableId;
  final String? tableNumber;
  final DateTime? sessionStartTime;
  final String? category;
  final bool showOnlySpecials;
  final bool autoFocusSearch;
  
  const MenuScreen({
    super.key,
    this.orderType = 'ONLINE',
    this.sessionId,
    this.tableId,
    this.tableNumber,
    this.sessionStartTime,
    this.category,
    this.showOnlySpecials = false,
    this.autoFocusSearch = false,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showOnlyFavorites = false;
  late TabController _tabController;
  bool _tabsReady = false;

  Timer? _sessionTimer;
  String _sessionDuration = '00:00';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _cartBounceController;
  late Animation<double> _cartBounceAnimation;

  int _lastCartCount = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _cartBounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _cartBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_cartBounceController);

    if (widget.orderType == 'DINING' && widget.sessionStartTime != null) {
      _startSessionTimer();
    }

    _fadeController.forward();
    context.read<MenuProvider>().addListener(_onMenuChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _lastCartCount = context.read<CartProvider>().items.length;
      final existingCats = context.read<MenuProvider>().categories;
      if (existingCats.isNotEmpty) _initTabs();
      context.read<MenuProvider>().loadMenuData();
      if (widget.autoFocusSearch && mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  bool _tabsInitializing = false;

  void _onMenuChanged() {
    if (!mounted || _tabsInitializing) return;
    final cats = context.read<MenuProvider>().categories;
    if (cats.isNotEmpty) {
      if (!_tabsReady || _tabController.length != cats.length) _initTabs();
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final difference = now.difference(widget.sessionStartTime!);
      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
      if (mounted) setState(() => _sessionDuration = hours == "00" ? '$minutes:$seconds' : '$hours:$minutes:$seconds');
    });
  }

  void _initTabs() {
    if (_tabsInitializing || !mounted) return;
    final cats = context.read<MenuProvider>().categories;
    if (cats.isEmpty) return;
    _tabsInitializing = true;
    if (_tabsReady) {
      _tabController.removeListener(_handleTabSelection);
      _tabController.dispose();
      _tabsReady = false;
    }
    int initIndex = 0;
    if (widget.category != null) {
      final matchIndex = cats.indexWhere((c) => c.toLowerCase() == widget.category!.toLowerCase());
      if (matchIndex != -1) {
        initIndex = matchIndex;
        context.read<MenuProvider>().loadItems(cats[matchIndex]);
      }
    } else if (context.read<MenuProvider>().selectedCategory.isNotEmpty) {
      final matchIndex = cats.indexWhere((c) => c.toLowerCase() == context.read<MenuProvider>().selectedCategory.toLowerCase());
      if (matchIndex != -1) initIndex = matchIndex;
    }
    _tabController = TabController(length: cats.length, vsync: this, initialIndex: initIndex);
    _tabController.addListener(_handleTabSelection);
    if (mounted) setState(() { _tabsReady = true; _tabsInitializing = false; });
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && mounted) {
      final cats = context.read<MenuProvider>().categories;
      if (_tabController.index < cats.length) context.read<MenuProvider>().loadItems(cats[_tabController.index]);
    }
  }

  @override
  void dispose() {
    context.read<MenuProvider>().removeListener(_onMenuChanged);
    _sessionTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _cartBounceController.dispose();
    if (_tabsReady) {
      _tabController.removeListener(_handleTabSelection);
      _tabController.dispose();
    }
    super.dispose();
  }

  IconData _iconForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('thali')) return Icons.restaurant_menu_rounded;
    if (c.contains('sweet')) return Icons.icecream_rounded;
    if (c.contains('farsan') || c.contains('snack')) return Icons.fastfood_rounded;
    if (c.contains('bread') || c.contains('roti')) return Icons.flatware_rounded;
    if (c.contains('drink') || c.contains('beverage')) return Icons.local_drink_rounded;
    if (c.contains('dal')) return Icons.soup_kitchen_rounded;
    if (c.contains('rice')) return Icons.rice_bowl_rounded;
    if (c.contains('sabzi')) return Icons.eco_rounded;
    if (c.contains('extra')) return Icons.add_circle_outline_rounded;
    return Icons.flatware_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    final cartProvider = context.watch<CartProvider>();

    final filteredItems = provider.allItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty || 
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCategory = true;
      if (_tabsReady) {
        final currentCat = provider.categories[_tabController.index];
        if (currentCat != "All") matchesCategory = item.category.toLowerCase() == currentCat.toLowerCase();
      }
      final matchesFavorite = !_showOnlyFavorites || provider.wishlistIds.contains(item.id);
      final matchesSpecial = !widget.showOnlySpecials || item.isRecommended || item.isPopular;
      return matchesSearch && matchesCategory && matchesFavorite && matchesSpecial;
    }).toList();

    if (cartProvider.items.length > _lastCartCount) _cartBounceController.forward(from: 0.0);
    _lastCartCount = cartProvider.items.length;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        appBar: AppBar(
          title: Text(
            widget.orderType == 'DINING' ? 'Dining Menu' : 'Govardhan Menu',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFF1A1A1A))),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (widget.orderType == 'DINING' && widget.sessionId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Container(
                    height: 40,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiningBillScreen(sessionId: widget.sessionId!, tableNumber: widget.tableNumber ?? widget.tableId ?? '?'))),
                      icon: const Icon(Icons.receipt_long, color: Color(0xFFFF6B00), size: 20),
                      label: Text('Bill', style: GoogleFonts.poppins(color: const Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ScaleTransition(
                  scale: _cartBounceAnimation,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFFF6B00).withValues(alpha: 0.08), shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFF6B00), size: 24),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(orderType: widget.orderType, sessionId: widget.sessionId, tableId: widget.tableId, tableNumber: widget.tableNumber))),
                        ),
                      ),
                      if (cartProvider.items.isNotEmpty)
                        Positioned(
                          right: -2, top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                            child: Text('${cartProvider.items.length}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          bottom: provider.isLoading || !_tabsReady
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      physics: const BouncingScrollPhysics(),
                      indicatorColor: const Color(0xFFFF6B00),
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: const Color(0xFFFF6B00),
                      unselectedLabelColor: const Color(0xFF7A7A7A),
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      tabs: provider.categories.map((c) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconForCategory(c), size: 16),
                            const SizedBox(width: 8),
                            Text(c),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
        ),
        body: provider.isLoading
            ? _buildShimmer()
            : Stack(
                children: [
                  Column(
                    children: [
                      if (widget.orderType == 'DINING') _buildSessionHeader(),
                      _buildSearchBar(),
                      Expanded(
                        child: filteredItems.isEmpty ? _buildEmpty() : _buildList(filteredItems),
                      ),
                    ],
                  ),
                  if (widget.orderType == 'DINING' && cartProvider.items.isNotEmpty)
                    Positioned(bottom: 20, left: 16, right: 16, child: _buildFloatingCart(cartProvider)),
                ],
              ),
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.indigo.shade50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.indigo.shade700, borderRadius: BorderRadius.circular(6)),
                  child: Text('Table ${widget.tableNumber ?? widget.tableId ?? '?'}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text('Dining Session Active', style: GoogleFonts.poppins(color: Colors.indigo.shade700, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          if (widget.sessionStartTime != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: Colors.indigo.shade700, size: 16),
                const SizedBox(width: 4),
                Text(_sessionDuration, style: GoogleFonts.poppins(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingCart(CartProvider cartProvider) {
    final subtotal = cartProvider.items.fold(0.0, (sum, i) => sum + i.price * i.quantity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.indigo.shade700, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('${cartProvider.items.length} items', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                Text('₹${subtotal.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(orderType: widget.orderType, sessionId: widget.sessionId, tableId: widget.tableId, tableNumber: widget.tableNumber))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo.shade700, padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
            child: Text('View Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade100,
        highlightColor: Colors.white,
        child: Container(height: 120, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search dishes...",
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF7A7A7A), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF6B00), size: 22),
                  filled: true, fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _showOnlyFavorites = !_showOnlyFavorites),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _showOnlyFavorites ? Colors.red.shade50 : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _showOnlyFavorites ? Colors.red.shade100 : Colors.grey.shade100)),
              child: Icon(_showOnlyFavorites ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: _showOnlyFavorites ? Colors.red : Colors.grey.shade400, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.restaurant_menu_rounded, size: 60, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text("No items found", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text("Try searching something else", style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14)),
    ]));
  }

  Widget _buildList(List<MenuItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => _MenuItemCard(item: items[i], index: i, onRefresh: () => setState(() {})),
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final MenuItem item;
  final int index;
  final VoidCallback onRefresh;
  const _MenuItemCard({required this.item, required this.index, required this.onRefresh});
  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> with SingleTickerProviderStateMixin {
  bool _isAdding = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _quickAdd() async {
    _controller.forward().then((_) => _controller.reverse());
    HapticFeedback.mediumImpact();
    setState(() => _isAdding = true);
    final ok = await context.read<CartProvider>().addItem(widget.item.id, 1, widget.item.price);
    setState(() => _isAdding = false);
    if (!mounted) return;
    scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
      content: Text(ok ? "${widget.item.name} added to cart" : "Failed to add ${widget.item.name}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: () async {
          _controller.forward().then((_) => _controller.reverse());
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
          widget.onRefresh();
        },
        child: Container(
          height: 145, // Increased height for description
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Stack( // Stack for the bestseller star
            children: [
              // Bestseller Star in corner
              if (item.isRecommended || item.isPopular)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFFFF9E5), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                  ),
                ),
              Row(
                children: [
                  // 1. Food Image + Wishlist
                  Stack(
                    children: [
                      Hero(
                        tag: 'item_${item.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: item.photoUrl,
                            width: 100, height: 121,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Shimmer.fromColors(baseColor: Colors.grey.shade100, highlightColor: Colors.white, child: Container(color: Colors.white)),
                            errorWidget: (_, __, ___) => Container(color: Colors.grey.shade50, child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 30)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6, left: 6,
                        child: GestureDetector(
                          onTap: () {
                            context.read<MenuProvider>().toggleWishlist(item.id);
                          },
                          child: Consumer<MenuProvider>(
                            builder: (context, menuProv, _) {
                              final isFav = menuProv.wishlistIds.contains(item.id);
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  size: 14,
                                  color: isFav ? Colors.red : const Color(0xFF1A1A1A),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // 2. Content Center
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(border: Border.all(color: item.isVeg ? const Color(0xFF4CAF50) : const Color(0xFFE53935)), borderRadius: BorderRadius.circular(2)),
                              child: Container(width: 6, height: 6, decoration: BoxDecoration(color: item.isVeg ? const Color(0xFF4CAF50) : const Color(0xFFE53935), shape: BoxShape.circle)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16))),
                          ],
                        ),
                        // Rating line
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                            const SizedBox(width: 2),
                            Text(item.rating.toString(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.grey.shade300)),
                            const SizedBox(width: 6),
                            Text(item.category, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Description
                        Text(item.description, 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                          style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12, height: 1.3)
                        ),
                        const Spacer(),
                        // Price (Bold Black)
                        Text('₹${item.price.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1A1A1A))),
                      ],
                    ),
                  ),
                  // 3. Action Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _isAdding 
                    ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B00))))
                    : Container(
                        width: 85, height: 38,
                        decoration: BoxDecoration(boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: ElevatedButton(
                          onPressed: _quickAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0, padding: EdgeInsets.zero,
                          ),
                          child: Text("Add +", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
