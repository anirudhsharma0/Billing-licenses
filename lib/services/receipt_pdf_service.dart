import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/receipt_model.dart';

class ReceiptPdfService {
  /// Generate Tally-standard Receipt Voucher PDF in A4 or A5
  static Future<Uint8List> generatePdf(
    ReceiptVoucher receipt, {
    ReceiptPageSize pageSize = ReceiptPageSize.a4,
  }) async {
    final pdf = pw.Document();
    final isA5 = pageSize == ReceiptPageSize.a5;

    // Load company logo
    pw.MemoryImage? logoImage;
    try {
      final logoPath = receipt.seller.logoUrl.isNotEmpty
          ? receipt.seller.logoUrl
          : 'assets/images/coop-logo.png';
      final logoBytes = await rootBundle.load(logoPath);
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // Optional signature/stamp image if configured as local file or asset
    pw.MemoryImage? signatureImage;
    if (receipt.seller.signatureUrl.trim().isNotEmpty) {
      try {
        final sigPath = receipt.seller.signatureUrl.trim();
        if (sigPath.startsWith('assets/')) {
          final sigBytes = await rootBundle.load(sigPath);
          signatureImage = pw.MemoryImage(sigBytes.buffer.asUint8List());
        } else if (!kIsWeb && File(sigPath).existsSync()) {
          signatureImage = pw.MemoryImage(File(sigPath).readAsBytesSync());
        }
      } catch (_) {
        signatureImage = null;
      }
    }

    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontItalic;
    try {
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
      fontItalic = await PdfGoogleFonts.robotoItalic();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      fontItalic = pw.Font.helveticaOblique();
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    final sellerName = receipt.seller.name.trim().isNotEmpty
        ? receipt.seller.name.trim()
        : 'The Kishan Bharti Coop. M.P. Society Ltd.';
    final sellerAddress = receipt.seller.address.trim();
    final stateInfo = [
      if (receipt.seller.state.trim().isNotEmpty)
        'State Name : ${receipt.seller.state.trim()}',
      if (receipt.seller.stateCode.trim().isNotEmpty)
        'Code : ${receipt.seller.stateCode.trim()}',
    ].join(', ');
    final contactParts = [
      if (receipt.seller.phone.trim().isNotEmpty)
        'Contact : ${receipt.seller.phone.trim()}',
      if (receipt.seller.email.trim().isNotEmpty)
        'E-Mail : ${receipt.seller.email.trim()}',
    ];

    final double baseFont = isA5 ? 8.5 : 10.0;
    final double titleFont = isA5 ? 12.0 : 14.0;
    final double companyFont = isA5 ? 11.5 : 14.0;
    final double logoSize = isA5 ? 44.0 : 58.0;

    pdf.addPage(
      pw.Page(
        pageFormat: isA5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(isA5 ? 20 : 28),
        theme: theme,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.0),
            ),
            padding: pw.EdgeInsets.all(isA5 ? 12 : 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // 1. TOP HEADER: Company Logo (Left) + Company Details
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: logoSize,
                        height: logoSize,
                        margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            sellerName,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: companyFont,
                            ),
                          ),
                          if (sellerAddress.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              sellerAddress,
                              style: pw.TextStyle(fontSize: baseFont),
                            ),
                          ],
                          if (stateInfo.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              stateInfo,
                              style: pw.TextStyle(fontSize: baseFont),
                            ),
                          ],
                          if (contactParts.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              contactParts.join('  |  '),
                              style: pw.TextStyle(fontSize: baseFont),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: isA5 ? 8 : 12),
                pw.Divider(color: PdfColors.black, thickness: 0.8),
                pw.SizedBox(height: isA5 ? 6 : 8),

                // 2. TITLE: Center bold "Receipt Voucher"
                pw.Center(
                  child: pw.Text(
                    'Receipt Voucher',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: titleFont,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),

                pw.SizedBox(height: isA5 ? 10 : 14),

                // 3. META ROW: Left "No.: [Receipt No]" | Right "Dated: [DD-MMM-YY]"
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: 'No. : ',
                            style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                          ),
                          pw.TextSpan(
                            text: receipt.receiptNo,
                            style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                          ),
                        ],
                      ),
                    ),
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: 'Dated : ',
                            style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                          ),
                          pw.TextSpan(
                            text: receipt.date,
                            style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: isA5 ? 8 : 10),

                // 4. MAIN PARTICULARS BOX (Bordered Table)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.9),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(7),
                    1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    // Table Header: Particulars (Left) | Amount (Right)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: pw.Text(
                            'Particulars',
                            style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              'Amount',
                              style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Body Row: Account, Through, Amount (in words) | Amount
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Row 1: Account:
                              pw.Text(
                                'Account :',
                                style: pw.TextStyle(font: fontItalic, fontSize: baseFont - 0.5),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 16),
                                child: pw.Text(
                                  receipt.customerName.trim().isNotEmpty
                                      ? receipt.customerName.trim().toUpperCase()
                                      : '—',
                                  style: pw.TextStyle(font: fontBold, fontSize: baseFont + 0.5),
                                ),
                              ),
                              pw.SizedBox(height: isA5 ? 10 : 14),

                              // Row 2: Through:
                              pw.Text(
                                'Through :',
                                style: pw.TextStyle(font: fontItalic, fontSize: baseFont - 0.5),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 16),
                                child: pw.Text(
                                  receipt.throughText,
                                  style: pw.TextStyle(fontSize: baseFont),
                                ),
                              ),
                              if (receipt.remarks.trim().isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 16),
                                  child: pw.Text(
                                    'On Account of : ${receipt.remarks.trim()}',
                                    style: pw.TextStyle(font: fontItalic, fontSize: baseFont - 1),
                                  ),
                                ),
                              ],
                              pw.SizedBox(height: isA5 ? 10 : 14),

                              // Row 3: Amount (in words):
                              pw.Text(
                                'Amount (in words) :',
                                style: pw.TextStyle(font: fontItalic, fontSize: baseFont - 0.5),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 16),
                                child: pw.Text(
                                  receipt.amountInWords,
                                  style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                                ),
                              ),
                              pw.SizedBox(height: isA5 ? 14 : 20),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.fromLTRB(8, 22, 8, 10),
                          child: pw.Align(
                            alignment: pw.Alignment.topRight,
                            child: pw.Text(
                              receipt.formattedAmount,
                              style: pw.TextStyle(font: fontBold, fontSize: baseFont + 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Total Row with Double Underline on Right Column
                    pw.TableRow(
                      children: [
                        pw.SizedBox(height: 28),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                receipt.formattedAmount,
                                style: pw.TextStyle(font: fontBold, fontSize: baseFont + 0.5),
                              ),
                              pw.SizedBox(height: 1.5),
                              pw.Container(
                                width: 72,
                                height: 0.8,
                                color: PdfColors.black,
                              ),
                              pw.SizedBox(height: 1.5),
                              pw.Container(
                                width: 72,
                                height: 0.8,
                                color: PdfColors.black,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: isA5 ? 24 : 34),

                // 5. FOOTER: Bottom Right Stamp/Signature + "Authorised Signatory"
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (signatureImage != null)
                          pw.Container(
                            height: isA5 ? 32 : 42,
                            margin: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                          )
                        else
                          pw.SizedBox(height: isA5 ? 24 : 32),
                        pw.Text(
                          'Authorised Signatory',
                          style: pw.TextStyle(font: fontBold, fontSize: baseFont),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Open native Print / Save PDF dialog
  static Future<void> printOrSave(
    ReceiptVoucher receipt, {
    ReceiptPageSize pageSize = ReceiptPageSize.a4,
  }) async {
    final bytes = await generatePdf(receipt, pageSize: pageSize);
    final safeName = receipt.customerName.trim().isNotEmpty
        ? receipt.customerName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'Receipt';
    final fileName = 'Receipt_${receipt.receiptNo}_$safeName.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: fileName,
      format: pageSize == ReceiptPageSize.a5
          ? PdfPageFormat.a5
          : PdfPageFormat.a4,
    );
  }

  /// Share PDF via WhatsApp / System Share Sheet
  static Future<void> sharePdf(
    ReceiptVoucher receipt, {
    ReceiptPageSize pageSize = ReceiptPageSize.a4,
  }) async {
    final bytes = await generatePdf(receipt, pageSize: pageSize);
    final safeName = receipt.customerName.trim().isNotEmpty
        ? receipt.customerName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'Receipt';
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Receipt_${receipt.receiptNo}_$safeName.pdf',
    );
  }
}

