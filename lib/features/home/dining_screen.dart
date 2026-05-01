import 'package:flutter/material.dart';
import '../dining/qr_scanner_screen.dart';

/// DiningScreen now directly redirects to the QRScannerScreen
/// to avoid the confusing two-step flow (placeholder → scanner).
class DiningScreen extends StatefulWidget {
  const DiningScreen({super.key});

  @override
  State<DiningScreen> createState() => _DiningScreenState();
}

class _DiningScreenState extends State<DiningScreen> {
  @override
  void initState() {
    super.initState();
    // Immediately navigate to QR scanner on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QRScannerScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple loading state while navigating
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
      ),
    );
  }
}
