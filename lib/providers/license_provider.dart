import 'package:flutter/foundation.dart';
import '../config/license_config.dart';
import '../services/license_service.dart';

class LicenseProvider with ChangeNotifier {
  String _clientId = '';
  bool _isLoading = true;
  bool _isLicensed = true;
  bool _isOffline = false;
  String? _customMessage;
  String? _clientName;
  DateTime? _lastChecked;
  final bool autoCheck;

  LicenseProvider({this.autoCheck = true}) {
    if (autoCheck) {
      initLicense();
    } else {
      _isLoading = false;
      _isLicensed = true;
    }
  }

  // Getters
  String get clientId => _clientId;
  bool get isLoading => _isLoading;
  bool get isLicensed => _isLicensed;
  bool get isOffline => _isOffline;
  String? get customMessage => _customMessage;
  String? get clientName => _clientName;
  DateTime? get lastChecked => _lastChecked;

  /// Initialize and verify license on app startup
  Future<void> initLicense() async {
    _isLoading = true;
    notifyListeners();

    _clientId = await LicenseService.getOrCreateClientId();
    final result = await LicenseService.checkLicense();

    _isLicensed = result.isLicensed;
    _isOffline = result.isOffline;
    _customMessage = result.customMessage;
    _clientName = result.clientName;
    _lastChecked = result.checkTime;
    _isLoading = false;
    notifyListeners();
  }

  /// Re-check license (e.g. after client paid or admin updated Google Sheet)
  Future<LicenseCheckResult> checkLicense() async {
    _isLoading = true;
    notifyListeners();

    final result = await LicenseService.checkLicense();
    _isLicensed = result.isLicensed;
    _isOffline = result.isOffline;
    _customMessage = result.customMessage;
    _clientName = result.clientName;
    _lastChecked = result.checkTime;
    _isLoading = false;
    notifyListeners();

    return result;
  }

  /// Update Google Sheet URL (Admin/Developer configuration)
  Future<void> updateSheetUrl(String url) async {
    await LicenseConfig.saveSheetUrl(url);
    await checkLicense();
  }

  /// Testing helper to set mock state
  @visibleForTesting
  void setMockState({
    required bool isLicensed,
    required String clientId,
    bool isOffline = false,
    String? message,
  }) {
    _isLicensed = isLicensed;
    _clientId = clientId;
    _isOffline = isOffline;
    _customMessage = message;
    _isLoading = false;
    notifyListeners();
  }
}
