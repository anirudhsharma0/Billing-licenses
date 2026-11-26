import 'dart:convert';
import '../utils/number_to_words.dart';
import 'invoice_model.dart';

/// Payment mode options for Receipt Voucher
enum PaymentMode { cash, upi, bankTransfer, cheque }

extension PaymentModeExtension on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.cheque:
        return 'Cheque';
    }
  }

  String get value {
    switch (this) {
      case PaymentMode.cash:
        return 'CASH';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.bankTransfer:
        return 'BANK_TRANSFER';
      case PaymentMode.cheque:
        return 'CHEQUE';
    }
  }

  static PaymentMode fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'UPI':
        return PaymentMode.upi;
      case 'BANK_TRANSFER':
      case 'BANK TRANSFER':
        return PaymentMode.bankTransfer;
      case 'CHEQUE':
        return PaymentMode.cheque;
      case 'CASH':
      default:
        return PaymentMode.cash;
    }
  }
}

/// Supported printable PDF page sizes for Receipt Voucher
enum ReceiptPageSize { a4, a5 }

extension ReceiptPageSizeExtension on ReceiptPageSize {
  String get label => this == ReceiptPageSize.a5 ? 'A5' : 'A4';
}

class ReceiptVoucher {
  final String? id;
  final String receiptNo;
  final String date; // Formatted as DD-MMM-YY e.g. 26-Nov-26
  final String customerName;
  final double amount;
  final PaymentMode paymentMode;
  final String referenceNo;
  final String remarks;
  final String? linkedInvoiceId;
  final String? linkedInvoiceNo;
  final SellerDetails seller;
  final DateTime? updatedAt;
  final bool isSynced;

  const ReceiptVoucher({
    this.id,
    this.receiptNo = '1',
    this.date = '',
    this.customerName = '',
    this.amount = 0.0,
    this.paymentMode = PaymentMode.cash,
    this.referenceNo = '',
    this.remarks = '',
    this.linkedInvoiceId,
    this.linkedInvoiceNo,
    this.seller = const SellerDetails(),
    this.updatedAt,
    this.isSynced = false,
  });

  String get amountInWords => NumberToWords.convert(amount, prefix: 'INR');

  String get formattedAmount => NumberToWords.formatCurrency(amount);

  String get throughText {
    final base = paymentMode.label;
    if (referenceNo.trim().isNotEmpty) {
      return '$base (Ref: ${referenceNo.trim()})';
    }
    return base;
  }

  String get displayName {
    if (customerName.trim().isNotEmpty) return customerName.trim();
    if (receiptNo.trim().isNotEmpty) return 'Receipt #$receiptNo';
    return 'Untitled Receipt';
  }

  ReceiptVoucher copyWith({
    String? id,
    String? receiptNo,
    String? date,
    String? customerName,
    double? amount,
    PaymentMode? paymentMode,
    String? referenceNo,
    String? remarks,
    String? linkedInvoiceId,
    String? linkedInvoiceNo,
    SellerDetails? seller,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ReceiptVoucher(
      id: id ?? this.id,
      receiptNo: receiptNo ?? this.receiptNo,
      date: date ?? this.date,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNo: referenceNo ?? this.referenceNo,
      remarks: remarks ?? this.remarks,
      linkedInvoiceId: linkedInvoiceId ?? this.linkedInvoiceId,
      linkedInvoiceNo: linkedInvoiceNo ?? this.linkedInvoiceNo,
      seller: seller ?? this.seller,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNo': receiptNo,
        'date': date,
        'customerName': customerName,
        'amount': amount,
        'paymentMode': paymentMode.value,
        'referenceNo': referenceNo,
        'remarks': remarks,
        'linkedInvoiceId': linkedInvoiceId,
        'linkedInvoiceNo': linkedInvoiceNo,
        'seller': seller.toJson(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isSynced': isSynced,
      };

  factory ReceiptVoucher.fromJson(Map<String, dynamic> json) {
    return ReceiptVoucher(
      id: json['id'],
      receiptNo: json['receiptNo'] ?? '',
      date: json['date'] ?? '',
      customerName: json['customerName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: PaymentModeExtension.fromString(json['paymentMode']),
      referenceNo: json['referenceNo'] ?? '',
      remarks: json['remarks'] ?? '',
      linkedInvoiceId: json['linkedInvoiceId'],
      linkedInvoiceNo: json['linkedInvoiceNo'],
      seller: json['seller'] != null
          ? SellerDetails.fromJson(Map<String, dynamic>.from(json['seller']))
          : const SellerDetails(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isSynced: json['isSynced'] ?? false,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory ReceiptVoucher.fromJsonString(String str) =>
      ReceiptVoucher.fromJson(json.decode(str) as Map<String, dynamic>);
}

