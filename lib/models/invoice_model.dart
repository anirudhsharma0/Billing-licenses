import 'dart:convert';

/// Tax mode options: CGST_SGST (Intra-state) or IGST (Inter-state)
enum TaxMode { cgstSgst, igst }

extension TaxModeExtension on TaxMode {
  String get value {
    switch (this) {
      case TaxMode.cgstSgst:
        return 'CGST_SGST';
      case TaxMode.igst:
        return 'IGST';
    }
  }

  static TaxMode fromString(String? val) {
    if (val == 'IGST') return TaxMode.igst;
    return TaxMode.cgstSgst;
  }
}

class SellerDetails {
  final String name;
  final String address;
  final String gstin;
  final String state;
  final String stateCode;
  final String email;
  final String phone;
  final String jurisdiction;
  final String declaration;
  final String logoUrl;
  final String signatureUrl;

  const SellerDetails({
    this.name = '',
    this.address = '',
    this.gstin = '',
    this.state = '',
    this.stateCode = '',
    this.email = '',
    this.phone = '',
    this.jurisdiction = '',
    this.declaration =
        'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
    this.logoUrl = 'assets/images/coop-logo.png',
    this.signatureUrl = '',
  });

  SellerDetails copyWith({
    String? name,
    String? address,
    String? gstin,
    String? state,
    String? stateCode,
    String? email,
    String? phone,
    String? jurisdiction,
    String? declaration,
    String? logoUrl,
    String? signatureUrl,
  }) {
    return SellerDetails(
      name: name ?? this.name,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      declaration: declaration ?? this.declaration,
      logoUrl: logoUrl ?? this.logoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'gstin': gstin,
        'state': state,
        'stateCode': stateCode,
        'email': email,
        'phone': phone,
        'jurisdiction': jurisdiction,
        'declaration': declaration,
        'logoUrl': logoUrl,
        'signatureUrl': signatureUrl,
      };

  factory SellerDetails.fromJson(Map<String, dynamic> json) => SellerDetails(
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        gstin: json['gstin'] ?? '',
        state: json['state'] ?? '',
        stateCode: json['stateCode'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        jurisdiction: json['jurisdiction'] ?? '',
        declaration: json['declaration'] ?? '',
        logoUrl: json['logoUrl'] ?? 'assets/images/coop-logo.png',
        signatureUrl: json['signatureUrl'] ?? '',
      );
}

class BuyerDetails {
  final String name;
  final String address;
  final String state;
  final String stateCode;
  final String gstin;

  const BuyerDetails({
    this.name = '',
    this.address = '',
    this.state = '',
    this.stateCode = '',
    this.gstin = '',
  });

  BuyerDetails copyWith({
    String? name,
    String? address,
    String? state,
    String? stateCode,
    String? gstin,
  }) {
    return BuyerDetails(
      name: name ?? this.name,
      address: address ?? this.address,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      gstin: gstin ?? this.gstin,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'state': state,
        'stateCode': stateCode,
        'gstin': gstin,
      };

  factory BuyerDetails.fromJson(Map<String, dynamic> json) => BuyerDetails(
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        state: json['state'] ?? '',
        stateCode: json['stateCode'] ?? '',
        gstin: json['gstin'] ?? '',
      );
}

class ConsigneeDetails {
  final String name;
  final String address;
  final String state;
  final String stateCode;
  final String gstin;

  const ConsigneeDetails({
    this.name = '',
    this.address = '',
    this.state = '',
    this.stateCode = '',
    this.gstin = '',
  });

  ConsigneeDetails copyWith({
    String? name,
    String? address,
    String? state,
    String? stateCode,
    String? gstin,
  }) {
    return ConsigneeDetails(
      name: name ?? this.name,
      address: address ?? this.address,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      gstin: gstin ?? this.gstin,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'state': state,
        'stateCode': stateCode,
        'gstin': gstin,
      };

  factory ConsigneeDetails.fromJson(Map<String, dynamic> json) =>
      ConsigneeDetails(
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        state: json['state'] ?? '',
        stateCode: json['stateCode'] ?? '',
        gstin: json['gstin'] ?? '',
      );
}

class InvoiceMetadata {
  final String invoiceNo;
  final String date;
  final String deliveryNote;
  final String deliveryNoteDate;
  final String referenceNo;
  final String otherReferences;
  final String destination;
  final String dispatchDocNo;
  final String dispatchedThrough;
  final String paymentTerms;
  final String termsOfDelivery;

  const InvoiceMetadata({
    this.invoiceNo = '',
    this.date = '',
    this.deliveryNote = '',
    this.deliveryNoteDate = '',
    this.referenceNo = '',
    this.otherReferences = '',
    this.destination = '',
    this.dispatchDocNo = '',
    this.dispatchedThrough = '',
    this.paymentTerms = '',
    this.termsOfDelivery = '',
  });

  InvoiceMetadata copyWith({
    String? invoiceNo,
    String? date,
    String? deliveryNote,
    String? deliveryNoteDate,
    String? referenceNo,
    String? otherReferences,
    String? destination,
    String? dispatchDocNo,
    String? dispatchedThrough,
    String? paymentTerms,
    String? termsOfDelivery,
  }) {
    return InvoiceMetadata(
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      deliveryNoteDate: deliveryNoteDate ?? this.deliveryNoteDate,
      referenceNo: referenceNo ?? this.referenceNo,
      otherReferences: otherReferences ?? this.otherReferences,
      destination: destination ?? this.destination,
      dispatchDocNo: dispatchDocNo ?? this.dispatchDocNo,
      dispatchedThrough: dispatchedThrough ?? this.dispatchedThrough,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      termsOfDelivery: termsOfDelivery ?? this.termsOfDelivery,
    );
  }

  Map<String, dynamic> toJson() => {
        'invoiceNo': invoiceNo,
        'date': date,
        'deliveryNote': deliveryNote,
        'deliveryNoteDate': deliveryNoteDate,
        'referenceNo': referenceNo,
        'otherReferences': otherReferences,
        'destination': destination,
        'dispatchDocNo': dispatchDocNo,
        'dispatchedThrough': dispatchedThrough,
        'paymentTerms': paymentTerms,
        'termsOfDelivery': termsOfDelivery,
      };

  factory InvoiceMetadata.fromJson(Map<String, dynamic> json) =>
      InvoiceMetadata(
        invoiceNo: json['invoiceNo'] ?? '',
        date: json['date'] ?? '',
        deliveryNote: json['deliveryNote'] ?? '',
        deliveryNoteDate: json['deliveryNoteDate'] ?? '',
        referenceNo: json['referenceNo'] ?? '',
        otherReferences: json['otherReferences'] ?? '',
        destination: json['destination'] ?? '',
        dispatchDocNo: json['dispatchDocNo'] ?? '',
        dispatchedThrough: json['dispatchedThrough'] ?? '',
        paymentTerms: json['paymentTerms'] ?? '',
        termsOfDelivery: json['termsOfDelivery'] ?? '',
      );
}

class InvoiceItem {
  final String description;
  final String subtext;
  final String hsn;
  final double quantity;
  final String unit;
  final double rate;
  final double taxRate;

  const InvoiceItem({
    this.description = '',
    this.subtext = '',
    this.hsn = '',
    this.quantity = 1,
    this.unit = 'set',
    this.rate = 0,
    this.taxRate = 18,
  });

  double get lineTotal => quantity * rate;

  InvoiceItem copyWith({
    String? description,
    String? subtext,
    String? hsn,
    double? quantity,
    String? unit,
    double? rate,
    double? taxRate,
  }) {
    return InvoiceItem(
      description: description ?? this.description,
      subtext: subtext ?? this.subtext,
      hsn: hsn ?? this.hsn,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'subtext': subtext,
        'hsn': hsn,
        'quantity': quantity,
        'unit': unit,
        'rate': rate,
        'taxRate': taxRate,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: json['description'] ?? '',
        subtext: json['subtext'] ?? '',
        hsn: json['hsn'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unit: json['unit'] ?? 'set',
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 18,
      );
}

class BankDetails {
  final String holderName;
  final String bankName;
  final String accountNo;
  final String ifsc;
  final String branch;
  final String swiftCode;

  const BankDetails({
    this.holderName = '',
    this.bankName = '',
    this.accountNo = '',
    this.ifsc = '',
    this.branch = '',
    this.swiftCode = '',
  });

  BankDetails copyWith({
    String? holderName,
    String? bankName,
    String? accountNo,
    String? ifsc,
    String? branch,
    String? swiftCode,
  }) {
    return BankDetails(
      holderName: holderName ?? this.holderName,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      ifsc: ifsc ?? this.ifsc,
      branch: branch ?? this.branch,
      swiftCode: swiftCode ?? this.swiftCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'holderName': holderName,
        'bankName': bankName,
        'accountNo': accountNo,
        'ifsc': ifsc,
        'branch': branch,
        'swiftCode': swiftCode,
      };

  factory BankDetails.fromJson(Map<String, dynamic> json) => BankDetails(
        holderName: json['holderName'] ?? '',
        bankName: json['bankName'] ?? '',
        accountNo: json['accountNo'] ?? '',
        ifsc: json['ifsc'] ?? '',
        branch: json['branch'] ?? '',
        swiftCode: json['swiftCode'] ?? '',
      );
}

class HsnSummaryRow {
  final String hsn;
  final double taxableValue;
  final double taxRate;
  final double cgstRate;
  final double sgstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;

  const HsnSummaryRow({
    required this.hsn,
    required this.taxableValue,
    required this.taxRate,
    required this.cgstRate,
    required this.sgstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
  });
}

class TaxBreakupItem {
  final String label;
  final String rateStr;
  final double amount;

  const TaxBreakupItem({
    required this.label,
    required this.rateStr,
    required this.amount,
  });
}

class Invoice {
  final String? id;
  final String savedName;
  final String invoiceTitle;
  final TaxMode taxMode;
  final double roundOff;
  final SellerDetails seller;
  final BuyerDetails buyer;
  final ConsigneeDetails consignee;
  final InvoiceMetadata metadata;
  final List<InvoiceItem> items;
  final BankDetails bankDetails;
  final DateTime? updatedAt;
  final bool isSynced;

  const Invoice({
    this.id,
    this.savedName = '',
    this.invoiceTitle = 'PROFORMA INVOICE',
    this.taxMode = TaxMode.cgstSgst,
    this.roundOff = 0.0,
    this.seller = const SellerDetails(),
    this.buyer = const BuyerDetails(),
    this.consignee = const ConsigneeDetails(),
    this.metadata = const InvoiceMetadata(),
    this.items = const [],
    this.bankDetails = const BankDetails(),
    this.updatedAt,
    this.isSynced = false,
  });

  String get displayName {
    if (savedName.trim().isNotEmpty) return savedName.trim();
    if (buyer.name.trim().isNotEmpty) return buyer.name.trim();
    if (metadata.invoiceNo.trim().isNotEmpty) return 'Bill #${metadata.invoiceNo.trim()}';
    return 'Untitled Bill';
  }

  double get totalQuantity {
    return items.fold(0.0, (sum, item) => sum + item.quantity);
  }

  double get totalTaxableValue {
    return items.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  Map<String, HsnSummaryRow> get hsnSummary {
    final Map<String, HsnSummaryRow> summary = {};

    for (final item in items) {
      final hsn = item.hsn.trim().isEmpty ? '—' : item.hsn.trim();
      final lineTaxable = item.lineTotal;
      final taxRate = item.taxRate;

      final existing = summary[hsn];
      final currentTaxable = (existing?.taxableValue ?? 0.0) + lineTaxable;

      if (taxMode == TaxMode.cgstSgst) {
        final halfRate = taxRate / 2.0;
        final cgst = lineTaxable * (halfRate / 100.0);
        final sgst = lineTaxable * (halfRate / 100.0);
        final curCgst = (existing?.cgstAmount ?? 0.0) + cgst;
        final curSgst = (existing?.sgstAmount ?? 0.0) + sgst;

        summary[hsn] = HsnSummaryRow(
          hsn: hsn,
          taxableValue: currentTaxable,
          taxRate: taxRate,
          cgstRate: halfRate,
          sgstRate: halfRate,
          cgstAmount: curCgst,
          sgstAmount: curSgst,
          igstAmount: 0.0,
          totalTax: curCgst + curSgst,
        );
      } else {
        final igst = lineTaxable * (taxRate / 100.0);
        final curIgst = (existing?.igstAmount ?? 0.0) + igst;

        summary[hsn] = HsnSummaryRow(
          hsn: hsn,
          taxableValue: currentTaxable,
          taxRate: taxRate,
          cgstRate: 0.0,
          sgstRate: 0.0,
          cgstAmount: 0.0,
          sgstAmount: 0.0,
          igstAmount: curIgst,
          totalTax: curIgst,
        );
      }
    }
    return summary;
  }

  List<TaxBreakupItem> get taxBreakupList {
    final List<TaxBreakupItem> list = [];
    for (final item in items) {
      final lineTaxable = item.lineTotal;
      final taxRate = item.taxRate;

      if (taxMode == TaxMode.cgstSgst) {
        final halfRate = taxRate / 2.0;
        final cgst = lineTaxable * (halfRate / 100.0);
        final sgst = lineTaxable * (halfRate / 100.0);

        final rateStr = halfRate.toStringAsFixed(halfRate.truncateToDouble() == halfRate ? 0 : 2);
        list.add(TaxBreakupItem(
          label: 'CGST OUTPUT@$rateStr%',
          rateStr: '$rateStr %',
          amount: cgst,
        ));
        list.add(TaxBreakupItem(
          label: 'SGST OUTPUT@$rateStr%',
          rateStr: '$rateStr %',
          amount: sgst,
        ));
      } else {
        final igst = lineTaxable * (taxRate / 100.0);
        final rateStr = taxRate.toStringAsFixed(taxRate.truncateToDouble() == taxRate ? 0 : 2);
        list.add(TaxBreakupItem(
          label: 'IGST OUTPUT@$rateStr%',
          rateStr: '$rateStr %',
          amount: igst,
        ));
      }
    }
    return list;
  }

  double get totalCgst =>
      hsnSummary.values.fold(0.0, (sum, row) => sum + row.cgstAmount);

  double get totalSgst =>
      hsnSummary.values.fold(0.0, (sum, row) => sum + row.sgstAmount);

  double get totalIgst =>
      hsnSummary.values.fold(0.0, (sum, row) => sum + row.igstAmount);

  double get totalTaxAmount =>
      hsnSummary.values.fold(0.0, (sum, row) => sum + row.totalTax);

  double get rawGrandTotal => totalTaxableValue + totalTaxAmount;

  double get grandTotal => (rawGrandTotal + roundOff).roundToDouble();

  Invoice copyWith({
    String? id,
    String? savedName,
    String? invoiceTitle,
    TaxMode? taxMode,
    double? roundOff,
    SellerDetails? seller,
    BuyerDetails? buyer,
    ConsigneeDetails? consignee,
    InvoiceMetadata? metadata,
    List<InvoiceItem>? items,
    BankDetails? bankDetails,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Invoice(
      id: id ?? this.id,
      savedName: savedName ?? this.savedName,
      invoiceTitle: invoiceTitle ?? this.invoiceTitle,
      taxMode: taxMode ?? this.taxMode,
      roundOff: roundOff ?? this.roundOff,
      seller: seller ?? this.seller,
      buyer: buyer ?? this.buyer,
      consignee: consignee ?? this.consignee,
      metadata: metadata ?? this.metadata,
      items: items ?? this.items,
      bankDetails: bankDetails ?? this.bankDetails,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedName': savedName,
        'invoiceTitle': invoiceTitle,
        'taxMode': taxMode.value,
        'roundOff': roundOff,
        'seller': seller.toJson(),
        'buyer': buyer.toJson(),
        'consignee': consignee.toJson(),
        'metadata': metadata.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'bankDetails': bankDetails.toJson(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isSynced': isSynced,
      };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'],
        savedName: json['savedName'] ?? '',
        invoiceTitle: json['invoiceTitle'] ?? 'PROFORMA INVOICE',
        taxMode: TaxModeExtension.fromString(json['taxMode']),
        roundOff: (json['roundOff'] as num?)?.toDouble() ?? 0.0,
        seller: json['seller'] != null
            ? SellerDetails.fromJson(json['seller'])
            : const SellerDetails(),
        buyer: json['buyer'] != null
            ? BuyerDetails.fromJson(json['buyer'])
            : const BuyerDetails(),
        consignee: json['consignee'] != null
            ? ConsigneeDetails.fromJson(json['consignee'])
            : const ConsigneeDetails(),
        metadata: json['metadata'] != null
            ? InvoiceMetadata.fromJson(json['metadata'])
            : const InvoiceMetadata(),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        bankDetails: json['bankDetails'] != null
            ? BankDetails.fromJson(json['bankDetails'])
            : const BankDetails(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
        isSynced: json['isSynced'] as bool? ?? false,
      );

  static Invoice fromJsonString(String source) =>
      Invoice.fromJson(json.decode(source) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());
}
