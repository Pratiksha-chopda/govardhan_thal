import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Mobile Verification")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: _box(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter Mobile Number",
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixText: "+91 ",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  _showOtpPopup(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OtpScreen()),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text("Send OTP"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOtpPopup(BuildContext context) {
    scaffoldMessengerKey.currentState!.showSnackBar(
      const SnackBar(
        content: Text("OTP sent: 123456"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.orange.withValues(alpha: 0.25),
        blurRadius: 10,
      )
    ],
  );
}
