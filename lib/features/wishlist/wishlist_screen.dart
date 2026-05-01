import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../menu/provider/menu_provider.dart';
import '../cart/provider/cart_provider.dart';
import '../menu/model/menu_item.dart' as model;
import '../menu/item_detail_screen.dart';
import '../../core/globals.dart';

/// ─────────────────────────────────────────────────────────────
/// WishlistScreen — Shows all items the user has favorited.
///
/// Uses MenuProvider.wishlistIds + allItems to filter locally,
/// with a pull-to-refresh that re-fetches from the server.
/// ─────────────────────────────────────────────────────────────
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MenuProvider>().fetchWishlist();
      if (mounted) setState(() => _isLoading = false);
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<MenuProvider>().fetchWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text("My Favourites",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, _) {
        final wishlistItems = menuProvider.allItems
            .where((item) => menuProvider.wishlistIds.contains(item.id))
            .toList();

        if (wishlistItems.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            color: const Color(0xFFFF6A00),
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              itemCount: wishlistItems.length,
              itemBuilder: (context, index) {
                return _WishlistItemCard(
                  item: wishlistItems[index],
                  index: index,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_outline_rounded,
                size: 60, color: Colors.red.shade300),
          ),
          const SizedBox(height: 28),
          Text("No Favourites Yet",
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: Text(
                "Tap the ❤️ on any dish to save\nit to your favourites!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu_rounded,
                color: Colors.white, size: 18),
            label: Text("Explore Menu",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.3),
            ),
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
        child: Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20))),
      ),
    );
  }
}

class _WishlistItemCard extends StatefulWidget {
  final model.MenuItem item;
  final int index;
  const _WishlistItemCard({required this.item, required this.index});

  @override
  State<_WishlistItemCard> createState() => _WishlistItemCardState();
}

class _WishlistItemCardState extends State<_WishlistItemCard>
    with SingleTickerProviderStateMixin {
  bool _isAdding = false;
  bool _isRemoving = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_isAdding) return;
    HapticFeedback.mediumImpact();
    setState(() => _isAdding = true);
    final ok = await context
        .read<CartProvider>()
        .addItem(widget.item.id, 1, widget.item.price);
    setState(() => _isAdding = false);
    if (!mounted) return;
    scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
      content: Text(
          ok
              ? "${widget.item.name} added to cart! 🛒"
              : "Failed to add ${widget.item.name}",
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500)),
      backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _removeFromWishlist() async {
    if (_isRemoving) return;
    HapticFeedback.lightImpact();
    setState(() => _isRemoving = true);
    await context.read<MenuProvider>().toggleWishlist(widget.item.id);
    if (!mounted) return;
    setState(() => _isRemoving = false);
    scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
      content: Text("${widget.item.name} removed from favourites",
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500)),
      backgroundColor: Colors.grey.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: "UNDO",
        textColor: const Color(0xFFFF6A00),
        onPressed: () {
          context.read<MenuProvider>().toggleWishlist(widget.item.id);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imageUrl = item.photoUrl;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + widget.index * 80),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: () {
            _controller.forward().then((_) => _controller.reverse());
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item)));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                // Image
                Hero(
                  tag: 'wishlist_${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade100,
                        highlightColor: Colors.white,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade50,
                          child: const Icon(Icons.fastfood_rounded,
                              color: Colors.grey, size: 30)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: item.isVeg
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE53935)),
                                borderRadius: BorderRadius.circular(2)),
                            child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: item.isVeg
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE53935),
                                    shape: BoxShape.circle)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFB300), size: 14),
                          const SizedBox(width: 2),
                          Text(item.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Text('•',
                              style:
                                  TextStyle(color: Colors.grey.shade300)),
                          const SizedBox(width: 6),
                          Text(item.category,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${item.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: const Color(0xFF1A1A1A))),
                          Row(
                            children: [
                              // Remove from wishlist
                              GestureDetector(
                                onTap: _removeFromWishlist,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _isRemoving
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.red.shade400))
                                      : Icon(Icons.favorite_rounded,
                                          color: Colors.red.shade400,
                                          size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Add to cart
                              GestureDetector(
                                onTap: _addToCart,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6A00),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFFFF6A00)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3))
                                    ],
                                  ),
                                  child: _isAdding
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : Text("Add",
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
