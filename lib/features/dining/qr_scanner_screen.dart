import 'dart:convert';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/token_manager.dart';
import '../login/login.dart';
import '../menu/menu_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // Parse if code is a URL and extract the last part (table ID)
  String _parseCode(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
      if (uri.queryParameters.containsKey('qrCode')) return uri.queryParameters['qrCode']!;
    } catch (_) {}
    return raw;
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String rawCode = barcodes.first.rawValue!;
      final String code = _parseCode(rawCode);
      _processQR(code);
    }
  }

  Future<void> _processQR(String code, {bool confirmSwitch = false}) async {
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    try {
      final result = await ApiService.verifyTable(code);
      if (!mounted) return;

      if (result['status'] == 'success' || result['success'] == true) {
        final table = result['data'] ?? result['table'];
        final tableId = (table?['table_id'] ?? table?['_id'] ?? '').toString();
        final tableNum = (table?['table_number'] ?? table?['tableNumber'] ?? 0).toString();

        // LOGIN REQUIRED RULE (Section 2)
        final loggedIn = await TokenManager.isLoggedIn();
        if (!loggedIn) {
          setState(() => _isProcessing = false);
          _showLoginRequiredDialog(tableId, tableNum);
          return;
        }

        final sessionResult = await ApiService.startDiningSession(tableId, confirmSwitch: confirmSwitch);
        if (!mounted) return;

        if (sessionResult['status'] == 'success' || sessionResult['success'] == true) {
          _handleSessionSuccess(sessionResult, tableId, tableNum);
        } else if (sessionResult['code'] == 'ACTIVE_SESSION_EXISTS' || sessionResult['message']?.toString().contains('already active') == true) {
          _showActiveSessionDialog(
            tableNum: tableNum,
            existingTable: sessionResult['existingTable']?.toString() ?? '?',
            onContinue: () => _handleSessionSuccess(sessionResult, tableId, tableNum, isExisting: true),
            onSwitch: () => _processQR(code, confirmSwitch: true),
          );
        } else {
          _showError(sessionResult['message'] ?? "Table is already occupied.");
        }
      } else {
        _showError(result['message'] ?? "Invalid QR Code.");
      }
    } catch (e) {
      _showError("Connection error. Check your internet.");
    }
  }

  void _showActiveSessionDialog({required String tableNum, required String existingTable, required VoidCallback onContinue, required VoidCallback onSwitch}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Active Session Found", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text(
          "You already have an active dining session at Table #$existingTable. Would you like to continue there or switch to Table #$tableNum?",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onContinue();
            },
            child: Text("CONTINUE T#$existingTable", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSwitch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("SWITCH TO T#$tableNum", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleSessionSuccess(Map sessionResult, String tableId, String tableNum, {bool isExisting = false}) async {
    _cameraController.stop();
    final sessionData = sessionResult['data'] ?? sessionResult;
    final sessionId = (sessionData?['session_id'] ?? sessionData?['_id'] ?? '').toString();
    final startTimeStr = (sessionData?['start_time'] ?? sessionData?['startTime']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_dining_session', jsonEncode({
      'sessionId': sessionId,
      'tableId': tableId,
      'tableNumber': tableNum,
      'orderType': 'DINING',
      'startTime': startTimeStr,
    }));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenuScreen(
            orderType: 'DINING',
            sessionId: sessionId,
            tableId: tableId,
            tableNumber: tableNum,
            sessionStartTime: startTimeStr != null ? DateTime.tryParse(startTimeStr.toString()) : null,
          ),
        ),
      );
    }
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Table Number", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter table number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                 _processQR("TABLE_QR_${controller.text.padLeft(3, '0')}");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6A00)),
            child: Text("PROCEED", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog(String tableId, String tableNum) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Login Required", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text(
          "You need to log in to place a dining order at Table #$tableNum. This helps us track your bill correctly.",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('pending_dining_table', tableId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("LOG IN NOW", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)), 
      backgroundColor: Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
      width: 250,
      height: 250,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
            scanWindow: scanWindow,
          ),
          // Professional Custom Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.7), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 250, height: 250,
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
          // Scanner Frame
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  _ScannerCorner(isTop: true, isLeft: true),
                  _ScannerCorner(isTop: true, isLeft: false),
                  _ScannerCorner(isTop: false, isLeft: true),
                  _ScannerCorner(isTop: false, isLeft: false),
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00))),
                ],
              ),
            ),
          ),
          // UI Elements
          Positioned(
            top: 50, left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: Column(
              children: [
                Text("SCAN TABLE QR", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text("Align QR within the frame to order", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _showManualEntry,
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                  label: Text("MANUAL ENTRY", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
          // Animated Scanning Line
          if (!_isProcessing) const _ScanningLine(),
        ],
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;
  const _ScannerCorner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isTop ? -2 : null,
      bottom: isTop ? null : -2,
      left: isLeft ? -2 : null,
      right: isLeft ? null : -2,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFFFF6A00), width: 4) : BorderSide.none,
            bottom: isTop ? BorderSide.none : const BorderSide(color: Color(0xFFFF6A00), width: 4),
            left: isLeft ? const BorderSide(color: Color(0xFFFF6A00), width: 4) : BorderSide.none,
            right: isLeft ? BorderSide.none : const BorderSide(color: Color(0xFFFF6A00), width: 4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(15) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(15) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(15) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(15) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final top = (MediaQuery.of(context).size.height / 2 - 125) + (250 * _anim.value);
        return Positioned(
          top: top, left: MediaQuery.of(context).size.width / 2 - 110,
          child: Container(
            width: 220, height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.withValues(alpha: 0), const Color(0xFFFF6A00), Colors.orange.withValues(alpha: 0)]),
              boxShadow: [BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
            ),
          ),
        );
      },
    );
  }
}
