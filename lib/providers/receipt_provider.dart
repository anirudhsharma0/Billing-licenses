import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/sample_data.dart';
import '../models/invoice_model.dart';
import '../models/receipt_model.dart';
import '../services/receipt_firestore_service.dart';

class ReceiptProvider with ChangeNotifier {
  final ReceiptStorageService _storageService = ReceiptStorageService();

  List<ReceiptVoucher> _savedReceipts = [];
  late ReceiptVoucher _currentReceipt;
  ReceiptPageSize _pageSize = ReceiptPageSize.a4;
  String _activeTab = 'form'; // 'form' or 'list'
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSyncing = false;
  String _editSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final bool enablePeriodicSync;
  Timer? _autoSyncTimer;

  ReceiptProvider({this.enablePeriodicSync = true}) {
    _currentReceipt = _buildInitialReceipt();
    _init();
  }

  List<ReceiptVoucher> get savedReceipts => _savedReceipts;
  ReceiptVoucher get currentReceipt => _currentReceipt;
  ReceiptPageSize get pageSize => _pageSize;
  String get activeTab => _activeTab;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSyncing => _isSyncing;
  String get editSessionId => _editSessionId;
  int get pendingSyncCount => _savedReceipts.where((r) => !r.isSynced).length;
  double get totalCollected =>
      _savedReceipts.fold(0.0, (sum, r) => sum + r.amount);

  static String formatTodayTallyDate() {
    return DateFormat('dd-MMM-yy').format(DateTime.now());
  }

  ReceiptVoucher _buildInitialReceipt() {
    return ReceiptVoucher(
      receiptNo: '1',
      date: formatTodayTallyDate(),
      seller: SampleData.sampleInvoice.seller,
    );
  }

  void _refreshEditSession() {
    _editSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _init() async {
    _savedReceipts = await _storageService.getLocalReceipts();
    if (_currentReceipt.id == null && _currentReceipt.customerName.isEmpty) {
      _currentReceipt = _currentReceipt.copyWith(receiptNo: _nextReceiptNo());
    }
    notifyListeners();

    if (enablePeriodicSync) {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!_isSyncing) {
          syncReceipts(showLoading: false);
        }
      });
      syncReceipts(showLoading: false);
    }
  }

  String _nextReceiptNo() {
    int maxNum = 0;
    for (final r in _savedReceipts) {
      final parsed = int.tryParse(r.receiptNo.trim());
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      }
    }
    return (maxNum > 0 ? maxNum + 1 : _savedReceipts.length + 1).toString();
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void setPageSize(ReceiptPageSize size) {
    _pageSize = size;
    notifyListeners();
  }

  void updateCurrentReceipt(ReceiptVoucher updated) {
    _currentReceipt = updated;
    notifyListeners();
  }

  /// Prepare a new receipt, optionally pre-filled from a Saved Bill
  void prepareNewReceipt({
    String? customerName,
    double? amount,
    String? linkedInvoiceId,
    String? linkedInvoiceNo,
    SellerDetails? seller,
  }) {
    _currentReceipt = ReceiptVoucher(
      id: null,
      receiptNo: _nextReceiptNo(),
      date: formatTodayTallyDate(),
      customerName: customerName?.trim() ?? '',
      amount: amount ?? 0.0,
      paymentMode: PaymentMode.cash,
      referenceNo: '',
      remarks: linkedInvoiceNo != null && linkedInvoiceNo.trim().isNotEmpty
          ? 'Against Bill #$linkedInvoiceNo'
          : '',
      linkedInvoiceId: linkedInvoiceId,
      linkedInvoiceNo: linkedInvoiceNo,
      seller: seller ?? _currentReceipt.seller,
    );
    _activeTab = 'form';
    _refreshEditSession();
    notifyListeners();
  }

  void loadReceiptForEdit(ReceiptVoucher receipt) {
    _currentReceipt = receipt;
    _activeTab = 'form';
    _refreshEditSession();
    notifyListeners();
  }

  Future<ReceiptSaveResult?> saveCurrentReceipt({bool asNew = false}) async {
    _isSaving = true;
    notifyListeners();
    try {
      final result = await _storageService.saveReceipt(
        _currentReceipt,
        asNew: asNew,
      );
      _currentReceipt = result.receipt;
      _savedReceipts = await _storageService.getLocalReceipts();
      _isSaving = false;
      notifyListeners();
      return result;
    } catch (_) {
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteReceipt(String id) async {
    await _storageService.deleteReceipt(id);
    _savedReceipts = await _storageService.getLocalReceipts();
    if (_currentReceipt.id == id) {
      _currentReceipt = _currentReceipt.copyWith(id: null);
    }
    notifyListeners();
  }

  Future<ReceiptSyncResult?> syncReceipts({bool showLoading = false}) async {
    if (_isSyncing) return null;
    _isSyncing = true;
    if (showLoading) _isLoading = true;
    notifyListeners();

    ReceiptSyncResult? result;
    try {
      result = await _storageService.syncWithCloud();
      _savedReceipts = await _storageService.getLocalReceipts();
    } catch (_) {}

    _isSyncing = false;
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> refreshReceipts() async {
    await syncReceipts(showLoading: true);
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

