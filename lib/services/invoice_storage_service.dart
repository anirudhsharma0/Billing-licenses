import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/firebase_config.dart';
import '../models/invoice_model.dart';
import 'firebase_service.dart';

class SaveResult {
  final Invoice invoice;
  final bool isCloudSaved;

  const SaveResult({required this.invoice, required this.isCloudSaved});
}

class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int pendingCount;
  final String message;

  const SyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.pendingCount = 0,
    this.message = '',
  });
}

class InvoiceStorageService {
  static const String _storageKey = 'proforma_invoices_local';
  static const String _pendingDeletionsKey = 'pending_deleted_invoice_ids';
  final Uuid _uuid = const Uuid();

  /// Retrieve all locally saved invoices
  Future<List<Invoice>> getLocalInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        final invoices = list
            .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
            .toList();
        _sortInvoices(invoices);
        return invoices;
      }
    } catch (_) {}
    return [];
  }

  /// Save local list to persistent storage
  Future<void> _saveLocalInvoices(List<Invoice> invoices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = json.encode(invoices.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, rawJson);
    } catch (_) {}
  }

  /// Get pending deleted invoice IDs
  Future<List<String>> _getPendingDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_pendingDeletionsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Save pending deleted invoice IDs
  Future<void> _savePendingDeletedIds(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_pendingDeletionsKey, ids);
    } catch (_) {}
  }

  /// Sort invoices newest first
  void _sortInvoices(List<Invoice> list) {
    list.sort((a, b) {
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  /// Count how many invoices are stored locally but pending Firebase sync
  Future<int> getPendingSyncCount() async {
    final local = await getLocalInvoices();
    final unsynced = local.where((inv) => !inv.isSynced).length;
    final pendingDeletes = await _getPendingDeletedIds();
    return unsynced + pendingDeletes.length;
  }

  /// Retrieve all saved invoices (Local + Cloud sync)
  Future<List<Invoice>> getAllInvoices({bool syncWithCloud = true}) async {
    if (syncWithCloud) {
      await this.syncWithCloud();
    }
    return await getLocalInvoices();
  }

  /// Two-way synchronization between Local Storage and Firebase Cloud Firestore:
  /// 1. Process pending deletions to cloud
  /// 2. Upload any offline (un-synced) invoices to Firebase
  /// 3. Download newly created / updated invoices from Firebase and merge into local storage
  Future<SyncResult> syncWithCloud() async {
    int uploaded = 0;
    int downloaded = 0;

    // Check Firebase configuration
    final creds = await FirebaseConfig.loadCredentials();
    if (!FirebaseConfig.isConfigured(creds['projectId'] ?? '', creds['apiKey'] ?? '')) {
      final local = await getLocalInvoices();
      final pending = local.where((e) => !e.isSynced).length;
      return SyncResult(
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
        final ok = await FirebaseService.deleteInvoice(id);
        if (ok) {
          successfullyDeleted.add(id);
        }
      }
      if (successfullyDeleted.isNotEmpty) {
        pendingDeletes.removeWhere((id) => successfullyDeleted.contains(id));
        await _savePendingDeletedIds(pendingDeletes);
      }

      // 2. Upload un-synced local invoices to Firebase
      List<Invoice> localInvoices = await getLocalInvoices();
      bool localUpdated = false;

      for (int i = 0; i < localInvoices.length; i++) {
        final inv = localInvoices[i];
        if (!inv.isSynced) {
          final ok = await FirebaseService.saveInvoice(inv);
          if (ok) {
            localInvoices[i] = inv.copyWith(isSynced: true);
            localUpdated = true;
            uploaded++;
          }
        }
      }

      if (localUpdated) {
        await _saveLocalInvoices(localInvoices);
      }

      // 3. Download & Merge from Firebase
      final cloudInvoices = await FirebaseService.fetchAllInvoices();
      if (cloudInvoices.isNotEmpty) {
        final Map<String, Invoice> map = {};
        for (final inv in localInvoices) {
          if (inv.id != null) map[inv.id!] = inv;
        }

        final currentPendingDeletes = await _getPendingDeletedIds();

        for (final cinv in cloudInvoices) {
          if (cinv.id == null || currentPendingDeletes.contains(cinv.id)) {
            continue;
          }
          final existing = map[cinv.id!];
          if (existing == null) {
            map[cinv.id!] = cinv.copyWith(isSynced: true);
            downloaded++;
          } else if (existing.isSynced) {
            // Both are synced: take newer one if cloud is newer
            if (cinv.updatedAt != null &&
                existing.updatedAt != null &&
                cinv.updatedAt!.isAfter(existing.updatedAt!)) {
              map[cinv.id!] = cinv.copyWith(isSynced: true);
            }
          }
          // If existing is !isSynced, keep local because it has un-synced local changes
        }

        localInvoices = map.values.toList();
        _sortInvoices(localInvoices);
        await _saveLocalInvoices(localInvoices);
      }

      final pendingRemaining = localInvoices.where((e) => !e.isSynced).length;
      return SyncResult(
        success: true,
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        pendingCount: pendingRemaining,
        message: 'Sync completed successfully',
      );
    } catch (e) {
      final local = await getLocalInvoices();
      final pendingRemaining = local.where((e) => !e.isSynced).length;
      return SyncResult(
        success: false,
        pendingCount: pendingRemaining,
        message: 'Sync error: $e',
      );
    }
  }

  /// Save or update an invoice (Local persistent first + Cloud Firestore sync)
  Future<SaveResult> saveInvoice(Invoice invoice, {bool asNew = false}) async {
    final List<Invoice> invoices = await getLocalInvoices();

    // If asNew is requested OR id is null/empty OR id is legacy 'sample-inv-01', generate a fresh unique UUID!
    final bool forceNew = asNew ||
        invoice.id == null ||
        invoice.id!.trim().isEmpty ||
        invoice.id == 'sample-inv-01';

    final String docId = forceNew ? _uuid.v4() : invoice.id!;

    // 1. Immediately store to local storage with isSynced: false (Instant offline durability)
    Invoice toSave = invoice.copyWith(
      id: docId,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    final existingIndex = forceNew ? -1 : invoices.indexWhere((inv) => inv.id == docId);
    if (existingIndex >= 0) {
      invoices[existingIndex] = toSave;
    } else {
      invoices.insert(0, toSave);
    }

    _sortInvoices(invoices);
    await _saveLocalInvoices(invoices);

    // 2. Try immediate Cloud Firestore sync
    bool cloudSaved = false;
    try {
      cloudSaved = await FirebaseService.saveInvoice(toSave);
      if (cloudSaved) {
        toSave = toSave.copyWith(isSynced: true);
        final idx = invoices.indexWhere((inv) => inv.id == docId);
        if (idx >= 0) {
          invoices[idx] = toSave;
          await _saveLocalInvoices(invoices);
        }
      }
    } catch (_) {
      cloudSaved = false;
    }

    return SaveResult(invoice: toSave, isCloudSaved: cloudSaved);
  }

  /// Delete an invoice by ID (Local persistent + Cloud Firestore + pending queue)
  Future<bool> deleteInvoice(String id) async {
    try {
      final List<Invoice> invoices = await getLocalInvoices();
      invoices.removeWhere((inv) => inv.id == id);
      await _saveLocalInvoices(invoices);

      // Track as pending deletion
      final pendingDeletes = await _getPendingDeletedIds();
      if (!pendingDeletes.contains(id)) {
        pendingDeletes.add(id);
        await _savePendingDeletedIds(pendingDeletes);
      }

      // Try deleting from cloud
      final ok = await FirebaseService.deleteInvoice(id);
      if (ok) {
        pendingDeletes.remove(id);
        await _savePendingDeletedIds(pendingDeletes);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Duplicate an existing invoice
  Future<SaveResult> duplicateInvoice(Invoice source) async {
    final String newId = _uuid.v4();
    final String newInvoiceNo = '${source.metadata.invoiceNo}-COPY';
    final duplicated = source.copyWith(
      id: newId,
      metadata: source.metadata.copyWith(invoiceNo: newInvoiceNo),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    return await saveInvoice(duplicated);
  }
}
