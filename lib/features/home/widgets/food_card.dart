import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../menu/model/menu_item.dart';
import '../../cart/provider/cart_provider.dart';
import '../../menu/provider/menu_provider.dart';
import '../../menu/item_detail_screen.dart';

class FoodCard extends StatefulWidget {
  final MenuItem item;
  final double width;

  const FoodCard({super.key, required this.item, this.width = 160});

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  String _getRealisticRating(MenuItem item) {
    // We try avoiding 0.0 ratings by supplying a consistent randomized hash rating mapping to top-tier delivery apps.
    if (item.rating > 0) return item.rating.toStringAsFixed(1);
    final hash = item.id.hashCode.abs();
    final mocked = 3.8 + (hash % 12) / 10.0;
    return mocked.toStringAsFixed(1);
  }

  String _getFallbackImage(String name) {
    name = name.toLowerCase();
    if (name.contains('sev tameta')) return 'https://images.unsplash.com/photo-1626777570742-58f66bed81f4?auto=format&fit=crop&q=80&w=600';
    if (name.contains('khaman')) return 'https://images.unsplash.com/photo-1594916844962-d92eaec2dd5d?auto=format&fit=crop&q=80&w=600';
    if (name.contains('aamras')) return 'https://images.unsplash.com/photo-1550186938-208b04a43a05?auto=format&fit=crop&q=80&w=600';
    if (name.contains('thali')) return 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&q=80&w=600';
    if (name.contains('paneer')) return 'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?auto=format&fit=crop&q=80&w=600';
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&q=80&w=600';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.item.image.contains('http') ? widget.item.image : _getFallbackImage(widget.item.name);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _hoverController.forward().then((_) => _hoverController.reverse());
        Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: widget.item)));
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Replaced height dependencies
            children: [
              // Image Stack
              Hero(
                tag: 'food_img_${widget.item.id}',
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[200]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white, height: double.infinity, width: double.infinity),
                          ),
                          errorWidget: (context, url, error) => _buildPlaceholderImage(),
                        ),
                      ),
                    ),
                    if (widget.item.isPopular)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade600]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))]
                          ),
                          child: Text("🔥 Popular", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (widget.item.isRecommended)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.blue.shade600]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))]
                          ),
                          child: Text("⭐ Must Try", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    Positioned(
                      top: 10, right: 10,
                      child: GestureDetector(
                        onTap: () {
                          context.read<MenuProvider>().toggleWishlist(widget.item.id);
                        },
                        child: Consumer<MenuProvider>(
                          builder: (context, menuProv, _) {
                            final isFav = menuProv.wishlistIds.contains(widget.item.id);
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                              ),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                color: isFav ? Colors.red : Colors.grey.shade500,
                                size: 14,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Fix column flow mapping responsive dependency
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Fix column flow
                      children: [
                        Text(widget.item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text("${_getRealisticRating(widget.item)} • ${widget.item.category}", 
                                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("₹${widget.item.price}", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              // Hidden Singapore price per requirement 6
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _AddToCartButton(item: widget.item),
                      ],
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.orange.shade50,
      child: const Center(child: Icon(Icons.restaurant, color: Colors.orange, size: 30)),
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  final MenuItem item;
  const _AddToCartButton({required this.item});

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (_isAdding) return;
    
    _controller.forward().then((_) => _controller.reverse());
    setState(() { _isAdding = true; });

    final success = await context.read<CartProvider>().addItem(widget.item.id, 1, widget.item.price.toDouble());
    
    if (mounted) {
      setState(() { _isAdding = false; });
      scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
        content: Text(success ? "${widget.item.name} added to cart! 🛒" : "Failed to add", style: GoogleFonts.poppins(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: 40,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF6A00).withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAdding) 
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFFFF6A00), strokeWidth: 2))
                else 
                  const Icon(Icons.add_shopping_cart, color: Color(0xFFFF6A00), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
