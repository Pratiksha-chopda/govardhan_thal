import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main/main_screen.dart';
import '../../services/api_service.dart';
import '../../services/token_manager.dart';
import '../splash/thali_logo.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showMessage("Please agree to the Terms to continue.", isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final mobile = _mobileController.text.trim();
      final password = _passwordController.text.trim();

      // Ensure register function awaits API call
      final result = await ApiService.register(name, email, mobile, password);

      if (!mounted) return;

      // Add response validation: check for boolean success field
      if (result['success'] == true) {
        _showMessage("Account created! Please log in.", isError: false);
        // Ensure navigation triggers after registration success
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showMessage(result['message'] ?? "Registration failed", isError: true);
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      if (!mounted) return;
      // Add proper error handling
      _showMessage("Server error. Check your connection.", isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() { _isGoogleLoading = true; });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() { _isGoogleLoading = false; });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, 
        idToken: googleAuth.idToken
      );

      if (googleAuth.idToken == null) {
        throw Exception("Google auth failed: idToken is null");
      }

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final result = await ApiService.firebaseLogin(
          firebaseUID: userCredential.user!.uid,
          email: userCredential.user!.email ?? "",
          name: userCredential.user!.displayName ?? "Google User",
          profileImage: userCredential.user!.photoURL ?? "",
        );

        if (!mounted) return;
        
        if (result['success'] == true) {
          final data = result['data'];
          final user = data['user'];
          final accessToken = data['accessToken'] ?? data['token'] ?? '';
          final refreshToken = data['refreshToken'] ?? '';

          await TokenManager.saveSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: user,
            loginType: 'google',
          );
        } else {
          _showMessage(result['message'] ?? "Google registration failed", isError: true);
          return;
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage("Google Registration Failed: ${e.toString()}", isError: true);
      }
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
            Expanded(child: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13))),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const ThaliLogo(size: 80),
                      const SizedBox(height: 16),
                      Text(
                        "Create Account", 
                        style: GoogleFonts.poppins(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: const Color(0xFF1A1A1A),
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Join the world of Govardhan Thal", 
                        style: GoogleFonts.poppins(
                          fontSize: 14, 
                          color: Colors.grey.shade600,
                        )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildInputLabel("Full Name"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController, hint: "Enter your full name",
                  keyboardType: TextInputType.name,
                  validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),
                _buildInputLabel("Email Address (Optional)"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController, hint: "Enter your email",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildInputLabel("Mobile Number"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _mobileController, hint: "Enter Mobile Number",
                  prefixText: "+91", keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (val) => val!.length != 10 ? 'Must be 10 digits' : null,
                ),
                const SizedBox(height: 14),
                _buildInputLabel("Password"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController, hint: "Password (8+ characters)",
                  isPassword: true, obscure: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (val.length < 8) return 'Minimum 8 characters required';
                    if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must contain an uppercase letter';
                    if (!RegExp(r'[a-z]').hasMatch(val)) return 'Must contain a lowercase letter';
                    if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must contain at least one number';
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) return 'Must contain a special character';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildInputLabel("Confirm Password"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _confirmPasswordController, hint: "Re-enter password",
                  isPassword: true, obscure: _obscureConfirmPassword,
                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please confirm your password';
                    if (val != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20, width: 20,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                        onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF5A5A5A), height: 1.4),
                          children: const [
                            TextSpan(text: "I read and agreed to "),
                            TextSpan(text: "User Agreement", style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.w600)),
                            TextSpan(text: " and "),
                            TextSpan(text: "Privacy Policy", style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildPrimaryButton(text: "Create Account", isLoading: _isLoading, onPressed: _signUp),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("Or sign up with", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13))),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildGoogleButton(onPressed: _signUpWithGoogle, isLoading: _isGoogleLoading),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text("Sign In", style: GoogleFonts.poppins(color: const Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)));
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
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
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
