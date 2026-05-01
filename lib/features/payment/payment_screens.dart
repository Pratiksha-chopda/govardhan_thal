import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import '../../services/payment_service.dart';

class UPIPaymentScreen extends StatefulWidget {
  final double amount;
  final String upiApp;
  final Function(PaymentResponse response) onPaymentComplete;

  const UPIPaymentScreen({
    super.key,
    required this.amount,
    required this.upiApp,
    required this.onPaymentComplete,
  });

  @override
  _UPIPaymentScreenState createState() => _UPIPaymentScreenState();
}

class _UPIPaymentScreenState extends State<UPIPaymentScreen> {
  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  void _startPayment() async {
    final response = await PaymentService.processUPI(widget.upiApp, widget.amount);
    if (mounted) {
      widget.onPaymentComplete(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Image.network(
                _getUpiLogo(widget.upiApp),
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.account_balance, size: 50, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Redirecting to UPI App",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Paying ₹${widget.amount.toStringAsFixed(2)} to Govardhan Thal",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 50),
            const Text(
               "Do not close this window or press back",
               style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _getUpiLogo(String app) {
     if (app == 'Google Pay') return 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Google_Pay_Logo_%282020%29.svg/512px-Google_Pay_Logo_%282020%29.svg.png';
     if (app == 'PhonePe') return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/PhonePe_Logo.svg/512px-PhonePe_Logo.svg.png';
     if (app == 'Paytm') return 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Paytm_Logo_%28standalone%29.svg/512px-Paytm_Logo_%28standalone%29.svg.png';
     return '';
  }
}

class CardPaymentScreen extends StatefulWidget {
  final double amount;
  final Function(PaymentResponse response) onPaymentComplete;

  const CardPaymentScreen({
    super.key,
    required this.amount,
    required this.onPaymentComplete,
  });

  @override
  _CardPaymentScreenState createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isProcessing = false;

  void _pay() async {
    if (_cardNumberController.text.length < 16) {
       scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(content: Text("Invalid card number")));
       return;
    }
    setState(() => _isProcessing = true);
    final response = await PaymentService.processCard(
      cardNumber: _cardNumberController.text,
      expiry: _expiryController.text,
      cvv: _cvvController.text,
      amount: widget.amount,
    );
    if (mounted) {
       widget.onPaymentComplete(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Enter Card Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.credit_card, color: Colors.white, size: 30),
                       Text("VISA / MASTERCARD", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _cardNumberController.text.isEmpty ? "XXXX XXXX XXXX XXXX" : _cardNumberController.text.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} "),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("EXPIRY", style: TextStyle(color: Colors.white54, fontSize: 10)),
                          Text(_expiryController.text.isEmpty ? "MM/YY" : _expiryController.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CVV", style: TextStyle(color: Colors.white54, fontSize: 10)),
                          Text("***", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text("Card Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 20),
            _buildField("Card Number", _cardNumberController, "5248 1234 5678 9012", maxLength: 16),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildField("Expiry date", _expiryController, "MM/YY")),
                const SizedBox(width: 20),
                Expanded(child: _buildField("CVV", _cvvController, "123", maxLength: 3, obscureText: true)),
              ],
            ),
            const SizedBox(height: 40),
            _isProcessing 
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text("PAY ₹${widget.amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int? maxLength, bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          maxLength: maxLength,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            counterText: "",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        )
      ],
    );
  }
}
