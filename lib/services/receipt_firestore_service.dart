import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/firebase_config.dart';
import '../models/receipt_model.dart';

class ReceiptSaveResult {
  final ReceiptVoucher receipt;
  final bool isCloudSaved;

  const ReceiptSaveResult({
    required this.receipt,
    required this.isCloudSaved,
  });
}

class ReceiptSyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int pendingCount;
  final String message;

  const ReceiptSyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.pendingCount = 0,
    this.message = '',
  });
}

/// Cloud Firestore REST API CRUD for the `receipts` collection
class ReceiptFirestoreService {
  static String _buildBaseUrl(String projectId) {
    return 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  }

  /// Save or update a receipt in Cloud Firestore collection `receipts`
  static Future<bool> saveReceipt(ReceiptVoucher receipt) async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return false;
    }

    try {
      final docId = receipt.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/receipts/$docId?key=$apiKey'
            : '${_buildBaseUrl(projectId)}/receipts/$docId',
      );

      final syncedReceipt = receipt.copyWith(isSynced: true);
      final payload = {
        'fields': {
          'id': {'stringValue': docId},
          'receiptNo': {'stringValue': syncedReceipt.receiptNo},
          'date': {'stringValue': syncedReceipt.date},
          'customerName': {'stringValue': syncedReceipt.customerName},
          'amount': {'doubleValue': syncedReceipt.amount},
          'paymentMode': {'stringValue': syncedReceipt.paymentMode.value},
          'linkedInvoiceNo': {'stringValue': syncedReceipt.linkedInvoiceNo ?? ''},
          'receiptJson': {'stringValue': syncedReceipt.toJsonString()},
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

  /// Fetch all receipts from Cloud Firestore collection `receipts`
  static Future<List<ReceiptVoucher>> fetchAllReceipts() async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return [];
    }

    try {
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/receipts?key=$apiKey&pageSize=100'
            : '${_buildBaseUrl(projectId)}/receipts?pageSize=100',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final List<dynamic>? docs = data['documents'];
      if (docs == null) return [];

      final List<ReceiptVoucher> receipts = [];
      for (final doc in docs) {
        final fields = doc['fields'];
        if (fields != null && fields['receiptJson'] != null) {
          final jsonString = fields['receiptJson']['stringValue'];
          if (jsonString != null) {
            final receipt = ReceiptVoucher.fromJsonString(jsonString);
            receipts.add(receipt.copyWith(isSynced: true));
          }
        }
      }
      return receipts;
    } catch (_) {
      return [];
    }
  }

  /// Delete a receipt from Cloud Firestore collection `receipts`
  static Future<bool> deleteReceipt(String docId) async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return false;
    }

    try {
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/receipts/$docId?key=$apiKey'
            : '${_buildBaseUrl(projectId)}/receipts/$docId',
      );
      final response = await http.delete(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Offline-first Local Storage + Two-way Firestore Sync for Receipts
class ReceiptStorageService {
  static const String _storageKey = 'receipt_vouchers_local';
  static const String _pendingDeletionsKey = 'pending_deleted_receipt_ids';
  final Uuid _uuid = const Uuid();

  Future<List<ReceiptVoucher>> getLocalReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        final receipts = list
            .map((item) => ReceiptVoucher.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _sortReceipts(receipts);
        return receipts;
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalReceipts(List<ReceiptVoucher> receipts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = json.encode(receipts.map((e) => e.toJson()).toList());
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

  void _sortReceipts(List<ReceiptVoucher> list) {
    list.sort((a, b) {
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  Future<ReceiptSyncResult> syncWithCloud() async {
    int uploaded = 0;
    int downloaded = 0;

    final creds = await FirebaseConfig.loadCredentials();
    if (!FirebaseConfig.isConfigured(creds['projectId'] ?? '', creds['apiKey'] ?? '')) {
      final local = await getLocalReceipts();
      final pending = local.where((e) => !e.isSynced).length;
      return ReceiptSyncResult(
        success: false,
        pendingCount: pending,
        message: 'Firebase not configured',
      );
    }

    try {
      // 1. Process pending deletions
      final pendingDeletes = await _getPendingDeletedIds();
      final List<String> successfullyDeleted = [];
      for (final id in List<String>.from(pendingDeletes)) {
        final ok = await ReceiptFirestoreService.deleteReceipt(id);
        if (ok) successfullyDeleted.add(id);
      }
      if (successfullyDeleted.isNotEmpty) {
        pendingDeletes.removeWhere((id) => successfullyDeleted.contains(id));
        await _savePendingDeletedIds(pendingDeletes);
      }

      // 2. Upload un-synced local receipts
      List<ReceiptVoucher> localReceipts = await getLocalReceipts();
      bool localUpdated = false;
      for (int i = 0; i < localReceipts.length; i++) {
        final r = localReceipts[i];
        if (!r.isSynced) {
          final ok = await ReceiptFirestoreService.saveReceipt(r);
          if (ok) {
            localReceipts[i] = r.copyWith(isSynced: true);
            localUpdated = true;
            uploaded++;
          }
        }
      }
      if (localUpdated) {
        await _saveLocalReceipts(localReceipts);
      }

      // 3. Download & merge from Firestore
      final cloudReceipts = await ReceiptFirestoreService.fetchAllReceipts();
      if (cloudReceipts.isNotEmpty) {
        final Map<String, ReceiptVoucher> map = {};
        for (final r in localReceipts) {
          if (r.id != null) map[r.id!] = r;
        }
        final currentPendingDeletes = await _getPendingDeletedIds();

        for (final cr in cloudReceipts) {
          if (cr.id == null || currentPendingDeletes.contains(cr.id)) continue;
          final existing = map[cr.id!];
          if (existing == null) {
            map[cr.id!] = cr.copyWith(isSynced: true);
            downloaded++;
          } else if (existing.isSynced) {
            if (cr.updatedAt != null &&
                existing.updatedAt != null &&
                cr.updatedAt!.isAfter(existing.updatedAt!)) {
              map[cr.id!] = cr.copyWith(isSynced: true);
            }
          }
        }

        localReceipts = map.values.toList();
        _sortReceipts(localReceipts);
        await _saveLocalReceipts(localReceipts);
      }

      final pendingRemaining = localReceipts.where((e) => !e.isSynced).length;
      return ReceiptSyncResult(
        success: true,
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        pendingCount: pendingRemaining,
        message: 'Receipt sync completed',
      );
    } catch (e) {
      final local = await getLocalReceipts();
      return ReceiptSyncResult(
        success: false,
        pendingCount: local.where((e) => !e.isSynced).length,
        message: 'Sync error: $e',
      );
    }
  }

  Future<ReceiptSaveResult> saveReceipt(ReceiptVoucher receipt, {bool asNew = false}) async {
    final List<ReceiptVoucher> receipts = await getLocalReceipts();
    final bool forceNew = asNew || receipt.id == null || receipt.id!.trim().isEmpty;
    final String docId = forceNew ? _uuid.v4() : receipt.id!;

    ReceiptVoucher toSave = receipt.copyWith(
      id: docId,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    final existingIndex = forceNew ? -1 : receipts.indexWhere((r) => r.id == docId);
    if (existingIndex >= 0) {
      receipts[existingIndex] = toSave;
    } else {
      receipts.insert(0, toSave);
    }

    _sortReceipts(receipts);
    await _saveLocalReceipts(receipts);

    bool cloudSaved = false;
    try {
      cloudSaved = await ReceiptFirestoreService.saveReceipt(toSave);
      if (cloudSaved) {
        toSave = toSave.copyWith(isSynced: true);
        final idx = receipts.indexWhere((r) => r.id == docId);
        if (idx >= 0) {
          receipts[idx] = toSave;
          await _saveLocalReceipts(receipts);
        }
      }
    } catch (_) {
      cloudSaved = false;
    }

    return ReceiptSaveResult(receipt: toSave, isCloudSaved: cloudSaved);
  }

  Future<bool> deleteReceipt(String id) async {
    try {
      final List<ReceiptVoucher> receipts = await getLocalReceipts();
      receipts.removeWhere((r) => r.id == id);
      await _saveLocalReceipts(receipts);

      final pendingDeletes = await _getPendingDeletedIds();
      if (!pendingDeletes.contains(id)) {
        pendingDeletes.add(id);
        await _savePendingDeletedIds(pendingDeletes);
      }

      final ok = await ReceiptFirestoreService.deleteReceipt(id);
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

