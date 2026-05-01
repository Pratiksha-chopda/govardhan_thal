import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final otpController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: _box(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter OTP",
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (otpController.text == "123456") {
                    Navigator.pop(context, true);
                  } else {
                    scaffoldMessengerKey.currentState!.showSnackBar(
                      const SnackBar(content: Text("Invalid OTP")),
                    );
                  }
                },
                child: const Text("Verify"),
              ),
            ],
          ),
        ),
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
