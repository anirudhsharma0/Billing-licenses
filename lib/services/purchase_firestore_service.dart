import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/firebase_config.dart';
import '../models/purchase_model.dart';

class PurchaseSaveResult {
  final PurchaseBill purchase;
  final bool isCloudSaved;

  const PurchaseSaveResult({
    required this.purchase,
    required this.isCloudSaved,
  });
}

class PurchaseSyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int pendingCount;
  final String message;

  const PurchaseSyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.pendingCount = 0,
    this.message = '',
  });
}

/// Cloud Firestore REST API CRUD for the `purchases` collection
class PurchaseFirestoreService {
  static String _buildBaseUrl(String projectId) {
    return 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  }

  /// Save or update a purchase bill in Cloud Firestore collection `purchases`
  static Future<bool> savePurchase(PurchaseBill purchase) async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return false;
    }

    try {
      final docId =
          purchase.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/purchases/$docId?key=$apiKey'
            : '${_buildBaseUrl(projectId)}/purchases/$docId',
      );

      final synced = purchase.copyWith(isSynced: true);
      final payload = {
        'fields': {
          'id': {'stringValue': docId},
          'supplierName': {'stringValue': synced.supplier.name},
          'invoiceNo': {'stringValue': synced.metadata.invoiceNo},
          'date': {'stringValue': synced.metadata.date},
          'taxableValue': {'doubleValue': synced.totalTaxableValue},
          'totalInputGst': {'doubleValue': synced.totalInputGst},
          'grandTotal': {'doubleValue': synced.grandTotal},
          'purchaseJson': {'stringValue': synced.toJsonString()},
          'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
          'isSynced': {'booleanValue': true},
        }
      };

      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all purchase bills from Cloud Firestore collection `purchases`
  static Future<List<PurchaseBill>> fetchAllPurchases() async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return [];
    }

    try {
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/purchases?key=$apiKey&pageSize=100'
            : '${_buildBaseUrl(projectId)}/purchases?pageSize=100',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final List<dynamic>? docs = data['documents'];
      if (docs == null) return [];

      final List<PurchaseBill> purchases = [];
      for (final doc in docs) {
        final fields = doc['fields'];
        if (fields != null && fields['purchaseJson'] != null) {
          final jsonString = fields['purchaseJson']['stringValue'];
          if (jsonString != null) {
            final p = PurchaseBill.fromJsonString(jsonString);
            purchases.add(p.copyWith(isSynced: true));
          }
        }
      }
      return purchases;
    } catch (_) {
      return [];
    }
  }

  /// Delete a purchase bill from Cloud Firestore collection `purchases`
  static Future<bool> deletePurchase(String docId) async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return false;
    }

    try {
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/purchases/$docId?key=$apiKey'
            : '${_buildBaseUrl(projectId)}/purchases/$docId',
      );
      final response =
          await http.delete(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Offline-first Local Storage + Two-way Firestore Sync for Purchase Bills
class PurchaseStorageService {
  static const String _storageKey = 'purchase_bills_local';
  static const String _pendingDeletionsKey = 'pending_deleted_purchase_ids';
  final Uuid _uuid = const Uuid();

  Future<List<PurchaseBill>> getLocalPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        final purchases = list
            .map((item) =>
                PurchaseBill.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _sortPurchases(purchases);
        return purchases;
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalPurchases(List<PurchaseBill> purchases) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = json.encode(purchases.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, rawJson);
    } catch (_) {}
  }

  Future<List<String>> _getPendingDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_pendingDeletionsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePendingDeletedIds(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_pendingDeletionsKey, ids);
    } catch (_) {}
  }

  void _sortPurchases(List<PurchaseBill> list) {
    list.sort((a, b) {
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  Future<PurchaseSyncResult> syncWithCloud() async {
    int uploaded = 0;
    int downloaded = 0;

    final creds = await FirebaseConfig.loadCredentials();
    if (!FirebaseConfig.isConfigured(
        creds['projectId'] ?? '', creds['apiKey'] ?? '')) {
      final local = await getLocalPurchases();
      return PurchaseSyncResult(
        success: false,
        pendingCount: local.where((e) => !e.isSynced).length,
        message: 'Firebase not configured',
      );
    }

    try {
      // 1. Process pending deletions
      final pendingDeletes = await _getPendingDeletedIds();
      final List<String> deleted = [];
      for (final id in List<String>.from(pendingDeletes)) {
        final ok = await PurchaseFirestoreService.deletePurchase(id);
        if (ok) deleted.add(id);
      }
      if (deleted.isNotEmpty) {
        pendingDeletes.removeWhere((id) => deleted.contains(id));
        await _savePendingDeletedIds(pendingDeletes);
      }

      // 2. Upload un-synced local purchases
      List<PurchaseBill> localPurchases = await getLocalPurchases();
      bool localUpdated = false;
      for (int i = 0; i < localPurchases.length; i++) {
        final p = localPurchases[i];
        if (!p.isSynced) {
          final ok = await PurchaseFirestoreService.savePurchase(p);
          if (ok) {
            localPurchases[i] = p.copyWith(isSynced: true);
            localUpdated = true;
            uploaded++;
          }
        }
      }
      if (localUpdated) {
        await _saveLocalPurchases(localPurchases);
      }

      // 3. Download & merge from Firestore
      final cloudPurchases = await PurchaseFirestoreService.fetchAllPurchases();
      if (cloudPurchases.isNotEmpty) {
        final Map<String, PurchaseBill> map = {};
        for (final p in localPurchases) {
          if (p.id != null) map[p.id!] = p;
        }
        final currentPendingDeletes = await _getPendingDeletedIds();

        for (final cp in cloudPurchases) {
          if (cp.id == null || currentPendingDeletes.contains(cp.id)) continue;
          final existing = map[cp.id!];
          if (existing == null) {
            map[cp.id!] = cp.copyWith(isSynced: true);
            downloaded++;
          } else if (existing.isSynced) {
            if (cp.updatedAt != null &&
                existing.updatedAt != null &&
                cp.updatedAt!.isAfter(existing.updatedAt!)) {
              map[cp.id!] = cp.copyWith(isSynced: true);
            }
          }
        }

        localPurchases = map.values.toList();
        _sortPurchases(localPurchases);
        await _saveLocalPurchases(localPurchases);
      }

      return PurchaseSyncResult(
        success: true,
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        pendingCount: localPurchases.where((e) => !e.isSynced).length,
        message: 'Purchase sync completed',
      );
    } catch (e) {
      final local = await getLocalPurchases();
      return PurchaseSyncResult(
        success: false,
        pendingCount: local.where((e) => !e.isSynced).length,
        message: 'Sync error: $e',
      );
    }
  }

  Future<PurchaseSaveResult> savePurchase(PurchaseBill purchase,
      {bool asNew = false}) async {
    final List<PurchaseBill> purchases = await getLocalPurchases();
    final bool forceNew =
        asNew || purchase.id == null || purchase.id!.trim().isEmpty;
    final String docId = forceNew ? _uuid.v4() : purchase.id!;

    PurchaseBill toSave = purchase.copyWith(
      id: docId,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    final idx = forceNew ? -1 : purchases.indexWhere((p) => p.id == docId);
    if (idx >= 0) {
      purchases[idx] = toSave;
    } else {
      purchases.insert(0, toSave);
    }

    _sortPurchases(purchases);
    await _saveLocalPurchases(purchases);

    bool cloudSaved = false;
    try {
      cloudSaved = await PurchaseFirestoreService.savePurchase(toSave);
      if (cloudSaved) {
        toSave = toSave.copyWith(isSynced: true);
        final savedIdx = purchases.indexWhere((p) => p.id == docId);
        if (savedIdx >= 0) {
          purchases[savedIdx] = toSave;
          await _saveLocalPurchases(purchases);
        }
      }
    } catch (_) {
      cloudSaved = false;
    }

    return PurchaseSaveResult(purchase: toSave, isCloudSaved: cloudSaved);
  }

  Future<bool> deletePurchase(String id) async {
    try {
      final List<PurchaseBill> purchases = await getLocalPurchases();
      purchases.removeWhere((p) => p.id == id);
      await _saveLocalPurchases(purchases);

      final pendingDeletes = await _getPendingDeletedIds();
      if (!pendingDeletes.contains(id)) {
        pendingDeletes.add(id);
        await _savePendingDeletedIds(pendingDeletes);
      }

      final ok = await PurchaseFirestoreService.deletePurchase(id);
      if (ok) {
        pendingDeletes.remove(id);
        await _savePendingDeletedIds(pendingDeletes);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

