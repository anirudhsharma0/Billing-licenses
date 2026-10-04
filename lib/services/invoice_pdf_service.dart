import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../utils/number_to_words.dart';

class InvoicePdfService {
  /// Generate A4 PDF Document bytes matching Indian Tally standard invoice
  static Future<Uint8List> generatePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Load cooperative logo from asset
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/coop-logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // Try Google Fonts NotoSans/Roboto with safe fallback
    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font? fontItalic;

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

    final amountInWords = NumberToWords.convert(invoice.grandTotal, prefix: '');
    final taxInWords = NumberToWords.convert(invoice.totalTaxAmount, prefix: 'INR');

    // Indian Rupee prefix (falls back gracefully)
    const rupeePrefix = 'Rs. ';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. TOP DOCUMENT TITLE (Above Box)
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Center(
                  child: pw.Text(
                    invoice.invoiceTitle.toUpperCase(),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10.5,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              // 2. MAIN OUTER BOX
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // A. Seller Header with Logo
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              width: 68,
                              height: 52,
                              margin: const pw.EdgeInsets.only(right: 8),
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  invoice.seller.name.isNotEmpty
                                      ? invoice.seller.name
                                      : 'The Kishan Bharti Coop. M.P. Society Ltd.',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 13,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 1.5),
                                pw.Text(
                                  invoice.seller.address,
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8.5,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  'GSTIN/UIN: ${invoice.seller.gstin}',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8.5,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  'State Name : ${invoice.seller.state}, Code : ${invoice.seller.stateCode}',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                if (invoice.seller.email.isNotEmpty)
                                  pw.Text(
                                    'E-Mail : ${invoice.seller.email}',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 8,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // B. Buyer, Consignee & Dispatch Grid
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Left Column: Buyer & Invoice Info
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                children: [
                                  // Buyer details
                                  pw.Container(
                                    padding: const pw.EdgeInsets.all(4.5),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text('Buyer (Bill to)',
                                            style: const pw.TextStyle(
                                                fontSize: 7.5, color: PdfColors.black)),
                                        pw.SizedBox(height: 1),
                                        pw.Text(invoice.buyer.name,
                                            style: pw.TextStyle(
                                                font: fontBold, fontSize: 8.5)),
                                        pw.SizedBox(height: 1),
                                        pw.Text(invoice.buyer.address,
                                            style: const pw.TextStyle(fontSize: 7.5)),
                                        pw.SizedBox(height: 1),
                                        pw.Text(
                                            'State Name : ${invoice.buyer.state}, Code : ${invoice.buyer.stateCode}',
                                            style: const pw.TextStyle(fontSize: 7.5)),
                                        if (invoice.buyer.gstin.isNotEmpty)
                                          pw.Text('GSTIN/UIN: ${invoice.buyer.gstin}',
                                              style: pw.TextStyle(
                                                  font: fontBold, fontSize: 7.5)),
                                      ],
                                    ),
                                  ),
                                  // Invoice Metadata Sub-grid
                                  pw.Container(
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                        top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                      ),
                                    ),
                                    child: pw.Row(
                                      children: [
                                        pw.Expanded(
                                          child: pw.Container(
                                            decoration: const pw.BoxDecoration(
                                              border: pw.Border(
                                                right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                              ),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                              children: [
                                                _metaBox('Invoice No.', invoice.metadata.invoiceNo, fontBold, isBold: true),
                                                _metaBox('Delivery Note', invoice.metadata.deliveryNote, fontBold),
                                                _metaBox('Reference No. & Date.', invoice.metadata.referenceNo, fontBold, isLast: true),
                                              ],
                                            ),
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                            children: [
                                              _metaBox('Dated', invoice.metadata.date, fontBold, isBold: true),
                                              _metaBox('Delivery Note Date', invoice.metadata.deliveryNoteDate, fontBold),
                                              _metaBox('Other References', invoice.metadata.otherReferences, fontBold, isLast: true),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Right Column: Consignee & Dispatch Info
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                // Consignee details
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(4.5),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('Consignee (Ship to)',
                                          style: const pw.TextStyle(
                                              fontSize: 7.5, color: PdfColors.black)),
                                      pw.SizedBox(height: 1),
                                      pw.Text(
                                        invoice.consignee.name.isNotEmpty
                                            ? invoice.consignee.name
                                            : invoice.buyer.name,
                                        style: pw.TextStyle(
                                            font: fontBold, fontSize: 8.5),
                                      ),
                                      pw.SizedBox(height: 1),
                                      pw.Text(
                                        invoice.consignee.address.isNotEmpty
                                            ? invoice.consignee.address
                                            : invoice.buyer.address,
                                        style: const pw.TextStyle(fontSize: 7.5),
                                      ),
                                      pw.SizedBox(height: 1),
                                      pw.Text(
                                        'State Name : ${invoice.consignee.state.isNotEmpty ? invoice.consignee.state : invoice.buyer.state}, Code : ${invoice.consignee.stateCode.isNotEmpty ? invoice.consignee.stateCode : invoice.buyer.stateCode}',
                                        style: const pw.TextStyle(fontSize: 7.5),
                                      ),
                                      if (invoice.consignee.gstin.isNotEmpty || invoice.buyer.gstin.isNotEmpty)
                                        pw.Text(
                                          'GSTIN/UIN: ${invoice.consignee.gstin.isNotEmpty ? invoice.consignee.gstin : invoice.buyer.gstin}',
                                          style: pw.TextStyle(
                                              font: fontBold, fontSize: 7.5),
                                        ),
                                    ],
                                  ),
                                ),
                                // Dispatch Sub-grid matching exact PDF layout
                                pw.Container(
                                  decoration: const pw.BoxDecoration(
                                    border: pw.Border(
                                      top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                    ),
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                    children: [
                                      // Row 1: Destination | Dispatch Doc No.
                                      pw.Row(
                                        children: [
                                          pw.Expanded(
                                            child: pw.Container(
                                              decoration: const pw.BoxDecoration(
                                                border: pw.Border(
                                                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                                ),
                                              ),
                                              child: _metaBox('Destination', invoice.metadata.destination, fontBold, isLast: true),
                                            ),
                                          ),
                                          pw.Expanded(
                                            child: pw.Container(
                                              decoration: const pw.BoxDecoration(
                                                border: pw.Border(
                                                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                                ),
                                              ),
                                              child: _metaBox('Dispatch Doc No.', invoice.metadata.dispatchDocNo, fontBold, isLast: true),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Row 2: (blank left) | Dispatched through
                                      pw.Row(
                                        children: [
                                          pw.Expanded(
                                            child: pw.Container(
                                              decoration: const pw.BoxDecoration(
                                                border: pw.Border(
                                                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                                ),
                                              ),
                                              child: _metaBox('', '', fontBold, isLast: true),
                                            ),
                                          ),
                                          pw.Expanded(
                                            child: pw.Container(
                                              decoration: const pw.BoxDecoration(
                                                border: pw.Border(
                                                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                                                ),
                                              ),
                                              child: _metaBox('Dispatched through', invoice.metadata.dispatchedThrough, fontBold, isLast: true),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Row 3: Mode/Terms of Payment (Full Width)
                                      _metaBox('Mode/Terms of Payment', invoice.metadata.paymentTerms, fontBold),
                                      // Row 4: Terms of Delivery (Full Width)
                                      _metaBox('Terms of Delivery', invoice.metadata.termsOfDelivery, fontBold, isLast: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // C. Items Table with Sl, Description, HSN, Qty, Rate, per, Amount
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.Table(
                        border: const pw.TableBorder(
                          horizontalInside: pw.BorderSide.none,
                          verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                        columnWidths: const {
                          0: pw.FixedColumnWidth(22),  // Sl No
                          1: pw.FlexColumnWidth(3.8), // Description of Goods and Services
                          2: pw.FixedColumnWidth(48),  // HSN/SAC
                          3: pw.FixedColumnWidth(46),  // Quantity
                          4: pw.FixedColumnWidth(56),  // Rate
                          5: pw.FixedColumnWidth(26),  // per
                          6: pw.FixedColumnWidth(68),  // Amount
                        },
                        children: [
                          // Table Header
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                              ),
                            ),
                            children: [
                              _tableHeader('Sl\nNo.', fontBold, align: pw.TextAlign.center),
                              _tableHeader('Description of\nGoods and Services', fontBold, align: pw.TextAlign.center),
                              _tableHeader('HSN/SAC', fontBold, align: pw.TextAlign.center),
                              _tableHeader('Quantity', fontBold, align: pw.TextAlign.center),
                              _tableHeader('Rate', fontBold, align: pw.TextAlign.center),
                              _tableHeader('per', fontBold, align: pw.TextAlign.center),
                              _tableHeader('Amount', fontBold, align: pw.TextAlign.center),
                            ],
                          ),

                          // Table Item Rows
                          ...invoice.items.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final item = entry.value;
                            return pw.TableRow(
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                  alignment: pw.Alignment.topCenter,
                                  child: pw.Text('$idx', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(item.description,
                                          style: pw.TextStyle(font: fontBold, fontSize: 8.5)),
                                      if (item.subtext.isNotEmpty)
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.only(top: 1.5, left: 3),
                                          child: pw.Text(
                                            item.subtext,
                                            style: pw.TextStyle(
                                              font: fontItalic,
                                              fontSize: 7,
                                              color: PdfColors.black,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                  alignment: pw.Alignment.topCenter,
                                  child: pw.Text(item.hsn.isNotEmpty ? item.hsn : '—',
                                      style: const pw.TextStyle(fontSize: 8)),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  alignment: pw.Alignment.topRight,
                                  child: pw.Text(
                                    '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
                                    style: pw.TextStyle(font: fontBold, fontSize: 8),
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  alignment: pw.Alignment.topRight,
                                  child: pw.Text(NumberToWords.formatCurrency(item.rate),
                                      style: const pw.TextStyle(fontSize: 8)),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                  alignment: pw.Alignment.topCenter,
                                  child: pw.Text(item.unit,
                                      style: const pw.TextStyle(fontSize: 8)),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  alignment: pw.Alignment.topRight,
                                  child: pw.Text(NumberToWords.formatCurrency(item.lineTotal),
                                      style: pw.TextStyle(font: fontBold, fontSize: 8.5)),
                                ),
                              ],
                            );
                          }),

                          // Taxable Subtotal separator line
                          pw.TableRow(
                            children: [
                              pw.SizedBox(height: 8),
                              pw.SizedBox(height: 8),
                              pw.SizedBox(height: 8),
                              pw.SizedBox(height: 8),
                              pw.SizedBox(height: 8),
                              pw.SizedBox(height: 8),
                              pw.Container(
                                alignment: pw.Alignment.centerRight,
                                padding: const pw.EdgeInsets.only(top: 1.5, right: 3),
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 0.5)),
                                ),
                                child: pw.Text(
                                  NumberToWords.formatCurrency(invoice.totalTaxableValue),
                                  style: pw.TextStyle(font: fontBold, fontSize: 8),
                                ),
                              ),
                            ],
                          ),

                          // Tax Output Rows inside Item Table (Tally Style)
                          ...invoice.taxBreakupList.map((tax) {
                            return pw.TableRow(
                              children: [
                                pw.Container(),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    tax.label,
                                    style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                                  ),
                                ),
                                pw.Container(),
                                pw.Container(),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(tax.rateStr, style: const pw.TextStyle(fontSize: 7.5)),
                                ),
                                pw.Container(),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(NumberToWords.formatCurrency(tax.amount),
                                      style: pw.TextStyle(font: fontBold, fontSize: 8)),
                                ),
                              ],
                            );
                          }),

                          // Total Row
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                              ),
                            ),
                            children: [
                              pw.Container(),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 8.5)),
                              ),
                              pw.Container(),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 3),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  '${invoice.totalQuantity.toStringAsFixed(invoice.totalQuantity.truncateToDouble() == invoice.totalQuantity ? 0 : 2)} ${invoice.items.isNotEmpty ? invoice.items[0].unit : "set"}',
                                  style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                                ),
                              ),
                              pw.Container(),
                              pw.Container(),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 3),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  '$rupeePrefix${NumberToWords.formatCurrency(invoice.grandTotal)}',
                                  style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // D. Amount Chargeable (in words)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  const pw.TextSpan(
                                    text: 'Amount Chargeable (in words) ',
                                    style: pw.TextStyle(fontSize: 7.5),
                                  ),
                                  pw.TextSpan(
                                    text: 'INR ${amountInWords.toUpperCase()}',
                                    style: pw.TextStyle(font: fontBold, fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Text('E. & O.E',
                              style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                        ],
                      ),
                    ),

                    // E. HSN/SAC Summary Table
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.Table(
                        border: const pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                          verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                        children: [
                          // HSN Header
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                              ),
                            ),
                            children: [
                              _hsnHeader('HSN/SAC', fontBold, align: pw.TextAlign.center),
                              _hsnHeader('Taxable\nValue', fontBold, align: pw.TextAlign.center),
                              if (invoice.taxMode == TaxMode.cgstSgst) ...[
                                _hsnHeader('CGST\nRate', fontBold, align: pw.TextAlign.center),
                                _hsnHeader('CGST\nAmount', fontBold, align: pw.TextAlign.center),
                                _hsnHeader('SGST/UTGST\nRate', fontBold, align: pw.TextAlign.center),
                                _hsnHeader('SGST/UTGST\nAmount', fontBold, align: pw.TextAlign.center),
                              ] else ...[
                                _hsnHeader('IGST\nRate', fontBold, align: pw.TextAlign.center),
                                _hsnHeader('IGST\nAmount', fontBold, align: pw.TextAlign.center),
                              ],
                              _hsnHeader('Total\nTax Amount', fontBold, align: pw.TextAlign.center),
                            ],
                          ),
                          // HSN Rows
                          ...invoice.hsnSummary.values.map((row) {
                            return pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  child: pw.Text(row.hsn, style: const pw.TextStyle(fontSize: 7.5)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  child: pw.Text(NumberToWords.formatCurrency(row.taxableValue),
                                      textAlign: pw.TextAlign.right,
                                      style: const pw.TextStyle(fontSize: 7.5)),
                                ),
                                if (invoice.taxMode == TaxMode.cgstSgst) ...[
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    child: pw.Text('${row.cgstRate.toStringAsFixed(row.cgstRate.truncateToDouble() == row.cgstRate ? 0 : 2)}%',
                                        textAlign: pw.TextAlign.center,
                                        style: const pw.TextStyle(fontSize: 7.5)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                    child: pw.Text(NumberToWords.formatCurrency(row.cgstAmount),
                                        textAlign: pw.TextAlign.right,
                                        style: const pw.TextStyle(fontSize: 7.5)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    child: pw.Text('${row.sgstRate.toStringAsFixed(row.sgstRate.truncateToDouble() == row.sgstRate ? 0 : 2)}%',
                                        textAlign: pw.TextAlign.center,
                                        style: const pw.TextStyle(fontSize: 7.5)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                    child: pw.Text(NumberToWords.formatCurrency(row.sgstAmount),
                                        textAlign: pw.TextAlign.right,
                                        style: const pw.TextStyle(fontSize: 7.5)),
                                  ),
                                ] else ...[
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    child: pw.Text('${row.taxRate.toStringAsFixed(row.taxRate.truncateToDouble() == row.taxRate ? 0 : 2)}%',
                                        textAlign: pw.TextAlign.center,
                                        style: const pw.TextStyle(fontSize: 7.5)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                    child: pw.Text(NumberToWords.formatCurrency(row.igstAmount),
                                        textAlign: pw.TextAlign.right,
                                        style: const pw.TextStyle(fontSize: 7.5)),
                                  ),
                                ],
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  child: pw.Text(NumberToWords.formatCurrency(row.totalTax),
                                      textAlign: pw.TextAlign.right,
                                      style: const pw.TextStyle(fontSize: 7.5)),
                                ),
                              ],
                            );
                          }),
                          // HSN Total Row
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                              ),
                            ),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                child: pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                child: pw.Text(NumberToWords.formatCurrency(invoice.totalTaxableValue),
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(font: fontBold, fontSize: 8)),
                              ),
                              if (invoice.taxMode == TaxMode.cgstSgst) ...[
                                pw.Container(),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  child: pw.Text(NumberToWords.formatCurrency(invoice.totalCgst),
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(font: fontBold, fontSize: 8)),
                                ),
                                pw.Container(),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  child: pw.Text(NumberToWords.formatCurrency(invoice.totalSgst),
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(font: fontBold, fontSize: 8)),
                                ),
                              ] else ...[
                                pw.Container(),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  child: pw.Text(NumberToWords.formatCurrency(invoice.totalIgst),
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(font: fontBold, fontSize: 8)),
                                ),
                              ],
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                child: pw.Text(NumberToWords.formatCurrency(invoice.totalTaxAmount),
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(font: fontBold, fontSize: 8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // F. Tax Amount in Words
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            const pw.TextSpan(
                              text: 'Tax Amount (in words) : ',
                              style: pw.TextStyle(fontSize: 7.5),
                            ),
                            pw.TextSpan(
                              text: taxInWords.toUpperCase(),
                              style: pw.TextStyle(font: fontBold, fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // G. Company Bank Details & Signatory
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left: Bank Details & Declaration
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text("Company's Bank Details",
                                    style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                                pw.SizedBox(height: 2),
                                _bankLine("A/c Holder's Name:", invoice.bankDetails.holderName, fontBold),
                                _bankLine("Bank Name :", invoice.bankDetails.bankName, fontBold),
                                _bankLine("A/c No. :", invoice.bankDetails.accountNo, fontBold),
                                _bankLine("Branch & IFS Code :", '${invoice.bankDetails.branch} & ${invoice.bankDetails.ifsc}', fontBold),
                                if (invoice.bankDetails.swiftCode.isNotEmpty)
                                  _bankLine("SWIFT Code :", invoice.bankDetails.swiftCode, fontBold),
                                pw.SizedBox(height: 6),
                                pw.Text('Declaration',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 7.5,
                                        decoration: pw.TextDecoration.underline)),
                                pw.SizedBox(height: 1.5),
                                pw.Text(
                                  invoice.seller.declaration,
                                  style: const pw.TextStyle(fontSize: 6.8),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right: Signatory
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text('for ${invoice.seller.name}',
                                    style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                                pw.SizedBox(height: 40),
                                pw.Text('Authorised Signatory',
                                    style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. JURISDICTION & COMPUTER GENERATED FOOTER (Centered outside box)
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SUBJECT TO ${invoice.seller.jurisdiction.toUpperCase()} JURISDICTION',
                      style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'This is a Computer Generated Invoice',
                      style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.black),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or Save PDF using Printing dialog
  static Future<void> printOrSave(Invoice invoice) async {
    final pdfBytes = await generatePdf(invoice);
    final docType = invoice.invoiceTitle.trim().isNotEmpty
        ? invoice.invoiceTitle.trim().replaceAll(' ', '_')
        : 'Invoice';
    final invoiceName = invoice.metadata.invoiceNo.isNotEmpty
        ? '${docType}_${invoice.metadata.invoiceNo}'
        : docType;
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '$invoiceName.pdf',
    );
  }

  /// Share PDF directly via WhatsApp or Native Mobile Share Sheet
  static Future<void> sharePdf(Invoice invoice) async {
    final pdfBytes = await generatePdf(invoice);
    final docType = invoice.invoiceTitle.trim().isNotEmpty
        ? invoice.invoiceTitle.trim().replaceAll(' ', '_')
        : 'Invoice';
    final invoiceName = invoice.metadata.invoiceNo.isNotEmpty
        ? '${docType}_${invoice.metadata.invoiceNo}'
        : docType;
    final customerName = invoice.buyer.name.trim().isNotEmpty
        ? invoice.buyer.name.trim()
        : 'Customer';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$invoiceName.pdf',
      subject: 'GST Invoice #$invoiceName - $customerName',
      body: 'Dear $customerName,\n\nPlease find attached your GST Invoice ($invoiceName).\n\nThank you for your business!',
    );
  }

  // Helpers
  static pw.Widget _metaBox(String label, String value, pw.Font bold, {bool isBold = false, bool isLast = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: isLast
          ? null
          : const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
            ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.black)),
          pw.Text(
            value.isNotEmpty ? value : ' ',
            style: pw.TextStyle(
              font: isBold ? bold : null,
              fontSize: isBold ? 8 : 7.5,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String title, pw.Font bold, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 2),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : align == pw.TextAlign.center
              ? pw.Alignment.center
              : pw.Alignment.centerLeft,
      child: pw.Text(
        title,
        style: pw.TextStyle(font: bold, fontSize: 7.5),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _hsnHeader(String title, pw.Font bold, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : align == pw.TextAlign.center
              ? pw.Alignment.center
              : pw.Alignment.centerLeft,
      child: pw.Text(
        title,
        style: pw.TextStyle(font: bold, fontSize: 7),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _bankLine(String label, String value, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(label,
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
          ),
          pw.Expanded(
            child: pw.Text(value.isNotEmpty ? value : '—',
                style: pw.TextStyle(font: bold, fontSize: 7.5)),
          ),
        ],
      ),
    );
  }
}
