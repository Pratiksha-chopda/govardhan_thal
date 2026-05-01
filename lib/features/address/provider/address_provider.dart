import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/token_manager.dart';
import '../models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Returns the default address, or the very first one if no default is explicitly set
  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.first;
    }
  }

  Future<void> fetchAddresses() async {
    final userId = await TokenManager.getUserId();
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final rawData = await ApiService.getAddresses(userId);
      _addresses = rawData.map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e))).toList();
      
      // If no address selected yet, pick the default one
      if (_selectedAddress == null) {
        _selectedAddress = defaultAddress;
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      _addresses = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setDefault(String addressId) async {
    // Optimistically update the UI
    _addresses = _addresses.map((a) {
      return AddressModel(
        id: a.id,
        userId: a.userId,
        label: a.label,
        houseNo: a.houseNo,
        street: a.street,
        area: a.area,
        city: a.city,
        pincode: a.pincode,
        landmark: a.landmark,
        latitude: a.latitude,
        longitude: a.longitude,
        isDefault: a.id == addressId,
      );
    }).toList();
    
    // Sort to keep default at top
    _addresses.sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
    notifyListeners();

    try {
      final result = await ApiService.setDefaultAddress(addressId);
      return result['success'] == true;
    } catch (e) {
      await fetchAddresses();
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    // Optimistic delete
    final backup = List<AddressModel>.from(_addresses);
    _addresses.removeWhere((a) => a.id == addressId);
    notifyListeners();

    try {
      final result = await ApiService.deleteAddress(addressId);
      if ((result['status'] == 'success' || result['success'] == true)) return true;
      _addresses = backup;
      notifyListeners();
    } catch (e) {
      _addresses = backup;
      notifyListeners();
    }
    return false;
  }
}
