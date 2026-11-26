import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/purchase_model.dart';
import '../services/purchase_firestore_service.dart';

class PurchaseProvider with ChangeNotifier {
  final PurchaseStorageService _storageService = PurchaseStorageService();

  List<PurchaseBill> _savedPurchases = [];
  late PurchaseBill _currentPurchase;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSyncing = false;
  String _editSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final bool enablePeriodicSync;
  Timer? _autoSyncTimer;

  PurchaseProvider({this.enablePeriodicSync = true}) {
    _currentPurchase = _buildInitialPurchase();
    _init();
  }

  List<PurchaseBill> get savedPurchases => _savedPurchases;
  PurchaseBill get currentPurchase => _currentPurchase;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSyncing => _isSyncing;
  String get editSessionId => _editSessionId;
  int get pendingSyncCount =>
      _savedPurchases.where((p) => !p.isSynced).length;

  double get totalPurchaseAmount =>
      _savedPurchases.fold(0.0, (sum, p) => sum + p.grandTotal);

  double get totalInputGst =>
      _savedPurchases.fold(0.0, (sum, p) => sum + p.totalInputGst);

  static String formatTodayDate() {
    return DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  PurchaseBill _buildInitialPurchase() {
    return PurchaseBill(
      metadata: PurchaseMetadata(date: formatTodayDate()),
      items: const [PurchaseItem()],
    );
  }

  void _refreshEditSession() {
    _editSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _init() async {
    _savedPurchases = await _storageService.getLocalPurchases();
    notifyListeners();

    if (enablePeriodicSync) {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!_isSyncing) {
          syncPurchases(showLoading: false);
        }
      });
      syncPurchases(showLoading: false);
    }
  }

  void prepareNewPurchase() {
    _currentPurchase = _buildInitialPurchase();
    _refreshEditSession();
    notifyListeners();
  }

  void loadPurchaseForEdit(PurchaseBill purchase) {
    _currentPurchase = purchase;
    _refreshEditSession();
    notifyListeners();
  }

  void updateCurrentPurchase(PurchaseBill updated) {
    _currentPurchase = updated;
    notifyListeners();
  }

  void addItem() {
    final updated = List<PurchaseItem>.from(_currentPurchase.items)
      ..add(const PurchaseItem());
    _currentPurchase = _currentPurchase.copyWith(items: updated);
    notifyListeners();
  }

  void updateItem(int index, PurchaseItem item) {
    if (index < 0 || index >= _currentPurchase.items.length) return;
    final updated = List<PurchaseItem>.from(_currentPurchase.items);
    updated[index] = item;
    _currentPurchase = _currentPurchase.copyWith(items: updated);
    notifyListeners();
  }

  void removeItem(int index) {
    if (_currentPurchase.items.length <= 1) return;
    final updated = List<PurchaseItem>.from(_currentPurchase.items)
      ..removeAt(index);
    _currentPurchase = _currentPurchase.copyWith(items: updated);
    _refreshEditSession();
    notifyListeners();
  }

  void loadAllItems(List<PurchaseItem> catalogItems) {
    _currentPurchase = _currentPurchase.copyWith(
      items: List<PurchaseItem>.from(catalogItems),
    );
    _refreshEditSession();
    notifyListeners();
  }

  Future<PurchaseSaveResult?> saveCurrentPurchase({bool asNew = false}) async {
    _isSaving = true;
    notifyListeners();
    try {
      final result = await _storageService.savePurchase(
        _currentPurchase,
        asNew: asNew,
      );
      _currentPurchase = result.purchase;
      _savedPurchases = await _storageService.getLocalPurchases();
      _isSaving = false;
      notifyListeners();
      return result;
    } catch (_) {
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deletePurchase(String id) async {
    await _storageService.deletePurchase(id);
    _savedPurchases = await _storageService.getLocalPurchases();
    if (_currentPurchase.id == id) {
      _currentPurchase = _currentPurchase.copyWith(id: null);
    }
    notifyListeners();
  }

  Future<PurchaseSyncResult?> syncPurchases({bool showLoading = false}) async {
    if (_isSyncing) return null;
    _isSyncing = true;
    if (showLoading) _isLoading = true;
    notifyListeners();

    PurchaseSyncResult? result;
    try {
      result = await _storageService.syncWithCloud();
      _savedPurchases = await _storageService.getLocalPurchases();
    } catch (_) {}

    _isSyncing = false;
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> refreshPurchases() async {
    await syncPurchases(showLoading: true);
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

