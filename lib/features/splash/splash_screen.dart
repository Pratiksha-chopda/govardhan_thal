import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../login/login.dart';
import '../main/main_screen.dart';
import '../../services/token_manager.dart';
import '../../services/socket_service.dart';
import 'thali_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Timer(const Duration(seconds: 2), () async {
      // Auto-login: check if user is already logged in with JWT
      final token = await TokenManager.getAccessToken();
      
      bool isDesktop = false;
      if (kIsWeb) {
        isDesktop = true;
      } else {
        isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      }
      
      Widget nextScreen;
      
      if (token != null && token.isNotEmpty) {
        // Initialize Socket
        SocketService().connect();
        final userId = await TokenManager.getUserId();
        
        // Normal user
        if (userId != null) SocketService().joinUserRoom(userId);
          
        if (isDesktop) {
          // Force logout if a regular user tries to run the app as desktop build
          await TokenManager.clearAll();
          SocketService().disconnect();
          nextScreen = const LoginScreen();
        } else {
          nextScreen = const MainScreen();
        }
      } else {
        nextScreen = const LoginScreen();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF7A00), Color(0xFFFF5A00)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Modern Thali Logo (Size increased by 12%)
                      const ThaliLogo(size: 90), 

                      const SizedBox(height: 20),

                      // Premium Branding
                      Text(
                        "Govardhan Thal",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Taste the Heart of Gujarat",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
