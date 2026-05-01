import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'provider/address_provider.dart';
import 'models/address_model.dart';
import 'add_address_screen.dart';
import '../menu/menu_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AddressProvider>().fetchAddresses());
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError("Location services are disabled on your device.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError("Location permissions were denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError("Location permissions are permanently denied, please enable them in settings.");
        return;
      }

      // Try to get position with a 10-second timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Fallback to last known position if current is too slow
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          rethrow;
        }
      }
      
      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      } catch (e) {
        debugPrint("Geocoding Error: $e");
        // If geocoding fails but we have position, still allow adding address manually with coords
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddAddressScreen(
              initialLat: position.latitude,
              initialLng: position.longitude,
            ),
          ),
        );
        return;
      }
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddAddressScreen(
              initialLat: position.latitude,
              initialLng: position.longitude,
              initialPincode: place.postalCode,
              initialCity: place.locality,
              initialArea: place.subLocality,
              initialStreet: place.street,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      _showError("Unable to fetch location. Please check GPS reception or add manually.");
    } finally {
      if (mounted) setState(() => _isLocating = false);
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
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text("Select Delivery Address", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addrProv, _) {
          if (addrProv.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)));
          }

          return Column(
            children: [
              // Location Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: _locationActionCard(),
              ),

              Expanded(
                child: addrProv.addresses.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: addrProv.addresses.length,
                        itemBuilder: (context, index) {
                          final address = addrProv.addresses[index];
                          return _addressCard(address, addrProv);
                        },
                      ),
              ),

              // Bottom Button
              _bottomAction(addrProv),
            ],
          );
        },
      ),
    );
  }

  Widget _locationActionCard() {
    return InkWell(
      onTap: _isLocating ? null : _useCurrentLocation,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF6A00).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            _isLocating 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFF6A00)))
              : const Icon(Icons.my_location_rounded, color: Color(0xFFFF6A00), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Use Current Location", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFFFF6A00))),
                  Text("Using GPS for faster checkout", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(AddressModel address, AddressProvider provider) {
    final isSelected = provider.selectedAddress?.id == address.id;
    return GestureDetector(
      onTap: () => provider.selectAddress(address),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFFFF6A00) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(
              address.label == 'Home' ? Icons.home_rounded : (address.label == 'Work' ? Icons.work_rounded : Icons.location_on_rounded),
              color: isSelected ? const Color(0xFFFF6A00) : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                          child: Text("DEFAULT", style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("${address.houseNo}, ${address.street}", style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                  Text(address.area, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                  Text("${address.city} - ${address.pincode}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFFF6A00), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No saved addresses", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Add delivery address to continue", style: GoogleFonts.poppins(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6A00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text("Add New Address", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction(AddressProvider provider) {
    final showConfirm = provider.selectedAddress != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen())),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFFFF6A00)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text("Add New", style: GoogleFonts.poppins(color: const Color(0xFFFF6A00), fontWeight: FontWeight.bold)),
                ),
              ),
              if (showConfirm) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MenuScreen(orderType: 'ONLINE')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6A00), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text("Confirm & Order", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
