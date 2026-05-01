import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const CustomEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: const Color(0xFFFF6A00).withOpacity(0.6)),
            ),
            const SizedBox(height: 35),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (buttonText != null && onButtonPressed != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(buttonText!, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
