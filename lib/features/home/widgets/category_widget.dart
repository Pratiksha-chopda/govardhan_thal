import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../menu/menu_screen.dart';

class CategoryWidget extends StatefulWidget {
  final Map<String, String> category;
  final int index;

  const CategoryWidget({super.key, required this.category, required this.index});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<List<Color>> _bgGradients = [
    [Colors.orange.shade300, Colors.orange.shade500],
    [Colors.green.shade300, Colors.green.shade500],
    [Colors.purple.shade300, Colors.purple.shade500],
    [Colors.blue.shade300, Colors.blue.shade500],
    [Colors.red.shade300, Colors.red.shade500],
    [Colors.teal.shade300, Colors.teal.shade500],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Animate the scale
    _controller.forward().then((_) => _controller.reverse());
    // Navigate immediately — do NOT call loadMenuData() here.
    // MenuScreen handles its own data loading. Calling it here causes
    // two concurrent loadMenuData() calls which floods notifyListeners()
    // and produces the ANR cascade.
    final catLabel = widget.category["label"]!;
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => MenuScreen(category: catLabel),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn)
          ),
          child: child,
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _bgGradients[widget.index % _bgGradients.length];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 80,
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: gradientColors[1].withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(widget.category["emoji"]!, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.category["label"]!,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
