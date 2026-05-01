import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cart/models/cart_item.dart';
import '../../../services/api_service.dart';


class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  // Debounce map: menuId -> Timer
  final Map<String, Timer> _debouncers = {};

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _activeSession;
  Map<String, dynamic>? get activeSession => _activeSession;

  double _dynamicDeliveryFee = 0.0;
  String _currentAddressId = '';
  double get currentDeliveryFee => _dynamicDeliveryFee;

  // ---------------- PRICE BREAKDOWN ----------------
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get deliveryFee => _currentAddressId.isEmpty 
      ? (subtotal >= 500 || subtotal == 0 ? 0.0 : 40.0) 
      : _dynamicDeliveryFee; 

  double get gstAmount => _items.fold(0.0, (sum, item) => sum + (item.subtotal * (item.gstRate / 100)));
  
  String get gstSummaryLabel {
    if (_items.isEmpty) return "Taxes & Charges (GST)";
    final uniqueRates = _items.map((e) => e.gstRate).toSet();
    if (uniqueRates.length == 1 && uniqueRates.first > 0) {
      return "Taxes (${uniqueRates.first.toStringAsFixed(0)}% GST)";
    }
    return "Taxes & Charges (GST)";
  }

  double get total => subtotal + deliveryFee + gstAmount;

  Future<void> updateDeliveryAddress(String addressId) async {
    _currentAddressId = addressId;
    try {
      final res = await ApiService.getDeliveryFee(addressId, subtotal);
      if (res['success'] == true) {
        _dynamicDeliveryFee = (res['data']?['deliveryFee'] ?? 40.0).toDouble();
      }
    } catch (_) {
      _dynamicDeliveryFee = 40.0;
    }
    notifyListeners();
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getCart();
      final itemsList = data['items'] as List? ?? [];
      _items = itemsList.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('Cart fetch error: $e');
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add item to cart — with optimistic UI
  Future<bool> addItem(String menuId, int quantity, double price) async {
    // Optimistic insert
    final existingIndex = _items.indexWhere((i) => i.menuId == menuId);
    if (existingIndex >= 0) {
      final currentQty = _items[existingIndex].quantity;
      _optimisticUpdate(menuId, currentQty + quantity);
    }

    try {
      final success = await ApiService.addToCart(menuId, quantity);
      if (success) {
        await fetchCart(); // Get full item details (image/name)
        return true;
      } else {
        await fetchCart(); // Revert/Sync on fail
        return false;
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
      await fetchCart(); // Revert/Sync on fail
      return false;
    }
  }

  /// Remove item completely
  Future<bool> removeItem(String menuId) async {
    // Optimistic remove
    final backup = List<CartItem>.from(_items);
    _items.removeWhere((i) => i.menuId == menuId);
    notifyListeners();

    try {
      final success = await ApiService.removeFromCart(menuId);
      if (success) return true;
      // Revert if API failed
      _items = backup;
      notifyListeners();
    } catch (e) {
      _items = backup;
      notifyListeners();
    }
    return false;
  }

  /// Update item quantity — Optimistic with Debounce
  void updateQuantity(String menuId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuId);
      return;
    }

    // 1. Optimistic UI update instantly!
    _optimisticUpdate(menuId, quantity);

    // 2. Cancel running timer for this item if tapped again quickly
    if (_debouncers.containsKey(menuId)) {
      _debouncers[menuId]!.cancel();
    }

    // 3. Start 500ms countdown before hitting API
    _debouncers[menuId] = Timer(const Duration(milliseconds: 500), () async {
      try {
        final success = await ApiService.updateCartQuantity(menuId, quantity);
        if (!success) await fetchCart(); // Sync if failed
      } catch (e) {
        await fetchCart(); // Sync if failed
      }
      _debouncers.remove(menuId);
    });
  }

  void _optimisticUpdate(String menuId, int newQuantity) {
    final index = _items.indexWhere((i) => i.menuId == menuId);
    if (index >= 0) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  void clearLocalCart() {
    _items.clear();
    notifyListeners();
  }

  /// Clears the backend cart
  Future<bool> clearCart() async {
    try {
      final ok = await ApiService.clearCart();
      if (ok) clearLocalCart();
      return ok;
    } catch (e) {
      return false;
    }
  }

  /// Place all current cart items as a DINING order attached to the session.
  /// On success, clears the local cart.
  Future<bool> placeAsDiningOrder({
    required String sessionId,
    required String tableId,
    String? couponCode,
    double? discountAmount,
  }) async {
    if (_items.isEmpty) return false;

    final orderItems = _items.map((i) => {
      'menuId':   i.menuId,
      'menu_id':  i.menuId, // Support both formats for safety
      'quantity': i.quantity,
    }).toList();

    try {
      final res = await ApiService.placeDiningOrder(
        sessionId: sessionId,
        tableId:   tableId,
        items:     orderItems,
        couponCode: couponCode,
        discountAmount: discountAmount,
      );

      if (res['status'] == 'success' || res['success'] == true) {
        // Clear cart locally and on server
        await ApiService.clearCart();
        clearLocalCart();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Dining order error: $e');
      return false;
    }
  }

  /// Check if the user has an active dining session
  Future<void> checkActiveSession() async {
    try {
      final res = await ApiService.getActiveDiningSession();
      if (res['status'] != 'error' && res['data'] != null) {
        _activeSession = Map<String, dynamic>.from(res['data']?['activeSession'] ?? res['data']);
        
        // Save to Local for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_session_id', _activeSession?['_id'] ?? '');
        await prefs.setString('table_id', _activeSession?['tableId']?['tableNumber']?.toString() ?? '');
      } else {
        // API says no session, but let's check if we have a local one to verify? 
        // Actually, API is the source of truth. If API says no session, we clear local.
        _activeSession = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_session_id');
        await prefs.remove('table_id');
      }
      notifyListeners();
    } catch (e) {
      // Network error? Try to use local if exists (offline support or startup)
      final prefs = await SharedPreferences.getInstance();
      final localSessionId = prefs.getString('active_session_id');
      final localTableNum = prefs.getString('table_id');
      
      if (localSessionId != null && localSessionId.isNotEmpty) {
        _activeSession = {
          '_id': localSessionId,
          'tableId': {'tableNumber': localTableNum}
        };
      } else {
        _activeSession = null;
      }
      notifyListeners();
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    for (final timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> clearActiveSession() async {
    _activeSession = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_session_id');
    await prefs.remove('table_id');
    notifyListeners();
  }
}
