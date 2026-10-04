import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/firebase_config.dart';
import '../data/sample_data.dart';
import '../models/invoice_model.dart';
import '../services/invoice_storage_service.dart';

class InvoiceProvider with ChangeNotifier {
  final InvoiceStorageService _storageService = InvoiceStorageService();

  Invoice _invoice = SampleData.sampleInvoice;
  List<Invoice> _savedInvoices = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSyncing = false;
  bool _isFirebaseConfigured = false;
  double _zoomLevel = 1.0;
  String _viewMode = 'form'; // 'form' (Details Entry), 'preview' (A4 Bill), 'records' (Saved Bills), 'split'
  int _selectedFormTab = 0; // 0: Items, 1: Buyer/Consignee, 2: Invoice Info, 3: Seller/Bank
  String _editSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final bool enablePeriodicSync;
  Timer? _autoSyncTimer;

  InvoiceProvider({this.enablePeriodicSync = true}) {
    _initStorageAndFirebase();
  }

  // Getters
  Invoice get invoice => _invoice;
  List<Invoice> get savedInvoices => _savedInvoices;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSyncing => _isSyncing;
  bool get isFirebaseConfigured => _isFirebaseConfigured;
  int get pendingSyncCount => _savedInvoices.where((inv) => !inv.isSynced).length;
  double get zoomLevel => _zoomLevel;
  String get viewMode => _viewMode;
  int get selectedFormTab => _selectedFormTab;
  String get editSessionId => _editSessionId;

  void _refreshEditSession() {
    _editSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  // View & UI controls
  void setViewMode(String mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void generateBill() {
    _viewMode = 'preview';
    notifyListeners();
  }

  void setSelectedFormTab(int tab) {
    _selectedFormTab = tab;
    notifyListeners();
  }

  void setZoomLevel(double zoom) {
    _zoomLevel = zoom.clamp(0.5, 1.5);
    notifyListeners();
  }

  void zoomIn() {
    setZoomLevel(_zoomLevel + 0.10);
  }

  void zoomOut() {
    setZoomLevel(_zoomLevel - 0.10);
  }

  void resetZoom() {
    setZoomLevel(1.0);
  }

  // Storage operations
  Future<void> _initStorageAndFirebase() async {
    // 1. Immediately load local offline data (instant startup)
    _savedInvoices = await _storageService.getLocalInvoices();
    notifyListeners();

    // 2. Check Firebase status
    await checkFirebaseStatus();

    // 3. Start background periodic auto-sync (runs every 30 seconds when enabled)
    if (enablePeriodicSync) {
      _startPeriodicSync();
      // 4. Initial sync with cloud in background
      syncInvoices(showLoading: false);
    }
  }

  void _startPeriodicSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isSyncing) {
        syncInvoices(showLoading: false);
      }
    });
  }

  Future<void> checkFirebaseStatus() async {
    final creds = await FirebaseConfig.loadCredentials();
    _isFirebaseConfigured = FirebaseConfig.isConfigured(
      creds['projectId'] ?? '',
      creds['apiKey'] ?? '',
    );
    notifyListeners();
  }

  Future<SyncResult?> syncInvoices({bool showLoading = false}) async {
    if (_isSyncing) return null;
    _isSyncing = true;
    if (showLoading) {
      _isLoading = true;
    }
    notifyListeners();

    SyncResult? result;
    try {
      result = await _storageService.syncWithCloud();
      _savedInvoices = await _storageService.getLocalInvoices();
    } catch (_) {}

    _isSyncing = false;
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> refreshInvoices() async {
    await syncInvoices(showLoading: true);
  }

  void setSavedName(String name) {
    _invoice = _invoice.copyWith(savedName: name);
    notifyListeners();
  }

  Future<SaveResult?> saveCurrentInvoice({
    String? customSavedName,
    bool asNew = false,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      Invoice toSave = _invoice;
      if (customSavedName != null && customSavedName.trim().isNotEmpty) {
        toSave = toSave.copyWith(savedName: customSavedName.trim());
      } else if (toSave.savedName.trim().isEmpty && toSave.buyer.name.trim().isNotEmpty) {
        toSave = toSave.copyWith(savedName: toSave.buyer.name.trim());
      }

      final result = await _storageService.saveInvoice(toSave, asNew: asNew);
      _invoice = result.invoice;
      _savedInvoices = await _storageService.getAllInvoices(syncWithCloud: false);
      _isSaving = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadSavedInvoice(Invoice inv, {bool openPreview = false}) async {
    _invoice = inv;
    _refreshEditSession();
    if (openPreview) {
      _viewMode = 'preview';
    }
    notifyListeners();
  }

  Future<void> deleteSavedInvoice(String id) async {
    await _storageService.deleteInvoice(id);
    _savedInvoices = await _storageService.getAllInvoices(syncWithCloud: false);
    if (_invoice.id == id) {
      _invoice = _invoice.copyWith(id: null);
    }
    notifyListeners();
  }

  Future<void> duplicateSavedInvoice(Invoice inv) async {
    final result = await _storageService.duplicateInvoice(inv);
    _invoice = result.invoice;
    _refreshEditSession();
    _savedInvoices = await _storageService.getAllInvoices(syncWithCloud: false);
    notifyListeners();
  }

  // Invoice Mutations
  void updateInvoice(Invoice updated) {
    _invoice = updated;
    notifyListeners();
  }

  void setInvoiceTitle(String title) {
    _invoice = _invoice.copyWith(invoiceTitle: title);
    notifyListeners();
  }

  void setTaxMode(TaxMode mode) {
    _invoice = _invoice.copyWith(taxMode: mode);
    notifyListeners();
  }

  void setRoundOff(double roundOff) {
    _invoice = _invoice.copyWith(roundOff: roundOff);
    notifyListeners();
  }

  void updateSeller(SellerDetails seller) {
    _invoice = _invoice.copyWith(seller: seller);
    notifyListeners();
  }

  void updateBuyer(BuyerDetails buyer) {
    _invoice = _invoice.copyWith(buyer: buyer);
    notifyListeners();
  }

  void updateBuyerAndSyncConsignee(BuyerDetails buyer, {bool syncConsignee = true}) {
    _invoice = _invoice.copyWith(buyer: buyer);
    if (syncConsignee) {
      _invoice = _invoice.copyWith(
        consignee: ConsigneeDetails(
          name: buyer.name,
          address: buyer.address,
          state: buyer.state,
          stateCode: buyer.stateCode,
          gstin: buyer.gstin,
        ),
      );
    }
    notifyListeners();
  }

  void updateConsignee(ConsigneeDetails consignee) {
    _invoice = _invoice.copyWith(consignee: consignee);
    notifyListeners();
  }

  void copyBuyerToConsignee() {
    _invoice = _invoice.copyWith(
      consignee: ConsigneeDetails(
        name: _invoice.buyer.name,
        address: _invoice.buyer.address,
        state: _invoice.buyer.state,
        stateCode: _invoice.buyer.stateCode,
        gstin: _invoice.buyer.gstin,
      ),
    );
    notifyListeners();
  }

  void updateMetadata(InvoiceMetadata meta) {
    _invoice = _invoice.copyWith(metadata: meta);
    notifyListeners();
  }

  void updateBankDetails(BankDetails bank) {
    _invoice = _invoice.copyWith(bankDetails: bank);
    notifyListeners();
  }

  // Items Operations
  void addItem() {
    final List<InvoiceItem> updatedItems = List.from(_invoice.items);
    updatedItems.add(const InvoiceItem(
      description: '',
      subtext: '',
      hsn: '',
      quantity: 1,
      unit: 'Nos',
      rate: 0,
      taxRate: 18,
    ));
    _invoice = _invoice.copyWith(items: updatedItems);
    notifyListeners();
  }

  void updateItem(int index, InvoiceItem item) {
    if (index >= 0 && index < _invoice.items.length) {
      final List<InvoiceItem> updatedItems = List.from(_invoice.items);
      updatedItems[index] = item;
      _invoice = _invoice.copyWith(items: updatedItems);
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (_invoice.items.length <= 1) return;
    final List<InvoiceItem> updatedItems = List.from(_invoice.items);
    updatedItems.removeAt(index);
    _invoice = _invoice.copyWith(items: updatedItems);
    notifyListeners();
  }

  void duplicateItem(int index) {
    if (index >= 0 && index < _invoice.items.length) {
      final List<InvoiceItem> updatedItems = List.from(_invoice.items);
      final itemToCopy = updatedItems[index];
      updatedItems.insert(index + 1, itemToCopy);
      _invoice = _invoice.copyWith(items: updatedItems);
      notifyListeners();
    }
  }

  void loadSampleData() {
    _invoice = SampleData.sampleInvoice;
    _refreshEditSession();
    _viewMode = 'form';
    notifyListeners();
  }

  void resetToNew() {
    int maxNum = 0;
    for (final inv in _savedInvoices) {
      final parsed = int.tryParse(inv.metadata.invoiceNo.trim());
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      }
    }
    final nextNo = (maxNum > 0 ? maxNum + 1 : _savedInvoices.length + 1).toString();

    // Preserve current items, seller, bank details so user only changes buyer details!
    final templateItems = _invoice.items.isNotEmpty
        ? _invoice.items
        : SampleData.newEmptyInvoice.items;
    final templateSeller = _invoice.seller.name.isNotEmpty
        ? _invoice.seller
        : SampleData.newEmptyInvoice.seller;
    final templateBank = _invoice.bankDetails.bankName.isNotEmpty
        ? _invoice.bankDetails
        : SampleData.newEmptyInvoice.bankDetails;
    final templateTaxMode = _invoice.taxMode;
    final templateRoundOff = _invoice.roundOff;

    _invoice = Invoice(
      id: null,
      savedName: '',
      invoiceTitle: _invoice.invoiceTitle,
      taxMode: templateTaxMode,
      roundOff: templateRoundOff,
      seller: templateSeller,
      bankDetails: templateBank,
      items: templateItems,
      metadata: InvoiceMetadata(
        invoiceNo: nextNo,
        date: '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
      ),
      buyer: const BuyerDetails(
        name: '',
        address: '',
        state: 'Haryana',
        stateCode: '06',
        gstin: '',
      ),
      consignee: const ConsigneeDetails(
        name: '',
        address: '',
        state: 'Haryana',
        stateCode: '06',
        gstin: '',
      ),
    );
    _refreshEditSession();
    _viewMode = 'form';
    _selectedFormTab = 0;
    notifyListeners();
  }

  void createForNewCustomer(Invoice source) {
    int maxNum = 0;
    for (final inv in _savedInvoices) {
      final parsed = int.tryParse(inv.metadata.invoiceNo.trim());
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      }
    }
    final nextNo = (maxNum > 0 ? maxNum + 1 : _savedInvoices.length + 1).toString();

    _invoice = source.copyWith(
      id: null,
      savedName: '',
      metadata: source.metadata.copyWith(
        invoiceNo: nextNo,
        date: '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
      ),
      buyer: const BuyerDetails(
        name: '',
        address: '',
        state: 'Haryana',
        stateCode: '06',
      ),
      consignee: const ConsigneeDetails(
        name: '',
        address: '',
        state: 'Haryana',
        stateCode: '06',
      ),
    );
    _refreshEditSession();
    _viewMode = 'form';
    _selectedFormTab = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
