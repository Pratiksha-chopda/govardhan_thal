import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../menu/model/menu_item.dart';
import '../cart/provider/cart_provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final MenuItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  int _qty = 1;
  bool _isAdding = false;
  late AnimationController _addAnimController;
  late Animation<double> _addScaleAnim;

  @override
  void initState() {
    super.initState();
    _addAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _addScaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _addAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _addAnimController.dispose();
    super.dispose();
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

  Future<void> _addToCart() async {
    HapticFeedback.heavyImpact();
    _addAnimController.forward().then((_) => _addAnimController.reverse());
    setState(() => _isAdding = true);

    final ok = await context
        .read<CartProvider>()
        .addItem(widget.item.id, _qty, widget.item.price);

    setState(() => _isAdding = false);

    if (!mounted) return;
    if (ok) {
      scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text("${widget.item.name} added to cart!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
      Navigator.pop(context); 
    } else {
      scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
        content: Text("Failed to add item. Try again.", style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final total = item.price * _qty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: const Color(0xFFFF6A00),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'item_${item.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.white,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFFF6A00).withValues(alpha: 0.05),
                            child: Center(child: Text(_emojiForCategory(item.category), style: const TextStyle(fontSize: 100))),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.isPopular || item.isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.isRecommended ? '✨ BESTSELLER' : '🔥 POPULAR',
                            style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                          ),
                        ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(item.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), letterSpacing: -0.2)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: item.isVeg ? const Color(0xFF4CAF50) : const Color(0xFFE53935), width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: item.isVeg ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Increased gap

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(item.rating.toStringAsFixed(1), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text("${item.category}", style: GoogleFonts.poppins(color: const Color(0xFF7A7A7A), fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          Text("₹${item.price.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: Color(0xFFF0F0F0), thickness: 0.8),
                      ),

                      Text("About this item", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                      const SizedBox(height: 12),
                      Text(item.description.isEmpty ? "Crafted with passion using authentic Gujarati spices and farm-fresh ingredients. A signature dish that brings the taste of tradition to your plate." : item.description,
                          style: GoogleFonts.poppins(color: const Color(0xFF7A7A7A), fontSize: 14, height: 1.6, fontWeight: FontWeight.w400)),

                      const SizedBox(height: 32),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _infoChip(Icons.access_time_rounded, "Fresh Prep"),
                          _infoChip(Icons.eco_outlined, item.isVeg ? "100% Veg" : "Non-Veg"),
                          _infoChip(Icons.local_fire_department_rounded, item.isPopular ? "Highly Rated" : "Traditional"),
                          _infoChip(Icons.restaurant_menu_rounded, "Chef Special"),
                        ],
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Select Quantity", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text("How many would you like?", style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A7A7A))),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6A00).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _qtyButton(Icons.remove_rounded, () {
                                  if (_qty > 1) setState(() => _qty--);
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text('$_qty', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFFFF6A00))),
                                ),
                                _qtyButton(Icons.add_rounded, () => setState(() => _qty++)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, -5)),
                ],
              ),
              child: ScaleTransition(
                scale: _addScaleAnim,
                child: Container(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isAdding ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: _isAdding
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Add to Cart", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text("₹${total.toStringAsFixed(0)}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFF6A00)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A4A4A))),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: const Color(0xFFFF6A00), size: 22),
      ),
    );
  }
}
