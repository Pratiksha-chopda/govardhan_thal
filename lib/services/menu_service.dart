import 'api_service.dart';

/// ─────────────────────────────────────────────────────────────
/// MenuService — Production Service Layer for Menu operations.
/// ─────────────────────────────────────────────────────────────
class MenuService {
  static Future<List<dynamic>> getMenu({String? category, String? search}) async {
    return await ApiService.getMenu(category: category, search: search);
  }

  static Future<List<String>> getCategories() async {
    return await ApiService.getCategories();
  }

  static Future<Map<String, dynamic>> createMenu(Map<String, dynamic> data) async {
    return await ApiService.createMenu(data);
  }

  static Future<Map<String, dynamic>> updateMenu(String id, Map<String, dynamic> data) async {
    return await ApiService.updateMenu(id, data);
  }

  static Future<Map<String, dynamic>> deleteMenu(String id) async {
    return await ApiService.deleteMenu(id);
  }
}
