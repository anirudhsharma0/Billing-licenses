import 'package:intl/intl.dart';

/// Converts numeric amounts into Indian Currency words and formats INR currency
class NumberToWords {
  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  static String _twoDigits(int n) {
    if (n == 0) return '';
    if (n < 20) return _units[n];
    final t = n ~/ 10;
    final u = n % 10;
    return ('${_tens[t]} ${u > 0 ? _units[u] : ''}').trim();
  }

  static String _threeDigits(int n) {
    final h = n ~/ 100;
    final rem = n % 100;
    String str = '';
    if (h > 0) {
      str += '${_units[h]} Hundred';
    }
    if (rem > 0) {
      str += '${str.isNotEmpty ? " and " : ""}${_twoDigits(rem)}';
    }
    return str.trim();
  }

  static String _convertIntegerToIndianWords(int num) {
    if (num == 0) return 'Zero';

    int n = num;
    final crore = n ~/ 10000000;
    n %= 10000000;

    final lakh = n ~/ 100000;
    n %= 100000;

    final thousand = n ~/ 1000;
    n %= 1000;

    final remainder = n;

    final List<String> parts = [];

    if (crore > 0) {
      parts.add('${_convertIntegerToIndianWords(crore)} Crore');
    }
    if (lakh > 0) {
      parts.add('${_twoDigits(lakh)} Lakh');
    }
    if (thousand > 0) {
      parts.add('${_twoDigits(thousand)} Thousand');
    }
    if (remainder > 0) {
      parts.add(_threeDigits(remainder));
    }

    return parts.join(' ');
  }

  /// Convert amount to Indian words e.g. "Three Lakh Twenty Thousand Rupees Only"
  static String convert(double amount, {String prefix = ''}) {
    final pfx = prefix.trim().isNotEmpty ? '${prefix.trim()} ' : '';
    if (amount.isNaN || amount == 0) return '${pfx}Zero Only'.trim();

    final absolute = amount.abs();
    final rupees = absolute.floor();
    final paise = ((absolute - rupees) * 100).round();

    String result = rupees > 0 ? _convertIntegerToIndianWords(rupees) : '';

    String words = pfx;
    if (result.isNotEmpty) {
      words += result;
    }

    if (paise > 0) {
      final paiseWords = _twoDigits(paise);
      if (result.isNotEmpty) {
        words += ' and Paise $paiseWords';
      } else {
        words += 'Paise $paiseWords';
      }
    }

    words += ' Only';
    return words.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Format as Indian Currency: 3,20,000.00
  static String formatCurrency(double amount) {
    if (amount.isNaN) return '0.00';
    try {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '',
        decimalDigits: 2,
      );
      return formatter.format(amount).trim();
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }

  /// Format with rupee symbol: ₹ 3,20,000.00
  static String formatWithSymbol(double amount) {
    return '₹ ${formatCurrency(amount)}';
  }
}
