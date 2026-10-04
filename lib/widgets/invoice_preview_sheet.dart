import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../utils/number_to_words.dart';

class InvoicePreviewSheet extends StatelessWidget {
  final Invoice invoice;

  const InvoicePreviewSheet({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final amountInWords = NumberToWords.convert(invoice.grandTotal, prefix: '');
    final taxInWords = NumberToWords.convert(invoice.totalTaxAmount, prefix: 'INR');

    // A4 width standard at 96 DPI is approx 794px. We fix sheet width to 794 for consistent 1:1 view
    return Container(
      width: 794,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            spreadRadius: 2,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP DOCUMENT TITLE (Above Box, Centered)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              invoice.invoiceTitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.black,
              ),
            ),
          ),

          // 2. MAIN OUTER BORDER BOX
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.0),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A. Seller Header with Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo on Left (Preserving current cooperative logo)
                      Container(
                        width: 90,
                        height: 72,
                        margin: const EdgeInsets.only(right: 12),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/coop-logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: const Text('LOGO', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ),
                        ),
                      ),
                      // Seller details centered
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              invoice.seller.name.isNotEmpty
                                  ? invoice.seller.name
                                  : 'The Kishan Bharti Coop. M.P. Society Ltd.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              invoice.seller.address,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'GSTIN/UIN: ${invoice.seller.gstin}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'State Name : ${invoice.seller.state}, Code : ${invoice.seller.stateCode}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (invoice.seller.email.isNotEmpty)
                              Text(
                                'E-Mail : ${invoice.seller.email}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // B. Buyer & Consignee + Invoice Metadata Grid
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: Buyer & Invoice Info
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.black, width: 1.0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Buyer details
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Buyer (Bill to)',
                                        style: TextStyle(fontSize: 9.5, color: Colors.black)),
                                    const SizedBox(height: 2),
                                    Text(
                                      invoice.buyer.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      invoice.buyer.address,
                                      style: const TextStyle(fontSize: 10, color: Colors.black),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'State Name : ${invoice.buyer.state}, Code : ${invoice.buyer.stateCode}',
                                      style: const TextStyle(fontSize: 9.5, color: Colors.black),
                                    ),
                                    if (invoice.buyer.gstin.isNotEmpty)
                                      Text(
                                        'GSTIN/UIN: ${invoice.buyer.gstin}',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Invoice Metadata Sub-grid
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.black, width: 1.0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: Colors.black, width: 1.0),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _metaBox('Invoice No.', invoice.metadata.invoiceNo, isBold: true),
                                            _metaBox('Delivery Note', invoice.metadata.deliveryNote),
                                            _metaBox('Reference No. & Date.', invoice.metadata.referenceNo, isLast: true),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _metaBox('Dated', invoice.metadata.date, isBold: true),
                                          _metaBox('Delivery Note Date', invoice.metadata.deliveryNoteDate),
                                          _metaBox('Other References', invoice.metadata.otherReferences, isLast: true),
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

                      // RIGHT: Consignee & Dispatch Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Consignee details
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Consignee (Ship to)',
                                      style: TextStyle(fontSize: 9.5, color: Colors.black)),
                                  const SizedBox(height: 2),
                                  Text(
                                    (invoice.consignee.name.isNotEmpty
                                            ? invoice.consignee.name
                                            : invoice.buyer.name)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    invoice.consignee.address.isNotEmpty
                                        ? invoice.consignee.address
                                        : invoice.buyer.address,
                                    style: const TextStyle(fontSize: 10, color: Colors.black),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'State Name : ${invoice.consignee.state.isNotEmpty ? invoice.consignee.state : invoice.buyer.state}, Code : ${invoice.consignee.stateCode.isNotEmpty ? invoice.consignee.stateCode : invoice.buyer.stateCode}',
                                    style: const TextStyle(fontSize: 9.5, color: Colors.black),
                                  ),
                                  if (invoice.consignee.gstin.isNotEmpty || invoice.buyer.gstin.isNotEmpty)
                                    Text(
                                      'GSTIN/UIN: ${invoice.consignee.gstin.isNotEmpty ? invoice.consignee.gstin : invoice.buyer.gstin}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Dispatch Sub-grid matching exact PDF layout
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.black, width: 1.0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Row 1: Destination | Dispatch Doc No.
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              right: BorderSide(color: Colors.black, width: 1.0),
                                              bottom: BorderSide(color: Colors.black, width: 1.0),
                                            ),
                                          ),
                                          child: _metaBox('Destination', invoice.metadata.destination, isLast: true),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.black, width: 1.0),
                                            ),
                                          ),
                                          child: _metaBox('Dispatch Doc No.', invoice.metadata.dispatchDocNo, isLast: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Row 2: (blank left) | Dispatched through
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              right: BorderSide(color: Colors.black, width: 1.0),
                                              bottom: BorderSide(color: Colors.black, width: 1.0),
                                            ),
                                          ),
                                          child: _metaBox('', '', isLast: true),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.black, width: 1.0),
                                            ),
                                          ),
                                          child: _metaBox('Dispatched through', invoice.metadata.dispatchedThrough, isLast: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Row 3: Mode/Terms of Payment (Full Width)
                                  _metaBox('Mode/Terms of Payment', invoice.metadata.paymentTerms),
                                  // Row 4: Terms of Delivery (Full Width)
                                  _metaBox('Terms of Delivery', invoice.metadata.termsOfDelivery, isLast: true),
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
                _buildItemsTable(),

                // D. Amount Chargeable in Words
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Amount Chargeable (in words) ',
                                style: TextStyle(fontSize: 10, color: Colors.black),
                              ),
                              TextSpan(
                                text: 'INR ${amountInWords.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Text(
                        'E. & O.E',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // E. HSN/SAC Tax Summary Table
                _buildHsnSummaryTable(),

                // F. Tax Amount in Words
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Tax Amount (in words) : ',
                          style: TextStyle(fontSize: 10, color: Colors.black),
                        ),
                        TextSpan(
                          text: taxInWords.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // G. Declaration, Bank Details & Signatory
                _buildFooterSection(),
              ],
            ),
          ),

          // 3. JURISDICTION & COMPUTER GENERATED FOOTER (Centered outside box)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Text(
                  'SUBJECT TO ${invoice.seller.jurisdiction.toUpperCase()} JURISDICTION',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 1),
                const Text(
                  'This is a Computer Generated Invoice',
                  style: TextStyle(fontSize: 9, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sub-components
  Widget _metaBox(String label, String value, {bool isBold = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8.5, color: Colors.black)),
          Text(
            value.isNotEmpty ? value : ' ',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontSize: isBold ? 11 : 10,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
      ),
      child: Table(
        border: const TableBorder(
          verticalInside: BorderSide(color: Colors.black, width: 1.0),
        ),
        columnWidths: const {
          0: FixedColumnWidth(34), // Sl No
          1: FlexColumnWidth(4),  // Description of Goods and Services
          2: FixedColumnWidth(66), // HSN/SAC
          3: FixedColumnWidth(66), // Quantity
          4: FixedColumnWidth(85), // Rate
          5: FixedColumnWidth(36), // per
          6: FixedColumnWidth(96), // Amount
        },
        children: [
          // Header Row
          const TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
            ),
            children: [
              _HeaderCell('Sl\nNo.', align: TextAlign.center),
              _HeaderCell('Description of\nGoods and Services', align: TextAlign.center),
              _HeaderCell('HSN/SAC', align: TextAlign.center),
              _HeaderCell('Quantity', align: TextAlign.center),
              _HeaderCell('Rate', align: TextAlign.center),
              _HeaderCell('per', align: TextAlign.center),
              _HeaderCell('Amount', align: TextAlign.center),
            ],
          ),

          // Items Rows
          ...invoice.items.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('$idx',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                      if (item.subtext.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 4),
                          child: Text(
                            item.subtext,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(item.hsn.isNotEmpty ? item.hsn : '—',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, color: Colors.black)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(NumberToWords.formatCurrency(item.rate),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 10.5, color: Colors.black)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(item.unit,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, color: Colors.black)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(NumberToWords.formatCurrency(item.lineTotal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            );
          }),

          // Subtotal Spacer row
          TableRow(
            children: [
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(top: 2, right: 4),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black, width: 0.5)),
                ),
                child: Text(
                  NumberToWords.formatCurrency(invoice.totalTaxableValue),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),

          // Tax Output rows inside Item Table (Tally Style)
          ...invoice.taxBreakupList.map((tax) {
            return TableRow(
              children: [
                const SizedBox(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  child: Text(
                    tax.label,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(),
                const SizedBox(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  child: Text(
                    tax.rateStr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ),
                const SizedBox(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  child: Text(
                    NumberToWords.formatCurrency(tax.amount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            );
          }),

          // Total Row
          TableRow(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black, width: 1.0)),
            ),
            children: [
              const SizedBox(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              const SizedBox(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  '${invoice.totalQuantity.toStringAsFixed(invoice.totalQuantity.truncateToDouble() == invoice.totalQuantity ? 0 : 2)} ${invoice.items.isNotEmpty ? invoice.items[0].unit : "set"}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(),
              const SizedBox(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  '₹ ${NumberToWords.formatCurrency(invoice.grandTotal)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHsnSummaryTable() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
      ),
      child: Table(
        border: const TableBorder(
          horizontalInside: BorderSide(color: Colors.black, width: 0.5),
          verticalInside: BorderSide(color: Colors.black, width: 1.0),
        ),
        children: [
          // Header Row
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
            ),
            children: [
              const _HsnCell('HSN/SAC', isHeader: true, align: TextAlign.center),
              const _HsnCell('Taxable\nValue', isHeader: true, align: TextAlign.center),
              if (invoice.taxMode == TaxMode.cgstSgst) ...[
                const _HsnCell('CGST\nRate', isHeader: true, align: TextAlign.center),
                const _HsnCell('CGST\nAmount', isHeader: true, align: TextAlign.center),
                const _HsnCell('SGST/UTGST\nRate', isHeader: true, align: TextAlign.center),
                const _HsnCell('SGST/UTGST\nAmount', isHeader: true, align: TextAlign.center),
              ] else ...[
                const _HsnCell('IGST\nRate', isHeader: true, align: TextAlign.center),
                const _HsnCell('IGST\nAmount', isHeader: true, align: TextAlign.center),
              ],
              const _HsnCell('Total\nTax Amount', isHeader: true, align: TextAlign.center),
            ],
          ),
          // HSN Summary Rows
          ...invoice.hsnSummary.values.map((row) {
            return TableRow(
              children: [
                _HsnCell(row.hsn, align: TextAlign.center),
                _HsnCell(NumberToWords.formatCurrency(row.taxableValue), align: TextAlign.right),
                if (invoice.taxMode == TaxMode.cgstSgst) ...[
                  _HsnCell('${row.cgstRate.toStringAsFixed(row.cgstRate.truncateToDouble() == row.cgstRate ? 0 : 2)}%', align: TextAlign.center),
                  _HsnCell(NumberToWords.formatCurrency(row.cgstAmount), align: TextAlign.right, isBold: true),
                  _HsnCell('${row.sgstRate.toStringAsFixed(row.sgstRate.truncateToDouble() == row.sgstRate ? 0 : 2)}%', align: TextAlign.center),
                  _HsnCell(NumberToWords.formatCurrency(row.sgstAmount), align: TextAlign.right, isBold: true),
                ] else ...[
                  _HsnCell('${row.taxRate.toStringAsFixed(row.taxRate.truncateToDouble() == row.taxRate ? 0 : 2)}%', align: TextAlign.center),
                  _HsnCell(NumberToWords.formatCurrency(row.igstAmount), align: TextAlign.right, isBold: true),
                ],
                _HsnCell(NumberToWords.formatCurrency(row.totalTax), align: TextAlign.right, isBold: true),
              ],
            );
          }),
          // Total HSN Row
          TableRow(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black, width: 1.0)),
            ),
            children: [
              const _HsnCell('Total', isHeader: true),
              _HsnCell(NumberToWords.formatCurrency(invoice.totalTaxableValue), align: TextAlign.right, isBold: true),
              if (invoice.taxMode == TaxMode.cgstSgst) ...[
                const _HsnCell(''),
                _HsnCell(NumberToWords.formatCurrency(invoice.totalCgst), align: TextAlign.right, isBold: true),
                const _HsnCell(''),
                _HsnCell(NumberToWords.formatCurrency(invoice.totalSgst), align: TextAlign.right, isBold: true),
              ] else ...[
                const _HsnCell(''),
                _HsnCell(NumberToWords.formatCurrency(invoice.totalIgst), align: TextAlign.right, isBold: true),
              ],
              _HsnCell(NumberToWords.formatCurrency(invoice.totalTaxAmount), align: TextAlign.right, isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Bank Details & Declaration
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.black, width: 1.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Company's Bank Details",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 3),
                _bankRow("A/c Holder's Name:", invoice.bankDetails.holderName),
                _bankRow("Bank Name :", invoice.bankDetails.bankName),
                _bankRow("A/c No. :", invoice.bankDetails.accountNo, isMono: true),
                _bankRow("Branch & IFS Code :", "${invoice.bankDetails.branch} & ${invoice.bankDetails.ifsc}"),
                if (invoice.bankDetails.swiftCode.isNotEmpty)
                  _bankRow("SWIFT Code :", invoice.bankDetails.swiftCode),
                const SizedBox(height: 10),
                const Text(
                  'Declaration',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.seller.declaration,
                  style: const TextStyle(fontSize: 9, color: Colors.black),
                ),
              ],
            ),
          ),
        ),

        // Right: Signatory
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'for ${invoice.seller.name}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 60),
                const Text(
                  'Authorised Signatory',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bankRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.black)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: isMono ? 'monospace' : null,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _HeaderCell(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }
}

class _HsnCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isBold;
  final TextAlign align;

  const _HsnCell(this.text, {this.isHeader = false, this.isBold = false, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }
}
