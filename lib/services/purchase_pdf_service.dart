import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import '../utils/number_to_words.dart';

class PurchasePdfService {
  /// Generate clean A4 Purchase Bill PDF with Items & HSN Input Tax Summary
  static Future<Uint8List> generatePdf(
    PurchaseBill purchase, {
    SellerDetails? buyerFirm,
  }) async {
    final pdf = pw.Document();

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

    final hsnRows = purchase.hsnSummary.values.toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        theme: theme,
        build: (pw.Context context) {
          return [
            // Title
            pw.Center(
              child: pw.Text(
                'PURCHASE BILL / INWARD TAX RECORD',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            pw.SizedBox(height: 6),

            // Outer Container: Supplier + Metadata
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left: Supplier Details
                      pw.Expanded(
                        flex: 6,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Supplier (From):',
                                style: pw.TextStyle(font: fontItalic, fontSize: 8),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                purchase.supplier.name.isNotEmpty
                                    ? purchase.supplier.name
                                    : '—',
                                style: pw.TextStyle(font: fontBold, fontSize: 10.5),
                              ),
                              if (purchase.supplier.address.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  purchase.supplier.address,
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                              ],
                              if (purchase.supplier.gstin.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'GSTIN/UIN : ${purchase.supplier.gstin}',
                                  style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                                ),
                              ],
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'State : ${purchase.supplier.state} (Code: ${purchase.supplier.stateCode})',
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right: Metadata
                      pw.Expanded(
                        flex: 4,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _metaLine('Purchase Inv No.', purchase.metadata.invoiceNo, fontBold),
                              _metaLine('Invoice Date', purchase.metadata.date, fontBold),
                              if (purchase.metadata.referenceNo.isNotEmpty)
                                _metaLine('Reference No.', purchase.metadata.referenceNo, fontBold),
                              if (purchase.metadata.ewayBillNo.isNotEmpty)
                                _metaLine('e-Way Bill No.', purchase.metadata.ewayBillNo, fontBold),
                              if (purchase.metadata.vehicleNo.isNotEmpty)
                                _metaLine('Vehicle No.', purchase.metadata.vehicleNo, fontBold),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (buyerFirm != null && buyerFirm.name.isNotEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.Text(
                        'Purchased By : ${buyerFirm.name}${buyerFirm.gstin.isNotEmpty ? ' (GSTIN: ${buyerFirm.gstin})' : ''}',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                      ),
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // Items Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FixedColumnWidth(24),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FixedColumnWidth(48),
                3: const pw.FixedColumnWidth(46),
                4: const pw.FixedColumnWidth(54),
                5: const pw.FixedColumnWidth(34),
                6: const pw.FixedColumnWidth(60),
                7: const pw.FixedColumnWidth(62),
              },
              headers: [
                'Sl',
                'Description of Goods',
                'HSN/SAC',
                'Qty',
                'Rate',
                'GST%',
                'Taxable',
                'Total',
              ],
              data: List.generate(purchase.items.length, (i) {
                final item = purchase.items[i];
                return [
                  '${i + 1}',
                  item.description.isNotEmpty ? item.description : '—',
                  item.hsn.isNotEmpty ? item.hsn : '—',
                  '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
                  NumberToWords.formatCurrency(item.rate),
                  '${item.gstRate.toStringAsFixed(0)}%',
                  NumberToWords.formatCurrency(item.taxableValue),
                  NumberToWords.formatCurrency(item.lineTotalWithGst),
                ];
              }),
            ),

            pw.SizedBox(height: 8),

            // Totals Box
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Amount Chargeable (in words):',
                          style: pw.TextStyle(font: fontItalic, fontSize: 8),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          purchase.amountInWords,
                          style: pw.TextStyle(font: fontBold, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      children: [
                        _totalLine('Taxable Value', NumberToWords.formatCurrency(purchase.totalTaxableValue), fontRegular),
                        _totalLine('CGST Input', NumberToWords.formatCurrency(purchase.totalCgstInput), fontRegular),
                        _totalLine('SGST Input', NumberToWords.formatCurrency(purchase.totalSgstInput), fontRegular),
                        if (purchase.roundOff != 0)
                          _totalLine('Round Off', purchase.roundOff.toStringAsFixed(2), fontRegular),
                        pw.Divider(thickness: 0.6),
                        _totalLine('Grand Total', 'Rs. ${NumberToWords.formatCurrency(purchase.grandTotal)}', fontBold, fontSize: 9.5),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // HSN Tax Summary Table
            pw.Text(
              'HSN/SAC Input Tax Summary',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5),
            ),
            pw.SizedBox(height: 3),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 7.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headers: [
                'HSN/SAC',
                'Taxable Value',
                'CGST Rate',
                'CGST Amt',
                'SGST Rate',
                'SGST Amt',
                'Total Tax',
              ],
              data: hsnRows.map((row) {
                final half = (row.gstRate / 2).toStringAsFixed(1);
                return [
                  row.hsn,
                  NumberToWords.formatCurrency(row.taxableValue),
                  '$half%',
                  NumberToWords.formatCurrency(row.cgstAmount),
                  '$half%',
                  NumberToWords.formatCurrency(row.sgstAmount),
                  NumberToWords.formatCurrency(row.totalTax),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _metaLine(String label, String value, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 8)),
          pw.Expanded(
            child: pw.Text(
              value.isNotEmpty ? value : '—',
              style: pw.TextStyle(font: boldFont, fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalLine(
    String label,
    String value,
    pw.Font font, {
    double fontSize = 8.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: fontSize)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: fontSize)),
        ],
      ),
    );
  }

  static Future<void> printOrSave(
    PurchaseBill purchase, {
    SellerDetails? buyerFirm,
  }) async {
    final bytes = await generatePdf(purchase, buyerFirm: buyerFirm);
    final safeName = purchase.supplier.name.trim().isNotEmpty
        ? purchase.supplier.name
            .trim()
            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'Purchase';
    final inv = purchase.metadata.invoiceNo.trim().isNotEmpty
        ? purchase.metadata.invoiceNo.trim()
        : 'Bill';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Purchase_${inv}_$safeName.pdf',
      format: PdfPageFormat.a4,
    );
  }
}

