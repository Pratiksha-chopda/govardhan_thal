import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/menu_item.dart';
import '../../../../services/menu_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/socket_service.dart';

class MenuProvider extends ChangeNotifier {
  List<String> wishlistIds = [];
  /// ---------------- ALL MENU ITEMS ----------------
  List<MenuItem> allItems = [];

  /// ---------------- FILTERED ITEMS (BY CATEGORY) ----------------
  List<MenuItem> items = [];

  /// ---------------- CATEGORIES ----------------
  List<String> categories = [];

  /// ---------------- SELECTED CATEGORY ----------------
  String selectedCategory = "";

  /// ---------------- LOADER ----------------
  bool isLoading = false;
  bool serverError = false;

  MenuProvider() {
    // Listen for real-time menu updates from admin
    SocketService().onMenuCreated = (_) => loadMenuData();
    SocketService().onMenuUpdated = (_) => loadMenuData();
    SocketService().onMenuDeleted = (_) => loadMenuData();
  }

  /// Isolate-safe: parses raw JSON list into MenuItem list on background thread
  static List<MenuItem> _parseMenuItems(List<dynamic> rawData) {
    return rawData
        .map((d) => MenuItem.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  static List<String> _buildCategories(List<MenuItem> items) {
    final cats = items.map((e) => e.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  /// =================================================
  /// ASYNC CACHING LOGIC — minimal notifyListeners calls
  /// =================================================
  Future<void> loadMenuData() async {
    final prefs = await SharedPreferences.getInstance();

    // Phase 1: Boot from cache (0 latency)
    final cachedData = prefs.getString('cached_menu');
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final rawList = await compute<String, List<dynamic>>(
          (s) => jsonDecode(s) as List<dynamic>,
          cachedData,
        );
        // Heavy mapping on background isolate
        final parsed = await compute(_parseMenuItems, rawList);
        _applyParsedItems(parsed);
        notifyListeners(); // notify ONCE after cache
      } catch (_) {
        await prefs.remove('cached_menu');
        isLoading = true;
        notifyListeners();
      }
    } else {
      // First install — show spinner
      isLoading = true;
      notifyListeners();
    }

    // Phase 2: Fetch fresh from network
    try {
      final apiData = await MenuService.getMenu();
      serverError = false;

      // Cache write on background isolate
      final encoded = await compute<List<dynamic>, String>(
        (list) => jsonEncode(list),
        apiData,
      );
      await prefs.setString('cached_menu', encoded);

      // Parse on background isolate
      final parsed = await compute(_parseMenuItems, apiData);
      _applyParsedItems(parsed);

      // Fetch wishlist silently (no separate notify)
      try {
        final list = await ApiService.getWishlist();
        wishlistIds = list.map((e) => e['_id'].toString()).toList();
      } catch (_) {}
    } catch (e) {
      debugPrint('Menu load error: $e');
      serverError = allItems.isEmpty;
    }

    isLoading = false;
    notifyListeners(); // notify ONCE after full API load
  }

  void _applyParsedItems(List<MenuItem> parsed) {
    allItems = parsed;
    categories = _buildCategories(parsed);

    if (selectedCategory.isEmpty) {
      selectedCategory = 'All';
    }

    // Re-apply current filter
    if (selectedCategory == 'All') {
      items = List.from(allItems);
    } else {
      items = allItems.where((i) => i.category == selectedCategory).toList();
    }
    // Caller notifies — no notifyListeners() here
  }

  Future<void> fetchWishlist() async {
    try {
      final list = await ApiService.getWishlist();
      wishlistIds = list.map((e) => e['_id'].toString()).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    }
  }

  Future<void> toggleWishlist(String menuId) async {
    try {
      final res = await ApiService.toggleWishlist(menuId);
      final isFav = res['isFavorite'] ?? false;
      if (isFav) {
        if (!wishlistIds.contains(menuId)) wishlistIds.add(menuId);
      } else {
        wishlistIds.remove(menuId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error toggling wishlist: $e");
    }
  }

  /// =================================================
  /// LOAD ITEMS BY CATEGORY
  /// =================================================
  void loadItems(String category) {
    selectedCategory = category;

    if (category == "All") {
      items = List.from(allItems);
    } else {
      items = allItems
          .where((item) => item.category == category)
          .toList();
    }

    notifyListeners();
  }
}
