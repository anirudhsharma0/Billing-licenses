import 'dart:convert';

/// Manual opening/adjustment entry for an inventory item.
class StockAdjustment {
  final String itemKey;
  final String itemName;
  final String hsn;
  final String unit;
  final double openingQty;
  final DateTime? updatedAt;

  const StockAdjustment({
    required this.itemKey,
    required this.itemName,
    this.hsn = '',
    this.unit = 'PCS',
    this.openingQty = 0.0,
    this.updatedAt,
  });

  static String normalizeKey(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  StockAdjustment copyWith({
    String? itemKey,
    String? itemName,
    String? hsn,
    String? unit,
    double? openingQty,
    DateTime? updatedAt,
  }) {
    return StockAdjustment(
      itemKey: itemKey ?? this.itemKey,
      itemName: itemName ?? this.itemName,
      hsn: hsn ?? this.hsn,
      unit: unit ?? this.unit,
      openingQty: openingQty ?? this.openingQty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'itemKey': itemKey,
        'itemName': itemName,
        'hsn': hsn,
        'unit': unit,
        'openingQty': openingQty,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory StockAdjustment.fromJson(Map<String, dynamic> json) => StockAdjustment(
        itemKey: json['itemKey'] ?? '',
        itemName: json['itemName'] ?? '',
        hsn: json['hsn'] ?? '',
        unit: json['unit'] ?? 'PCS',
        openingQty: (json['openingQty'] as num?)?.toDouble() ?? 0.0,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );

  static String encodeList(List<StockAdjustment> items) =>
      json.encode(items.map((e) => e.toJson()).toList());

  static List<StockAdjustment> decodeList(String raw) {
    final List<dynamic> list = json.decode(raw);
    return list
        .map((e) => StockAdjustment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Aggregated stock summary for a single item across Purchases, Sales, and Opening Stock.
class StockItemSummary {
  final String itemKey;
  final String itemName;
  final String hsn;
  final String unit;
  final double openingQty;
  final double purchasedQty;
  final double soldQty;
  final double lastPurchaseRate;
  final double lastSaleRate;

  const StockItemSummary({
    required this.itemKey,
    required this.itemName,
    this.hsn = '',
    this.unit = 'PCS',
    this.openingQty = 0.0,
    this.purchasedQty = 0.0,
    this.soldQty = 0.0,
    this.lastPurchaseRate = 0.0,
    this.lastSaleRate = 0.0,
  });

  static String normalizeKey(String name) =>
      StockAdjustment.normalizeKey(name);

  double get totalInQty => openingQty + purchasedQty;
  double get availableQty => totalInQty - soldQty;

  bool get isOutOfStock => availableQty <= 0;
  bool get isLowStock => availableQty > 0 && availableQty <= 5;
}

