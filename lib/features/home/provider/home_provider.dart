import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../menu/model/menu_item.dart';
import '../../../services/menu_service.dart';

class HomeProvider extends ChangeNotifier {
  bool isLoading = true;
  bool isError = false;

  List<String> bannerImages = [
    'assets/images/thali_1.webp', 
    'assets/images/thali_2.webp', 
    'assets/images/thali4.webp', 
  ];

  List<Map<String, String>> categories = [
    {"id": "Thali", "label": "Thali", "emoji": "🍱"},
    {"id": "Sabji", "label": "Sabji", "emoji": "🥦"},
    {"id": "Farsan", "label": "Farsan", "emoji": "🥘"},
    {"id": "Sweets", "label": "Sweets", "emoji": "🍮"},
    {"id": "Roti", "label": "Roti", "emoji": "🫓"},
    {"id": "Beverages", "label": "Beverages", "emoji": "🥛"},
  ];

  List<MenuItem> popularItems = [];
  List<MenuItem> todaySpecials = [];

  Future<void> loadHomeData() async {
    isError = false;
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Fast load from cache
      final cachedMenu = prefs.getString('cached_menu');
      if (cachedMenu != null && cachedMenu.isNotEmpty) {
        try {
          final decoded = await compute<String, List<dynamic>>(
            (raw) => jsonDecode(raw) as List<dynamic>,
            cachedMenu,
          );
          _parseData(decoded);
        } catch (_) {
          await prefs.remove('cached_menu');
        }
      }

      // Fetch fresh from backend
      final rawData = await MenuService.getMenu();
      if (rawData.isNotEmpty) {
        final encoded = await compute<List<dynamic>, String>(
          (list) => jsonEncode(list),
          rawData,
        );
        await prefs.setString('cached_menu', encoded);
        _parseData(rawData);
      }
    } catch (e) {
      isError = true;
      debugPrint("Home load error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _parseData(List<dynamic> rawData) {
    if (rawData.isEmpty) return;

    final all = rawData.map((d) => MenuItem.fromJson(d)).toList();

    // Extract popular & recommended items
    popularItems = all.where((item) => item.isPopular).toList();
    if (popularItems.isEmpty) {
      popularItems = all.take(5).toList();
    }

    todaySpecials = all.where((item) => item.isRecommended).toList();
    if (todaySpecials.isEmpty) {
      todaySpecials = all.skip(5).take(5).toList();
    }

    notifyListeners();
  }
}

