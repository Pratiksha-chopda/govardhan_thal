import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0 = Mobile, 1 = OTP, 2 = New Password

  final _mobileController = TextEditingController();
  final _otp1 = TextEditingController();
  final _otp2 = TextEditingController();
  final _otp3 = TextEditingController();
  final _otp4 = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _mobile = "";
  String _otp = "";
  String _maskedEmail = "";

  // Resend OTP timer
  int _resendSeconds = 0;
  Timer? _resendTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _resendTimer?.cancel();
    _mobileController.dispose();
    _otp1.dispose();
    _otp2.dispose();
    _otp3.dispose();
    _otp4.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (!mounted) return;
    _animController.reset();
    setState(() => _currentStep = step);
    _animController.forward();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendSeconds--);
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
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

  // ── Step 1: Send OTP via Backend (Email) ──
  Future<void> _sendOtp({bool isResend = false}) async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      _showMessage("Enter a valid 10-digit mobile number", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.forgotPassword(mobile);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _mobile = mobile;
      _maskedEmail = result['data']?['maskedEmail'] ?? result['maskedEmail'] ?? '';
      _startResendTimer();
      if (!isResend) _goToStep(1);
      _showMessage(result['message'] ?? "OTP sent successfully to your email");

      // Dev fallback: show OTP if email isn't configured
      final devOtp = result['data']?['devOtp'] ?? result['devOtp'];
      if (devOtp != null) {
        Future.delayed(const Duration(seconds: 1), () {
          _showMessage("DEV: OTP is $devOtp");
        });
      }
    } else {
      _showMessage(result['message'] ?? "Failed to send OTP", isError: true);
    }
  }

  // ── Step 2: Verify OTP ──
  Future<void> _verifyOtp() async {
    final otp = _otp1.text + _otp2.text + _otp3.text + _otp4.text;
    if (otp.length < 4) {
      _showMessage("Please enter the complete 4-digit OTP", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.verifyOtp(_mobile, otp);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _otp = otp;
      _goToStep(2);
      _showMessage("OTP verified successfully!");
    } else {
      _showMessage(result['message'] ?? "Invalid or expired OTP", isError: true);
    }
  }

  // ── Step 3: Reset Password ──
  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters", isError: true);
      return;
    }
    if (password != confirm) {
      _showMessage("Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.resetPassword(_mobile, _otp, password);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 52),
              ),
              const SizedBox(height: 20),
              Text("Password Reset\nSuccessful!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("You can now login with your new password.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("Go to Login",
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _showMessage(result['message'] ?? "Failed to reset password", isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              _goToStep(_currentStep - 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text("Forgot Password",
            style: GoogleFonts.poppins(
                color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 36),

                // Step content
                if (_currentStep == 0) _buildMobileStep(),
                if (_currentStep == 1) _buildOtpStep(),
                if (_currentStep == 2) _buildPasswordStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step Indicator Dots ──
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 8,
          width: isActive ? 32 : 8,
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green.shade400
                : isActive
                    ? const Color(0xFFFF6B00)
                    : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 1: MOBILE NUMBER
  // ══════════════════════════════════════════════════════════
  Widget _buildMobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Illustration icon
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 56, color: Color(0xFFFF6B00)),
          ),
        ),
        const SizedBox(height: 28),
        Text("Enter Mobile Number",
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Text("We'll send a 4-digit verification code to your registered email address.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
        const SizedBox(height: 28),
        _buildStyledTextField(
          controller: _mobileController,
          hint: "Enter 10-digit mobile number",
          prefixText: "+91",
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 32),
        _buildActionButton(
          text: "Send Request",
          onPressed: () => _sendOtp(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 2: OTP VERIFICATION
  // ══════════════════════════════════════════════════════════
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 56, color: Color(0xFFFF6B00)),
          ),
        ),
        const SizedBox(height: 28),
        Text("Verify Email Code",
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            children: [
              const TextSpan(text: "Enter the secure 4-digit code sent to "),
              TextSpan(
                text: _maskedEmail.isNotEmpty ? _maskedEmail : _mobile,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFFF6B00)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // OTP Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOtpBox(_otp1, autoFocus: true),
            _buildOtpBox(_otp2),
            _buildOtpBox(_otp3),
            _buildOtpBox(_otp4),
          ],
        ),
        const SizedBox(height: 24),

        // Resend OTP
        Center(
          child: _resendSeconds > 0
              ? Text("Resend Email in ${_resendSeconds}s",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500))
              : TextButton(
                  onPressed: () => _sendOtp(isResend: true),
                  child: Text("Resend Email Code",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF6B00))),
                ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          text: "Verify & Continue",
          onPressed: _verifyOtp,
        ),
      ],
    );
  }

  Widget _buildOtpBox(TextEditingController controller, {bool autoFocus = false}) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextFormField(
        controller: controller,
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 2)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          } else {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 3: NEW PASSWORD
  // ══════════════════════════════════════════════════════════
  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.password_rounded, size: 56, color: Color(0xFFFF6B00)),
          ),
        ),
        const SizedBox(height: 28),
        Text("Create New Password",
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Text("Your new password must be at least 6 characters long.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
        const SizedBox(height: 28),
        _buildStyledTextField(
          controller: _passwordController,
          hint: "New Password",
          isPassword: true,
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),
        _buildStyledTextField(
          controller: _confirmPasswordController,
          hint: "Confirm Password",
          isPassword: true,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 32),
        _buildActionButton(
          text: "Reset Password",
          onPressed: _resetPassword,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ══════════════════════════════════════════════════════════

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    String? prefixText,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1A1A1A)),
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
                    Text(prefixText,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B00))),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: const Color(0xFFE8E8E8)),
                  ],
                ),
              )
            : isPassword
                ? const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.lock_outline, color: Color(0xFFFF6B00), size: 20),
                  )
                : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20),
                onPressed: onToggle,
              )
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1)),
      ),
    );
  }

  Widget _buildActionButton({required String text, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: _isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFF8C33)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
