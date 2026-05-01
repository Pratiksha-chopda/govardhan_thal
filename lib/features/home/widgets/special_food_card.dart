import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../menu/model/menu_item.dart';
import '../../cart/provider/cart_provider.dart';
import '../../menu/item_detail_screen.dart';

class SpecialFoodCard extends StatefulWidget {
  final MenuItem item;
  final double width;

  const SpecialFoodCard({super.key, required this.item, this.width = 240});

  @override
  State<SpecialFoodCard> createState() => _SpecialFoodCardState();
}

class _SpecialFoodCardState extends State<SpecialFoodCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(_hoverController);
    
    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  String _getRealisticRating(MenuItem item) {
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
        _hoverController.reset();
        _hoverController.forward();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: widget.item)));
        });
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            children: [
              Container(
                width: widget.width,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: child,
              ),
              // Subtle shine reflection effect
              if (_hoverController.isAnimating)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return LinearGradient(
                              begin: Alignment(_shineAnimation.value - 1, -1),
                              end: Alignment(_shineAnimation.value, 1),
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Area
            Hero(
              tag: 'special_img_${widget.item.id}',
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        errorWidget: (context, url, error) => Container(
                          color: Colors.orange.shade50,
                          child: const Center(child: Icon(Icons.restaurant_menu, color: Colors.orange, size: 40)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(_getRealisticRating(widget.item), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Icon(Icons.circle, color: widget.item.isVeg ? Colors.green.shade600 : Colors.red.shade600, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // Text Details Area
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.orange.shade50.withValues(alpha: 0.3)],
                )
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.restaurant, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text("North Indian • ${widget.item.category}", 
                          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                       Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("₹${widget.item.price}", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SpecialAddToCartBtn(item: widget.item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecialAddToCartBtn extends StatefulWidget {
  final MenuItem item;
  const SpecialAddToCartBtn({required this.item, super.key});

  @override
  State<SpecialAddToCartBtn> createState() => _SpecialAddToCartBtnState();
}

class _SpecialAddToCartBtnState extends State<SpecialAddToCartBtn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
        content: Text(success ? "${widget.item.name} added! 🛒" : "Failed to add", style: GoogleFonts.poppins(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF5200)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAdding) 
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else 
                  Text("ADD", style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
