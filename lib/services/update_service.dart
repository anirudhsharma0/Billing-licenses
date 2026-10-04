import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/update_config.dart';

class UpdateInfo {
  final bool hasUpdate;
  final bool isOffline;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool mandatory;
  final String message;

  const UpdateInfo({
    required this.hasUpdate,
    this.isOffline = false,
    required this.currentVersion,
    required this.latestVersion,
    this.downloadUrl = '',
    this.releaseNotes = '',
    this.mandatory = false,
    this.message = '',
  });
}

class UpdateService {
  /// Compare semantic versions (e.g. 1.0.1 > 1.0.0)
  static bool isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '').split('.');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '').split('.');

      final int maxLen = cleanLatest.length > cleanCurrent.length ? cleanLatest.length : cleanCurrent.length;

      for (int i = 0; i < maxLen; i++) {
        final int l = i < cleanLatest.length ? int.tryParse(cleanLatest[i]) ?? 0 : 0;
        final int c = i < cleanCurrent.length ? int.tryParse(cleanCurrent[i]) ?? 0 : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  /// Check for latest update from GitHub repository
  static Future<UpdateInfo> checkForUpdate() async {
    const current = UpdateConfig.currentVersion;

    try {
      // 1. Try checking version.json from GitHub
      final versionUri = Uri.parse(UpdateConfig.versionJsonUrl);
      final response = await http.get(versionUri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latest = (data['version'] ?? current).toString();
        final notes = (data['release_notes'] ?? 'नए फीचर्स और बग फिक्स').toString();
        final mandatory = data['mandatory'] == true;

        String downloadUrl = '';
        if (!kIsWeb && Platform.isWindows) {
          downloadUrl = (data['windows_download_url'] ?? '').toString();
        } else if (!kIsWeb && Platform.isAndroid) {
          downloadUrl = (data['android_download_url'] ?? '').toString();
        } else {
          downloadUrl = (data['windows_download_url'] ?? data['android_download_url'] ?? '').toString();
        }

        final bool hasUpdate = isNewerVersion(latest, current);
        return UpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: current,
          latestVersion: latest,
          downloadUrl: downloadUrl,
          releaseNotes: notes,
          mandatory: mandatory,
          message: hasUpdate ? 'नया अपडेट उपलब्ध है!' : 'आप नवीनतम वर्जन पर हैं।',
        );
      }

      // 2. Fallback: Check GitHub Releases API
      final releasesUri = Uri.parse(UpdateConfig.githubReleasesApiUrl);
      final apiResponse = await http.get(
        releasesUri,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 6));

      if (apiResponse.statusCode == 200) {
        final data = json.decode(apiResponse.body);
        final tagName = (data['tag_name'] ?? current).toString().replaceAll('v', '');
        final body = (data['body'] ?? 'नए फीचर्स और सुधार').toString();
        final List assets = (data['assets'] as List?) ?? [];

        String downloadUrl = '';
        for (final asset in assets) {
          final name = (asset['name'] ?? '').toString().toLowerCase();
          final url = (asset['browser_download_url'] ?? '').toString();
          if (!kIsWeb && Platform.isWindows && (name.endsWith('.zip') || name.endsWith('.exe'))) {
            downloadUrl = url;
            break;
          } else if (!kIsWeb && Platform.isAndroid && name.endsWith('.apk')) {
            downloadUrl = url;
            break;
          }
        }

        final bool hasUpdate = isNewerVersion(tagName, current);
        return UpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: current,
          latestVersion: tagName,
          downloadUrl: downloadUrl,
          releaseNotes: body,
          message: hasUpdate ? 'नया अपडेट उपलब्ध है!' : 'आप नवीनतम वर्जन पर हैं।',
        );
      }

      return const UpdateInfo(
        hasUpdate: false,
        currentVersion: current,
        latestVersion: current,
        message: 'आप नवीनतम वर्जन पर हैं।',
      );
    } catch (_) {
      return const UpdateInfo(
        hasUpdate: false,
        isOffline: true,
        currentVersion: current,
        latestVersion: current,
        message: 'अपडेट चेक करने के लिए इंटरनेट से कनेक्ट करें।',
      );
    }
  }

  /// Download the update package with live progress reporting
  static Future<File?> downloadUpdateFile(
    String url, {
    required Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    final client = http.Client();
    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        return null;
      }

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      // Determine local save path in temp directory
      final tempDir = Directory.systemTemp;
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'billing_update_package.zip';
      final saveFile = File('${tempDir.path}\\$fileName');
      if (saveFile.existsSync()) {
        saveFile.deleteSync();
      }

      final sink = saveFile.openWrite();

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final double progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
        onProgress(progress, receivedBytes, totalBytes);
      }

      await sink.flush();
      await sink.close();

      return saveFile;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Apply update and restart the application
  static Future<bool> applyUpdate(File updateFile) async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        final filePath = updateFile.path;
        final appDir = File(Platform.resolvedExecutable).parent.path;

        if (filePath.endsWith('.exe')) {
          // Installer executable
          await Process.start(filePath, [], runInShell: true);
          exit(0);
        } else if (filePath.endsWith('.zip')) {
          // Zip package: Create and run helper batch script
          final scriptFile = File('${Directory.systemTemp.path}\\apply_billing_update.bat');
          await scriptFile.writeAsString('''
@echo off
echo Updating Billing App to latest version...
timeout /t 2 /nobreak >nul
tar -xf "$filePath" -C "$appDir"
start "" "$appDir\\billing_app.exe"
del "$filePath"
exit
''');
          await Process.start(scriptFile.path, [], runInShell: true);
          exit(0);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
