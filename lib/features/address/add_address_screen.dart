import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/token_manager.dart';
import 'provider/address_provider.dart';

class AddAddressScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialPincode;
  final String? initialCity;
  final String? initialArea;
  final String? initialStreet;

  const AddAddressScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialPincode,
    this.initialCity,
    this.initialArea,
    this.initialStreet,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  String _label = 'Home';
  final _houseCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Surat');
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pincodeCtrl.text = widget.initialPincode ?? '';
    _cityCtrl.text = widget.initialCity ?? 'Surat';
    _areaCtrl.text = widget.initialArea ?? '';
    _streetCtrl.text = widget.initialStreet ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = await TokenManager.getUserId();
      if (userId == null) throw Exception("User not logged in");    setState(() => _isLoading = true);


      final result = await ApiService.addAddress(
        userId: userId,
        label: _label,
        houseNo: _houseCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        landmark: _landmarkCtrl.text.isNotEmpty ? _landmarkCtrl.text.trim() : null,
        latitude: widget.initialLat,
        longitude: widget.initialLng,
        isDefault: _isDefault,
      );

      if (result['success'] == true) {
        if (mounted) {
          await context.read<AddressProvider>().fetchAddresses();
          Navigator.pop(context);
        }
      } else {
        _showError(result['message'] ?? "Save failed");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add New Address", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Save address as", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _labelChip('Home', Icons.home_rounded),
                  const SizedBox(width: 12),
                  _labelChip('Work', Icons.work_rounded),
                  const SizedBox(width: 12),
                  _labelChip('Other', Icons.location_on_rounded),
                ],
              ),
              const SizedBox(height: 30),
              _field(_houseCtrl, "House/Flat Number", Icons.door_front_door_rounded, required: true),
              const SizedBox(height: 16),
              _field(_streetCtrl, "Street/Building Name", Icons.apartment_rounded, required: true),
              const SizedBox(height: 16),
              _field(_areaCtrl, "Area/Sector/Locality", Icons.map_rounded, required: true),
              const SizedBox(height: 16),
              _field(_landmarkCtrl, "Landmark (Optional)", Icons.flag_rounded),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field(_pincodeCtrl, "Pincode", Icons.pin_drop_rounded, required: true, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _field(_cityCtrl, "City", Icons.location_city_rounded, required: true)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    activeColor: const Color(0xFFFF6A00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _isDefault = val ?? false),
                  ),
                  Text("Set as default address", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Save Address", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelChip(String label, IconData icon) {
    final isSelected = _label == label;
    return GestureDetector(
      onTap: () => setState(() => _label = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6A00) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFFF6A00) : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.3), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool required = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: required ? (v) => v!.isEmpty ? "Required" : null : null,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6A00), size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1)),
      ),
    );
  }
}
