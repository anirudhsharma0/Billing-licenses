import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/license_config.dart';

class LicenseCheckResult {
  final bool isLicensed;
  final bool isOffline;
  final String clientId;
  final String? clientName;
  final String? customMessage;
  final DateTime checkTime;

  const LicenseCheckResult({
    required this.isLicensed,
    required this.isOffline,
    required this.clientId,
    this.clientName,
    this.customMessage,
    required this.checkTime,
  });
}

class LicenseService {
  static const String _keyClientId = 'kb_permanent_client_id';
  static const String _keyLastStatus = 'kb_last_known_license_status';
  static const String _keyLastClientName = 'kb_last_client_name';
  static const String _keyLastMessage = 'kb_last_license_message';
  static const String _keyLastCheckTime = 'kb_last_license_check_time';

  /// Get or generate a permanent, immutable Client ID for this device
  static Future<String> getOrCreateClientId() async {
    // 1. Check SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_keyClientId)?.trim();
    if (savedId != null && savedId.isNotEmpty) {
      // Backup to filesystem if on Windows
      _persistToFileOnWindows(savedId);
      return savedId;
    }

    // 2. On Windows, check persistent filesystem storage as fallback (survives cache clear / reinstall)
    if (!kIsWeb && Platform.isWindows) {
      try {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData\\KishanBhartiBilling');
          final file = File('${dir.path}\\.device_license.id');
          if (file.existsSync()) {
            final existing = file.readAsStringSync().trim();
            if (existing.startsWith('KB-') && existing.length >= 12) {
              await prefs.setString(_keyClientId, existing);
              return existing;
            }
          }
        }
      } catch (_) {}
    }

    // 3. Generate a brand new, clean, immutable ID
    // Format: KB-XXXX-XXXX-XXXX (e.g. KB-8A2F-9C1D-4E3B)
    final rawUuid = const Uuid().v4().replaceAll('-', '').toUpperCase();
    final newId = 'KB-${rawUuid.substring(0, 4)}-${rawUuid.substring(4, 8)}-${rawUuid.substring(8, 12)}';

    await prefs.setString(_keyClientId, newId);
    _persistToFileOnWindows(newId);

    return newId;
  }

  /// Backup ID to Windows filesystem
  static void _persistToFileOnWindows(String id) {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData\\KishanBhartiBilling');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final file = File('${dir.path}\\.device_license.id');
          file.writeAsStringSync(id);
        }
      } catch (_) {}
    }
  }

  /// Check license status against Google Sheet with offline cached fallback
  static Future<LicenseCheckResult> checkLicense({String? overrideSheetUrl}) async {
    final clientId = await getOrCreateClientId();
    final prefs = await SharedPreferences.getInstance();
    final sheetUrl = overrideSheetUrl ?? await LicenseConfig.loadSheetUrl();

    try {
      final uri = Uri.parse(LicenseConfig.formatToCsvUrl(sheetUrl));
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final lines = response.body.split(RegExp(r'\r?\n'));
        bool found = false;
        bool isAllowed = false;
        String? clientName;
        String? message;

        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty) continue;

          final fields = _parseCsvLine(line);
          if (fields.isEmpty) continue;

          // Col 0: Client ID
          final rowId = fields[0].replaceAll('"', '').trim().toUpperCase();
          if (rowId == clientId.toUpperCase()) {
            found = true;

            // Col 1: Status (TRUE / FALSE)
            final statusStr = fields.length > 1 ? fields[1].replaceAll('"', '').trim().toUpperCase() : 'FALSE';
            isAllowed = (statusStr == 'TRUE' ||
                statusStr == '1' ||
                statusStr == 'YES' ||
                statusStr == 'ACTIVE' ||
                statusStr == 'OK' ||
                statusStr == 'PASS');

            // Col 2: Client Name (Optional)
            if (fields.length > 2) {
              clientName = fields[2].replaceAll('"', '').trim();
            }

            // Col 3: Custom message / Remarks / Expiry (Optional)
            if (fields.length > 3) {
              message = fields[3].replaceAll('"', '').trim();
            }

            break;
          }
        }

        if (found) {
          // Update cached offline state
          await prefs.setBool(_keyLastStatus, isAllowed);
          await prefs.setString(_keyLastCheckTime, DateTime.now().toIso8601String());
          if (clientName != null) await prefs.setString(_keyLastClientName, clientName);
          if (message != null) await prefs.setString(_keyLastMessage, message);

          return LicenseCheckResult(
            isLicensed: isAllowed,
            isOffline: false,
            clientId: clientId,
            clientName: clientName,
            customMessage: isAllowed
                ? 'लाइसेंस सक्रिय है।'
                : (message?.isNotEmpty == true ? message : 'भुगतान लंबित है अथवा लाइसेंस अमान्य है।'),
            checkTime: DateTime.now(),
          );
        } else {
          // ID not found in Google Sheet
          await prefs.setBool(_keyLastStatus, false);
          await prefs.setString(_keyLastCheckTime, DateTime.now().toIso8601String());

          return LicenseCheckResult(
            isLicensed: false,
            isOffline: false,
            clientId: clientId,
            customMessage: 'यह डिवाइस आईडी Google Sheet में नहीं मिली। कृपया एडमिन को यह आईडी भेजें।',
            checkTime: DateTime.now(),
          );
        }
      } else {
        // HTTP response error - fallback to offline status
        return _fallbackToOffline(prefs, clientId, 'सर्वर रिस्पॉन्स त्रुटि (${response.statusCode})');
      }
    } catch (_) {
      // Network error / offline / timeout - fallback to last known status
      return _fallbackToOffline(prefs, clientId, 'नेटवर्क अनुपलब्ध (ऑफ़लाइन)');
    }
  }

  /// Offline fallback: Return last known status as requested by user
  static LicenseCheckResult _fallbackToOffline(
    SharedPreferences prefs,
    String clientId,
    String reason,
  ) {
    final lastStatus = prefs.getBool(_keyLastStatus);
    final lastClientName = prefs.getString(_keyLastClientName);
    final lastMessage = prefs.getString(_keyLastMessage);

    if (lastStatus == true) {
      // Offline mode & last status was valid -> ALLOW app to open!
      return LicenseCheckResult(
        isLicensed: true,
        isOffline: true,
        clientId: clientId,
        clientName: lastClientName,
        customMessage: 'ऑफलाइन मोड: पिछला लाइसेंस एक्टिव था।',
        checkTime: DateTime.now(),
      );
    } else if (lastStatus == false) {
      // Offline mode & last status was false -> KEEP LOCKED!
      return LicenseCheckResult(
        isLicensed: false,
        isOffline: true,
        clientId: clientId,
        clientName: lastClientName,
        customMessage: lastMessage ?? 'ऑफलाइन मोड: पिछला लाइसेंस निष्क्रिय अथवा भुगतान लंबित था।',
        checkTime: DateTime.now(),
      );
    } else {
      // Brand new install, never connected once -> Lock until verified once
      return LicenseCheckResult(
        isLicensed: false,
        isOffline: true,
        clientId: clientId,
        customMessage: 'सत्यापन के लिए पहली बार इंटरनेट से कनेक्ट करें।',
        checkTime: DateTime.now(),
      );
    }
  }

  /// Quick CSV Line Parser handling quotes
  static List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    final StringBuffer buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString().trim());
    return fields;
  }
}
