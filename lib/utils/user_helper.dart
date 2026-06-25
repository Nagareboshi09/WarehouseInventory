import 'package:shared_preferences/shared_preferences.dart';

class UserHelper {
  static const String _usernameKey = 'username';
  static const String _roleKey = 'role';
  static const String _isLoggedInKey = 'isLoggedIn';

  /// Get the currently logged-in user information
  static Future<Map<String, String>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!isLoggedIn) {
        return null;
      }

      final username = prefs.getString(_usernameKey);
      final role = prefs.getString(_roleKey);

      if (username == null || username.isEmpty) {
        return null;
      }

      return {
        'username': username,
        'role': role ?? 'user',
      };
    } catch (e) {
      // Log error but don't throw - return null for safety
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Get just the current username
  static Future<String?> getCurrentUsername() async {
    final user = await getCurrentUser();
    return user?['username'];
  }

  /// Get just the current user role
  static Future<String?> getCurrentUserRole() async {
    final user = await getCurrentUser();
    return user?['role'];
  }

  /// Check if user is currently logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Format user display name
  static Future<String> getFormattedUserDisplay() async {
    final user = await getCurrentUser();
    if (user == null) {
      return 'Unknown User';
    }

    final username = user['username'] ?? 'Unknown';
    final role = user['role'] ?? 'user';
    
    // Capitalize first letter of role
    final formattedRole = role.isNotEmpty 
        ? role[0].toUpperCase() + role.substring(1).toLowerCase()
        : 'User';

    return '$username ($formattedRole)';
  }
}