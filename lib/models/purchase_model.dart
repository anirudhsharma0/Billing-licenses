import 'dart:convert';
import '../utils/number_to_words.dart';

class SupplierDetails {
  final String name;
  final String gstin;
  final String address;
  final String state;
  final String stateCode;

  const SupplierDetails({
    this.name = '',
    this.gstin = '',
    this.address = '',
    this.state = 'Haryana',
    this.stateCode = '06',
  });

  SupplierDetails copyWith({
    String? name,
    String? gstin,
    String? address,
    String? state,
    String? stateCode,
  }) {
    return SupplierDetails(
      name: name ?? this.name,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'gstin': gstin,
        'address': address,
        'state': state,
        'stateCode': stateCode,
      };

  factory SupplierDetails.fromJson(Map<String, dynamic> json) =>
      SupplierDetails(
        name: json['name'] ?? '',
        gstin: json['gstin'] ?? '',
        address: json['address'] ?? '',
        state: json['state'] ?? 'Haryana',
        stateCode: json['stateCode'] ?? '06',
      );
}

class PurchaseMetadata {
  final String invoiceNo;
  final String date;
  final String referenceNo;
  final String ewayBillNo;
  final String vehicleNo;

  const PurchaseMetadata({
    this.invoiceNo = '',
    this.date = '',
    this.referenceNo = '',
    this.ewayBillNo = '',
    this.vehicleNo = '',
  });

  PurchaseMetadata copyWith({
    String? invoiceNo,
    String? date,
    String? referenceNo,
    String? ewayBillNo,
    String? vehicleNo,
  }) {
    return PurchaseMetadata(
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      referenceNo: referenceNo ?? this.referenceNo,
      ewayBillNo: ewayBillNo ?? this.ewayBillNo,
      vehicleNo: vehicleNo ?? this.vehicleNo,
    );
  }

  Map<String, dynamic> toJson() => {
        'invoiceNo': invoiceNo,
        'date': date,
        'referenceNo': referenceNo,
        'ewayBillNo': ewayBillNo,
        'vehicleNo': vehicleNo,
      };

  factory PurchaseMetadata.fromJson(Map<String, dynamic> json) =>
      PurchaseMetadata(
        invoiceNo: json['invoiceNo'] ?? '',
        date: json['date'] ?? '',
        referenceNo: json['referenceNo'] ?? '',
        ewayBillNo: json['ewayBillNo'] ?? '',
        vehicleNo: json['vehicleNo'] ?? '',
      );
}

class PurchaseItem {
  final String description;
  final String hsn;
  final double quantity;
  final String unit;
  final double rate;
  final double gstRate;

  static const List<String> allowedUnits = ['PCS', 'MTR', 'KG', 'PKT', 'SET'];
  static const List<double> allowedGstRates = [5, 12, 18, 28];

  const PurchaseItem({
    this.description = '',
    this.hsn = '',
    this.quantity = 1,
    this.unit = 'PCS',
    this.rate = 0,
    this.gstRate = 18,
  });

  double get taxableValue => quantity * rate;
  double get cgstRate => gstRate / 2.0;
  double get sgstRate => gstRate / 2.0;
  double get cgstAmount => taxableValue * (cgstRate / 100.0);
  double get sgstAmount => taxableValue * (sgstRate / 100.0);
  double get totalGst => cgstAmount + sgstAmount;
  double get lineTotalWithGst => taxableValue + totalGst;

  PurchaseItem copyWith({
    String? description,
    String? hsn,
    double? quantity,
    String? unit,
    double? rate,
    double? gstRate,
  }) {
    return PurchaseItem(
      description: description ?? this.description,
      hsn: hsn ?? this.hsn,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      gstRate: gstRate ?? this.gstRate,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'hsn': hsn,
        'quantity': quantity,
        'unit': unit,
        'rate': rate,
        'gstRate': gstRate,
      };

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
        description: json['description'] ?? '',
        hsn: json['hsn'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unit: json['unit'] ?? 'PCS',
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
        gstRate: (json['gstRate'] as num?)?.toDouble() ?? 18,
      );
}

class PurchaseHsnRow {
  final String hsn;
  final double taxableValue;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double totalTax;

  const PurchaseHsnRow({
    required this.hsn,
    required this.taxableValue,
    required this.gstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.totalTax,
  });
}

class PurchaseBill {
  final String? id;
  final SupplierDetails supplier;
  final PurchaseMetadata metadata;
  final List<PurchaseItem> items;
  final double roundOff;
  final DateTime? updatedAt;
  final bool isSynced;

  const PurchaseBill({
    this.id,
    this.supplier = const SupplierDetails(),
    this.metadata = const PurchaseMetadata(),
    this.items = const [PurchaseItem()],
    this.roundOff = 0.0,
    this.updatedAt,
    this.isSynced = false,
  });

  String get displayName {
    if (supplier.name.trim().isNotEmpty) return supplier.name.trim();
    if (metadata.invoiceNo.trim().isNotEmpty) {
      return 'Purchase #${metadata.invoiceNo.trim()}';
    }
    return 'Untitled Purchase';
  }

  double get totalQuantity =>
      items.fold(0.0, (sum, item) => sum + item.quantity);

  double get totalTaxableValue =>
      items.fold(0.0, (sum, item) => sum + item.taxableValue);

  double get totalCgstInput =>
      items.fold(0.0, (sum, item) => sum + item.cgstAmount);

  double get totalSgstInput =>
      items.fold(0.0, (sum, item) => sum + item.sgstAmount);

  double get totalInputGst => totalCgstInput + totalSgstInput;

  double get rawGrandTotal => totalTaxableValue + totalInputGst;

  double get grandTotal => rawGrandTotal + roundOff;

  String get amountInWords =>
      NumberToWords.convert(grandTotal, prefix: 'INR');

  Map<String, PurchaseHsnRow> get hsnSummary {
    final Map<String, PurchaseHsnRow> map = {};
    for (final item in items) {
      final key = item.hsn.trim().isEmpty ? '—' : item.hsn.trim();
      final existing = map[key];
      final taxable = (existing?.taxableValue ?? 0.0) + item.taxableValue;
      final cgst = (existing?.cgstAmount ?? 0.0) + item.cgstAmount;
      final sgst = (existing?.sgstAmount ?? 0.0) + item.sgstAmount;
      map[key] = PurchaseHsnRow(
        hsn: key,
        taxableValue: taxable,
        gstRate: item.gstRate,
        cgstAmount: cgst,
        sgstAmount: sgst,
        totalTax: cgst + sgst,
      );
    }
    return map;
  }

  PurchaseBill copyWith({
    String? id,
    SupplierDetails? supplier,
    PurchaseMetadata? metadata,
    List<PurchaseItem>? items,
    double? roundOff,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return PurchaseBill(
      id: id ?? this.id,
      supplier: supplier ?? this.supplier,
      metadata: metadata ?? this.metadata,
      items: items ?? this.items,
      roundOff: roundOff ?? this.roundOff,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplier': supplier.toJson(),
        'metadata': metadata.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'roundOff': roundOff,
        'updatedAt': updatedAt?.toIso8601String(),
        'isSynced': isSynced,
      };

  factory PurchaseBill.fromJson(Map<String, dynamic> json) => PurchaseBill(
        id: json['id'],
        supplier: json['supplier'] != null
            ? SupplierDetails.fromJson(
                Map<String, dynamic>.from(json['supplier']))
            : const SupplierDetails(),
        metadata: json['metadata'] != null
            ? PurchaseMetadata.fromJson(
                Map<String, dynamic>.from(json['metadata']))
            : const PurchaseMetadata(),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) =>
                    PurchaseItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [PurchaseItem()],
        roundOff: (json['roundOff'] as num?)?.toDouble() ?? 0.0,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
        isSynced: json['isSynced'] ?? false,
      );

  String toJsonString() => json.encode(toJson());

  factory PurchaseBill.fromJsonString(String str) =>
      PurchaseBill.fromJson(json.decode(str) as Map<String, dynamic>);
}

