import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../main/main_screen.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../menu/menu_screen.dart';
import '../registration/registration_screen.dart';
import 'forgot_password_flow.dart';
import '../../services/token_manager.dart';
import '../../services/socket_service.dart';
import '../splash/thali_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final mobile = _mobileController.text.trim();
      final password = _passwordController.text.trim();

      // Ensure login function awaits API call
      final result = await ApiService.login(mobile, password);

      if (!mounted) return;

      // Add response validation: check for boolean success field
      if (result['success'] == true) {
        final data = result['data'];
        final user = data['user'];
        final accessToken = data['accessToken'] ?? data['token'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';

        await TokenManager.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );

        if (!mounted) return;
        bool isDesktop = false;
          if (kIsWeb) {
            isDesktop = true;
          } else {
            isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
          }

          if (isDesktop) {
            await TokenManager.clearAll();
            _showMessage("Desktop App is for Admins only!", isError: true);
          } else {
            // Real-time: Join user room for status updates
            SocketService().connect();
            SocketService().joinUserRoom(user['user_id'] ?? user['id'] ?? user['_id']);

            // RESUME SESSION RULE (Section 2)
            final prefs = await SharedPreferences.getInstance();
            final pendingTableId = prefs.getString('pending_dining_table');
            if (pendingTableId != null) {
              await prefs.remove('pending_dining_table');
              if (mounted) {
                // Ensure navigation triggers after login success
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MenuScreen(
                  orderType: 'DINING',
                  tableId: pendingTableId,
                )));
              }
            } else {
              if (mounted) {
                // Ensure navigation triggers after login success
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              }
            }
          }
      } else {
        _showMessage(result['message'] ?? "Invalid credentials", isError: true);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      if (!mounted) return;
      // Add proper error handling
      _showMessage("Server error. Check your connection.", isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isGoogleLoading = true; });
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() { _isGoogleLoading = false; });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // INTEGRATION: Call backend to create/verify user and get JWT
        final result = await ApiService.firebaseLogin(
          firebaseUID: userCredential.user!.uid,
          email: userCredential.user!.email ?? "",
          name: userCredential.user!.displayName ?? "Google User",
          profileImage: userCredential.user!.photoURL ?? "",
        );

        if (result['success'] == true) {
          final data = result['data'];
          final user = data['user'];
          final accessToken = data['accessToken'] ?? data['token'] ?? '';
          final refreshToken = data['refreshToken'] ?? '';

          // Save JWT and User Session info for the app
          await TokenManager.saveSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: user,
            loginType: 'google',
          );

          if (!mounted) return;
          bool isDesktop = false;
          if (kIsWeb) {
            isDesktop = true;
          } else {
            isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
          }

          if (isDesktop) {
            await TokenManager.clearAll();
            _showMessage("Desktop App is for Admins only!", isError: true);
          } else {
            // Real-time: Join user room for status updates
            SocketService().connect();
            SocketService().joinUserRoom(user['user_id'] ?? user['id'] ?? user['_id']);

            // RESUME SESSION RULE (Section 2)
            final prefs = await SharedPreferences.getInstance();
            final pendingTableId = prefs.getString('pending_dining_table');
            if (pendingTableId != null) {
              await prefs.remove('pending_dining_table');
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MenuScreen(
                  orderType: 'DINING',
                  tableId: pendingTableId,
                )));
              }
            } else {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              }
            }
          }
        } else {
          _showMessage(result['message'] ?? "Backend validation failed", isError: true);
        }
      }
    } catch (e) {
      _showMessage("Google Sign-In Failed.", isError: true);
    } finally {
      if (mounted) setState(() { _isGoogleLoading = false; });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (scaffoldMessengerKey.currentState == null) return;
    scaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B00),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER (Height ~35%)
            Container(
              height: screenHeight * 0.35,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top Right Skip Button
                  if (!(kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))))
                    Positioned(
                      top: 10,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())),
                        child: Text(
                          "Skip Login",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ThaliLogo(size: 85),
                      const SizedBox(height: 20),
                      Text(
                        "Govardhan Thal",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// WHITE FORM CONTAINER
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Mobile Number"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _mobileController,
                          hint: "Enter Mobile Number",
                          prefixText: "+91",
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          validator: (v) => v!.length != 10 ? 'Must be 10 digits' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Password"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: "••••••••",
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                          validator: (v) => v!.isEmpty ? 'Enter password' : null,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordFlow()));
                            }, 
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFF6B00),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildPrimaryButton(
                          text: "Sign In",
                          isLoading: _isLoading,
                          onPressed: _login,
                        ),

                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or sign in with",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _buildGoogleButton(
                          onPressed: _signInWithGoogle,
                          isLoading: _isGoogleLoading,
                        ),

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
                              child: Text(
                                "Sign Up",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFF6B00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? prefixText,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.normal, color: const Color(0xFF1A1A1A)),
      validator: validator,
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefixText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(prefixText, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B00))),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: const Color(0xFFE8E8E8)),
                  ],
                ),
              )
            : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400, size: 20),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1)),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required bool isLoading, required VoidCallback? onPressed}) {
    return _PressableScale(
      onPressed: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B00),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(text, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }

  Widget _buildGoogleButton({required VoidCallback onPressed, required bool isLoading}) {
    return _PressableScale(
      onPressed: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             if (isLoading)
                const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFFFF6B00), strokeWidth: 2))
             else ...[
                Image.asset("assets/images/google.webp", height: 20, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 20)),
                const SizedBox(width: 12),
                Text("Continue with Google", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
             ],
          ],
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const _PressableScale({required this.child, this.onPressed});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
