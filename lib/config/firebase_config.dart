import 'package:shared_preferences/shared_preferences.dart';

class FirebaseConfig {
  static const String _keyProjectId = 'firebase_project_id';
  static const String _keyApiKey = 'firebase_api_key';

  // Default fallback credentials (can be edited here or in-app settings)
  static String defaultProjectId = 'billingapp-47901';
  static String defaultApiKey = 'AIzaSyD1YkH1K63_QjXZnFotdygX3pjj94TbzQo';

  /// Check if Firebase credentials are valid
  static bool isConfigured(String projectId, [String? apiKey]) {
    final p = projectId.trim();
    if (p.isEmpty || p == 'your_project_id') return false;
    return true;
  }

  /// Load currently saved credentials from SharedPreferences
  static Future<Map<String, String>> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPid = prefs.getString(_keyProjectId)?.trim();
    final savedKey = prefs.getString(_keyApiKey)?.trim();
    final projectId = (savedPid != null && savedPid.isNotEmpty) ? savedPid : defaultProjectId;
    final apiKey = (savedKey != null && savedKey.isNotEmpty) ? savedKey : defaultApiKey;
    return {
      'projectId': projectId.trim(),
      'apiKey': apiKey.trim(),
    };
  }

  /// Save new credentials to SharedPreferences
  static Future<void> saveCredentials({
    required String projectId,
    required String apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProjectId, projectId.trim());
    await prefs.setString(_keyApiKey, apiKey.trim());
  }
}
