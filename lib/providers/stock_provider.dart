import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/solar_purchase_catalog.dart';
import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import '../models/stock_model.dart';

class StockProvider with ChangeNotifier {
  static const String _adjustmentsKey = 'stock_adjustments_local';
  static const String _baselineKey = 'stock_baseline_at';

  final Map<String, StockAdjustment> _adjustments = {};
  DateTime? _stockBaselineAt;
  bool _isLoaded = false;
  bool _hasLocalMutation = false;

  StockProvider({DateTime? initialBaseline}) : _stockBaselineAt = initialBaseline {
    _loadState();
  }

  bool get isLoaded => _isLoaded;
  DateTime? get stockBaselineAt => _stockBaselineAt;
  Map<String, StockAdjustment> get adjustments => Map.unmodifiable(_adjustments);

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_hasLocalMutation) {
        _isLoaded = true;
        return;
      }
      final raw = prefs.getString(_adjustmentsKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final list = StockAdjustment.decodeList(raw);
        for (final adj in list) {
          if (adj.itemKey.isNotEmpty) {
            _adjustments[adj.itemKey] = adj;
          }
        }
      }

      final baselineRaw = prefs.getString(_baselineKey);
      if (baselineRaw != null && baselineRaw.isNotEmpty) {
        _stockBaselineAt = DateTime.tryParse(baselineRaw);
      }
      // If no baseline is saved yet, start fresh from now so old historical bills start at 0.
      if (_stockBaselineAt == null) {
        _stockBaselineAt = DateTime.now();
        await prefs.setString(_baselineKey, _stockBaselineAt!.toIso8601String());
      }
    } catch (_) {
      _stockBaselineAt ??= DateTime.now();
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveAdjustments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _adjustmentsKey,
        StockAdjustment.encodeList(_adjustments.values.toList()),
      );
    } catch (_) {}
  }

  /// Resets all stock counts to 0 from this moment forward.
  /// Only bills/purchases saved or updated after this timestamp will be counted.
  Future<void> resetStockToZero() async {
    _hasLocalMutation = true;
    _adjustments.clear();
    _stockBaselineAt = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adjustmentsKey);
      await prefs.setString(_baselineKey, _stockBaselineAt!.toIso8601String());
    } catch (_) {}
  }

  Future<void> setOpeningStock({
    required String itemName,
    required double openingQty,
    String hsn = '',
    String unit = 'PCS',
  }) async {
    final cleanName = itemName.trim();
    if (cleanName.isEmpty) return;

    _hasLocalMutation = true;

    final key = StockAdjustment.normalizeKey(cleanName);
    _adjustments[key] = StockAdjustment(
      itemKey: key,
      itemName: cleanName,
      hsn: hsn.trim(),
      unit: unit.trim().isEmpty ? 'PCS' : unit.trim(),
      openingQty: openingQty,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveAdjustments();
  }

  Future<void> removeAdjustment(String itemKey) async {
    _adjustments.remove(itemKey);
    notifyListeners();
    await _saveAdjustments();
  }

  bool _isAfterBaseline(DateTime? updatedAt) {
    final baseline = _stockBaselineAt;
    if (baseline == null) return true;
    if (updatedAt == null) return false;
    return !updatedAt.isBefore(baseline);
  }

  /// Computes live stock summary by combining:
  /// 1. Opening / Manual adjustments
  /// 2. Saved Purchase Bills (Stock In) at/after baseline
  /// 3. Saved Sales Invoices (Stock Out) at/after baseline
  /// 4. Optionally includes all items from SolarPurchaseCatalog
  List<StockItemSummary> buildStockSummary({
    required List<PurchaseBill> purchases,
    required List<Invoice> invoices,
    bool includeCatalogDefaults = false,
  }) {
    final Map<String, _MutableStockBucket> buckets = {};

    _MutableStockBucket getOrCreate({
      required String name,
      String hsn = '',
      String unit = 'PCS',
    }) {
      final key = StockAdjustment.normalizeKey(name);
      return buckets.putIfAbsent(
        key,
        () => _MutableStockBucket(
          key: key,
          name: name.trim(),
          hsn: hsn.trim(),
          unit: unit.trim().isEmpty ? 'PCS' : unit.trim(),
        ),
      );
    }

    if (includeCatalogDefaults) {
      for (final item in SolarPurchaseCatalog.items) {
        final b = getOrCreate(
          name: item.description,
          hsn: item.hsn,
          unit: item.unit,
        );
        b.lastPurchaseRate = item.rate;
      }
    }

    for (final adj in _adjustments.values) {
      final b = getOrCreate(
        name: adj.itemName,
        hsn: adj.hsn,
        unit: adj.unit,
      );
      b.openingQty = adj.openingQty;
      if (b.hsn.isEmpty && adj.hsn.isNotEmpty) b.hsn = adj.hsn;
      if (adj.unit.isNotEmpty) b.unit = adj.unit;
    }

    for (final bill in purchases) {
      if (!_isAfterBaseline(bill.updatedAt)) continue;
      for (final item in bill.items) {
        if (item.description.trim().isEmpty) continue;
        final b = getOrCreate(
          name: item.description,
          hsn: item.hsn,
          unit: item.unit,
        );
        b.purchasedQty += item.quantity;
        if (b.hsn.isEmpty && item.hsn.isNotEmpty) b.hsn = item.hsn;
        if (item.unit.isNotEmpty) b.unit = item.unit;
        if (item.rate > 0) b.lastPurchaseRate = item.rate;
      }
    }

    for (final inv in invoices) {
      if (!_isAfterBaseline(inv.updatedAt)) continue;
      for (final item in inv.items) {
        if (item.description.trim().isEmpty) continue;
        final b = getOrCreate(
          name: item.description,
          hsn: item.hsn,
          unit: item.unit,
        );
        b.soldQty += item.quantity;
        if (b.hsn.isEmpty && item.hsn.isNotEmpty) b.hsn = item.hsn;
        if (b.unit.isEmpty && item.unit.isNotEmpty) b.unit = item.unit;
        if (item.rate > 0) b.lastSaleRate = item.rate;
      }
    }

    final result = buckets.values
        .map(
          (b) => StockItemSummary(
            itemKey: b.key,
            itemName: b.name,
            hsn: b.hsn,
            unit: b.unit,
            openingQty: b.openingQty,
            purchasedQty: b.purchasedQty,
            soldQty: b.soldQty,
            lastPurchaseRate: b.lastPurchaseRate,
            lastSaleRate: b.lastSaleRate,
          ),
        )
        .toList();

    result.sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
    return result;
  }
}

class _MutableStockBucket {
  final String key;
  final String name;
  String hsn;
  String unit;
  double openingQty = 0.0;
  double purchasedQty = 0.0;
  double soldQty = 0.0;
  double lastPurchaseRate = 0.0;
  double lastSaleRate = 0.0;

  _MutableStockBucket({
    required this.key,
    required this.name,
    required this.hsn,
    required this.unit,
  });
}
