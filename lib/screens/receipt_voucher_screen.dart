import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/receipt_model.dart';
import '../providers/invoice_provider.dart';
import '../providers/receipt_provider.dart';
import '../services/receipt_pdf_service.dart';
import '../utils/number_to_words.dart';

class ReceiptVoucherScreen extends StatefulWidget {
  const ReceiptVoucherScreen({super.key});

  @override
  State<ReceiptVoucherScreen> createState() => _ReceiptVoucherScreenState();
}

class _ReceiptVoucherScreenState extends State<ReceiptVoucherScreen> {
  final _receiptNoCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _lastSessionId = '';
  String _searchQuery = '';

  @override
  void dispose() {
    _receiptNoCtrl.dispose();
    _dateCtrl.dispose();
    _customerCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _remarksCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _syncControllersIfNeeded(ReceiptProvider provider) {
    if (_lastSessionId == provider.editSessionId) return;
    _lastSessionId = provider.editSessionId;
    final r = provider.currentReceipt;
    _receiptNoCtrl.text = r.receiptNo;
    _dateCtrl.text = r.date;
    _customerCtrl.text = r.customerName;
    _amountCtrl.text = r.amount > 0 ? r.amount.toStringAsFixed(2) : '';
    _refCtrl.text = r.referenceNo;
    _remarksCtrl.text = r.remarks;
  }

  Future<void> _pickDate(ReceiptProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final formatted = DateFormat('dd-MMM-yy').format(picked);
      _dateCtrl.text = formatted;
      provider.updateCurrentReceipt(
        provider.currentReceipt.copyWith(date: formatted),
      );
    }
  }

  Future<void> _handleSave(ReceiptProvider provider) async {
    final r = provider.currentReceipt;
    if (r.customerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया ग्राहक का नाम (Customer Name) दर्ज करें।'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (r.amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया सही राशि (Amount > 0) दर्ज करें।'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await provider.saveCurrentReceipt();
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isCloudSaved
                ? 'रसीद #${result.receipt.receiptNo} सेव और Cloud Firestore पर सिंक हो गई!'
                : 'रसीद #${result.receipt.receiptNo} डिवाइस पर ऑफलाइन सेव हो गई।',
          ),
          backgroundColor: const Color(0xFF00A86B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePrint(ReceiptVoucher receipt, ReceiptPageSize size) async {
    try {
      await ReceiptPdfService.printOrSave(receipt, pageSize: size);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print / PDF Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final invoiceProvider = context.watch<InvoiceProvider>();
    _syncControllersIfNeeded(provider);

    final receipt = provider.currentReceipt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAE8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Action Header
          _buildHeaderBar(context, provider, invoiceProvider, receipt),

          // Main Body: Either Form+Preview OR Saved Receipts List
          Expanded(
            child: provider.activeTab == 'list'
                ? _buildSavedReceiptsList(context, provider)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 820;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildFormPanel(context, provider, receipt),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              flex: 6,
                              child: Container(
                                color: const Color(0xFFE2E8F0),
                                padding: const EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Center(
                                    child: _TallyReceiptPreviewCard(
                                      receipt: receipt,
                                      pageSize: provider.pageSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Mobile / Narrow layout: Form + Preview stacked
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFormPanel(
                              context,
                              provider,
                              receipt,
                              scrollable: false,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Live Tally Receipt Preview',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _TallyReceiptPreviewCard(
                                receipt: receipt,
                                pageSize: provider.pageSize,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context,
    ReceiptProvider provider,
    InvoiceProvider invoiceProvider,
    ReceiptVoucher receipt,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Sub-tabs: New Receipt vs Saved Receipts
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SubTabButton(
                    icon: Icons.receipt_rounded,
                    label: 'नयी रसीद (New Receipt)',
                    selected: provider.activeTab == 'form',
                    onTap: () => provider.setActiveTab('form'),
                  ),
                  _SubTabButton(
                    icon: Icons.list_alt_rounded,
                    label: 'सेव रसीदें (${provider.savedReceipts.length})',
                    selected: provider.activeTab == 'list',
                    onTap: () => provider.setActiveTab('list'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // + New Receipt Button
            OutlinedButton.icon(
              onPressed: () {
                provider.prepareNewReceipt(seller: invoiceProvider.invoice.seller);
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('+ नयी रसीद'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 10),

            // Page Size Toggle: A4 / A5
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ReceiptPageSize.values.map((size) {
                  final selected = provider.pageSize == size;
                  return InkWell(
                    onTap: () => provider.setPageSize(size),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF0F172A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        size.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 10),

            // Save Receipt Button
            ElevatedButton.icon(
              onPressed: provider.isSaving ? null : () => _handleSave(provider),
              icon: provider.isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 16, color: Colors.white),
              label: Text(
                receipt.id != null ? 'रसीद अपडेट करें' : 'रसीद सेव करें',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
            ),
            const SizedBox(width: 8),

            // Print / Export PDF Button
            ElevatedButton.icon(
              onPressed: () => _handlePrint(receipt, provider.pageSize),
              icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
              label: Text(
                'प्रिंट / PDF (${provider.pageSize.label})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
            ),
            const SizedBox(width: 8),

            // Share PDF Button
            IconButton(
              tooltip: 'PDF शेयर करें',
              icon: const Icon(Icons.share_rounded, color: Color(0xFF00A86B)),
              onPressed: () => ReceiptPdfService.sharePdf(
                receipt,
                pageSize: provider.pageSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel(
    BuildContext context,
    ReceiptProvider provider,
    ReceiptVoucher receipt, {
    bool scrollable = true,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (receipt.linkedInvoiceNo != null && receipt.linkedInvoiceNo!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: Color(0xFF047857)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bill #${receipt.linkedInvoiceNo} से लिंक की गई रसीद',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Row 1: Receipt No & Date
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _receiptNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Receipt No. (रसीद नं.)',
                  prefixIcon: Icon(Icons.tag_rounded, size: 18),
                ),
                onChanged: (v) => provider.updateCurrentReceipt(
                  receipt.copyWith(receiptNo: v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _dateCtrl,
                decoration: InputDecoration(
                  labelText: 'Dated (DD-MMM-YY)',
                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 17),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    onPressed: () => _pickDate(provider),
                  ),
                ),
                onChanged: (v) => provider.updateCurrentReceipt(
                  receipt.copyWith(date: v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Customer Name (Account:)
        TextField(
          controller: _customerCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Account / Customer Name (ग्राहक का नाम) *',
            hintText: 'e.g. SUNIL KUMAR S/O UMED SINGH',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 19),
          ),
          onChanged: (v) => provider.updateCurrentReceipt(
            receipt.copyWith(customerName: v),
          ),
        ),
        const SizedBox(height: 14),

        // Amount
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount Received (प्राप्त राशि ₹) *',
            hintText: 'e.g. 18000',
            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '').trim()) ?? 0.0;
            provider.updateCurrentReceipt(
              receipt.copyWith(amount: parsed),
            );
          },
        ),
        const SizedBox(height: 8),
        if (receipt.amount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Amount in Words: ${receipt.amountInWords}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        const SizedBox(height: 14),

        // Payment Mode (Through:)
        const Text(
          'Through / Payment Mode (भुगतान का माध्यम)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PaymentMode.values.map((mode) {
            final selected = receipt.paymentMode == mode;
            return ChoiceChip(
              label: Text(mode.label),
              selected: selected,
              selectedColor: const Color(0xFFE8F5EE),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF047857) : const Color(0xFF475569),
              ),
              side: BorderSide(
                color: selected ? const Color(0xFF00A86B) : const Color(0xFFCBD5E1),
              ),
              onSelected: (_) => provider.updateCurrentReceipt(
                receipt.copyWith(paymentMode: mode),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Optional Reference No (UPI Ref / Cheque No / UTR)
        TextField(
          controller: _refCtrl,
          decoration: const InputDecoration(
            labelText: 'Reference / Cheque / UTR No. (वैकल्पिक)',
            hintText: 'e.g. UPI Ref 4123xxxx / Chq #001234',
            prefixIcon: Icon(Icons.confirmation_number_outlined, size: 18),
          ),
          onChanged: (v) => provider.updateCurrentReceipt(
            receipt.copyWith(referenceNo: v),
          ),
        ),
        const SizedBox(height: 14),

        // Optional Remarks
        TextField(
          controller: _remarksCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Remarks / On Account of (वैकल्पिक)',
            hintText: 'e.g. Part payment against Solar System Bill #1',
            prefixIcon: Icon(Icons.notes_rounded, size: 18),
          ),
          onChanged: (v) => provider.updateCurrentReceipt(
            receipt.copyWith(remarks: v),
          ),
        ),
      ],
    );

    if (!scrollable) return content;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: content,
    );
  }

  Widget _buildSavedReceiptsList(BuildContext context, ReceiptProvider provider) {
    final filtered = provider.savedReceipts.where((r) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.customerName.toLowerCase().contains(q) ||
          r.receiptNo.toLowerCase().contains(q) ||
          r.paymentMode.label.toLowerCase().contains(q) ||
          r.date.toLowerCase().contains(q);
    }).toList();

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          // Search & Sync Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'रसीद खोजें (Customer Name, Receipt No, Mode, Date)...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00A86B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'कुल प्राप्त: ${NumberToWords.formatWithSymbol(provider.totalCollected)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: provider.isSyncing ? null : () => provider.refreshReceipts(),
                  icon: provider.isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'अभी कोई रसीद सेव नहीं है।',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '#${r.receiptNo}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          r.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          r.paymentMode.label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0369A1),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        r.isSynced ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                                        size: 13,
                                        color: r.isSynced ? const Color(0xFF059669) : const Color(0xFFD97706),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Dated: ${r.date}${r.linkedInvoiceNo != null && r.linkedInvoiceNo!.isNotEmpty ? ' • Bill #${r.linkedInvoiceNo}' : ''}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  NumberToWords.formatWithSymbol(r.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF00A86B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Print / PDF',
                                      icon: const Icon(Icons.print_rounded, size: 17, color: Color(0xFF0F172A)),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _handlePrint(r, provider.pageSize),
                                    ),
                                    IconButton(
                                      tooltip: 'Share PDF',
                                      icon: const Icon(Icons.share_rounded, size: 17, color: Color(0xFF00A86B)),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => ReceiptPdfService.sharePdf(r, pageSize: provider.pageSize),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF4F46E5)),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => provider.loadReceiptForEdit(r),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFDC2626)),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('रसीद हटाएं?'),
                                            content: Text('क्या आप "${r.displayName}" की रसीद #${r.receiptNo} हटाना चाहते हैं?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(),
                                                child: const Text('रद्द करें'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                                onPressed: () {
                                                  Navigator.of(ctx).pop();
                                                  if (r.id != null) {
                                                    provider.deleteReceipt(r.id!);
                                                  }
                                                },
                                                child: const Text('हटाएं', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
          ),
        ],
      ),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? const Color(0xFF00A86B) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// On-screen Tally-standard Receipt Voucher Preview
class _TallyReceiptPreviewCard extends StatelessWidget {
  final ReceiptVoucher receipt;
  final ReceiptPageSize pageSize;

  const _TallyReceiptPreviewCard({
    required this.receipt,
    required this.pageSize,
  });

  @override
  Widget build(BuildContext context) {
    final seller = receipt.seller;
    final sellerName = seller.name.trim().isNotEmpty
        ? seller.name.trim()
        : 'The Kishan Bharti Coop. M.P. Society Ltd.';

    final stateLine = [
      if (seller.state.trim().isNotEmpty) 'State Name : ${seller.state.trim()}',
      if (seller.stateCode.trim().isNotEmpty) 'Code : ${seller.stateCode.trim()}',
    ].join(', ');

    final contactLine = [
      if (seller.phone.trim().isNotEmpty) 'Contact : ${seller.phone.trim()}',
      if (seller.email.trim().isNotEmpty) 'E-Mail : ${seller.email.trim()}',
    ].join('  |  ');

    return Container(
      constraints: BoxConstraints(maxWidth: pageSize == ReceiptPageSize.a5 ? 480 : 620),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                seller.logoUrl.isNotEmpty ? seller.logoUrl : 'assets/images/coop-logo.png',
                width: 54,
                height: 54,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 54, height: 54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    if (seller.address.trim().isNotEmpty)
                      Text(seller.address.trim(), style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    if (stateLine.isNotEmpty)
                      Text(stateLine, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    if (contactLine.isNotEmpty)
                      Text(contactLine, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 1, height: 20),

          // 2. Center Title
          const Center(
            child: Text(
              'Receipt Voucher',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Meta Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No. : ${receipt.receiptNo}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black),
              ),
              Text(
                'Dated : ${receipt.date}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 4. Main Particulars Box
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.0),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.black, width: 1.0)),
                          ),
                          child: const Text(
                            'Particulars',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(
                            'Amount',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.black, width: 1.0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Account :', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11.5)),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text(
                                  receipt.customerName.trim().isNotEmpty
                                      ? receipt.customerName.trim().toUpperCase()
                                      : '—',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Through :', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11.5)),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text(
                                  receipt.throughText,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              if (receipt.remarks.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.only(left: 14),
                                  child: Text(
                                    'On Account of : ${receipt.remarks.trim()}',
                                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Text('Amount (in words) :', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11.5)),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text(
                                  receipt.amountInWords,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
                          child: Text(
                            receipt.formattedAmount,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Total Row with Double Underline
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black, width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          height: 32,
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.black, width: 1.0)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                receipt.formattedAmount,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                              ),
                              const SizedBox(height: 1.5),
                              Container(width: 80, height: 1, color: Colors.black),
                              const SizedBox(height: 1.5),
                              Container(width: 80, height: 1, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // 5. Footer: Authorised Signatory
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              children: [
                if (seller.signatureUrl.trim().isNotEmpty &&
                    !kIsWeb &&
                    File(seller.signatureUrl.trim()).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Image.file(
                      File(seller.signatureUrl.trim()),
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  const SizedBox(height: 26),
                const Text(
                  'Authorised Signatory',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

