import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────
/// TokenManager — Manages JWT access & refresh tokens locally.
/// Stores tokens and user info in SharedPreferences.
/// ─────────────────────────────────────────────────────────────
class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userProfileKey = 'user_profile_image';
  static const String _userRoleKey = 'user_role';
  static const String _loginTypeKey = 'login_type';

  // ── Token Operations ──

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // ── User Info Operations ──

  static Future<void> saveUserInfo({
    required String userId,
    required String name,
    String email = '',
    String profileImage = '',
    String role = 'user',
    String loginType = 'mobile',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userProfileKey, profileImage);
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_loginTypeKey, loginType);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'Guest';
  }

  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? '';
  }

  static Future<String> getUserProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userProfileKey) ?? '';
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey) ?? 'user';
  }

  // ── Session Management ──

  /// Check if user is currently logged in (has a valid access token)
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_loginTypeKey);
  }

  /// Full save: tokens + user info in one call
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
    String? loginType,
  }) async {
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await saveUserInfo(
      userId: (user['user_id'] ?? user['id'] ?? '').toString(),
      name: user['name'] ?? '',
      email: user['email'] ?? '',
      profileImage: user['profileImage'] ?? '',
      role: user['role'] ?? 'user',
      loginType: loginType ?? 'mobile',
    );
  }
}
