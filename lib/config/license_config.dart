import 'package:shared_preferences/shared_preferences.dart';

class LicenseConfig {
  static const String _keySheetUrl = 'license_google_sheet_url';
  static const String _keyAdminPhone = 'license_admin_phone';
  static const String _keyAdminUpi = 'license_admin_upi';
  static const String _keyAdminName = 'license_admin_name';

  // Default Google Sheet URL / Sheet ID for license verification
  static String defaultSheetUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vSu7qfOXPX6rPqOTosqxXlb5ebRmfsRGEPZsa5TUUwRMjNwL0aZMbMtaEZ95ZHu_KJ9a10YBKEtPpID/pub?output=csv';

  // Admin contact info for payment and support
  static String defaultAdminPhone = '+91 98123 45678';
  static String defaultAdminName = 'Kishan Bharti Society / Software Admin';
  static String defaultAdminUpi = 'kishanbharti@upi';

  /// Converts any Google Sheet URL or ID into a direct CSV export URL
  static String formatToCsvUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return defaultSheetUrl;

    // If it's already a full CSV URL or Google Apps Script URL
    if (trimmed.contains('format=csv') ||
        trimmed.contains('out:csv') ||
        trimmed.contains('output=csv') ||
        trimmed.contains('script.google.com')) {
      return trimmed;
    }

    // If it's a full Google Sheet URL like https://docs.google.com/spreadsheets/d/SHEET_ID/...
    final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final sheetId = match.group(1);
      return 'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv';
    }

    // If the user just entered the Sheet ID (e.g. 1BxiMVs0XRA5...)
    if (!trimmed.contains('/') && trimmed.length > 15) {
      return 'https://docs.google.com/spreadsheets/d/$trimmed/gviz/tq?tqx=out:csv';
    }

    return trimmed;
  }

  /// Load currently saved Google Sheet URL from SharedPreferences
  static Future<String> loadSheetUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keySheetUrl)?.trim();
    if (saved != null &&
        saved.isNotEmpty &&
        !saved.contains('1gq_SampleBillingLicenseSheetId12345') &&
        !saved.contains('1jUINwkUwYShDU_NFzGqIJjlBNGk7DX9Iv7jPuMa1bPU/gviz')) {
      return formatToCsvUrl(saved);
    }
    return defaultSheetUrl;
  }

  /// Save new Google Sheet URL
  static Future<void> saveSheetUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySheetUrl, url.trim());
  }

  /// Load admin contact details
  static Future<Map<String, String>> loadAdminDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyAdminName)?.trim() ?? defaultAdminName,
      'phone': prefs.getString(_keyAdminPhone)?.trim() ?? defaultAdminPhone,
      'upi': prefs.getString(_keyAdminUpi)?.trim() ?? defaultAdminUpi,
    };
  }

  /// Save admin contact details
  static Future<void> saveAdminDetails({
    required String name,
    required String phone,
    required String upi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdminName, name.trim());
    await prefs.setString(_keyAdminPhone, phone.trim());
    await prefs.setString(_keyAdminUpi, upi.trim());
  }
}
