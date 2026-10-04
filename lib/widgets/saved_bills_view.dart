import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../services/invoice_pdf_service.dart';
import '../utils/number_to_words.dart';

class SavedBillsView extends StatefulWidget {
  const SavedBillsView({super.key});

  @override
  State<SavedBillsView> createState() => _SavedBillsViewState();
}

class _SavedBillsViewState extends State<SavedBillsView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final invoices = provider.savedInvoices;

    final filtered = invoices.where((inv) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = inv.displayName.toLowerCase();
      final customer = inv.buyer.name.toLowerCase();
      final invoiceNo = inv.metadata.invoiceNo.toLowerCase();
      final date = inv.metadata.date.toLowerCase();
      return name.contains(q) ||
          customer.contains(q) ||
          invoiceNo.contains(q) ||
          date.contains(q);
    }).toList();

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Filter & Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ग्राहक के नाम से खोजें (Search by Customer Name, Invoice No., or Date)...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF00A86B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Refresh / Cloud Sync Button
                OutlinedButton.icon(
                  onPressed: (provider.isLoading || provider.isSyncing)
                      ? null
                      : () => provider.refreshInvoices(),
                  icon: (provider.isLoading || provider.isSyncing)
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: Text(provider.isSyncing ? 'सिंक हो रहा है...' : 'Sync / Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),

                // New Bill quick button
                ElevatedButton.icon(
                  onPressed: () => provider.resetToNew(),
                  icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                  label: const Text('+ अगला ग्राहक / नया बिल', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A86B),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Pending Offline Sync Alert Banner (if any bills are pending upload)
          if (provider.pendingSyncCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_queue_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${provider.pendingSyncCount} बिल डिवाइस पर ऑफलाइन सुरक्षित हैं। जैसे ही इंटरनेट चालू होगा, ये अपने आप Firebase पर अपलोड हो जाएंगे।',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: provider.isSyncing ? null : () => provider.refreshInvoices(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (provider.isSyncing)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.sync_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            provider.isSyncing ? 'सिंक जारी...' : 'अभी सिंक करें',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Total Count Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'कुल सुरक्षित बिल्स (Total Saved Bills): ${filtered.length} of ${invoices.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: provider.pendingSyncCount > 0
                            ? const Color(0xFFF59E0B)
                            : (provider.isFirebaseConfigured ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.pendingSyncCount > 0
                          ? '${provider.pendingSyncCount} Offline (Pending Sync)'
                          : (provider.isFirebaseConfigured
                              ? 'Cloud Firestore Synced'
                              : 'Local Storage Mode'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: provider.pendingSyncCount > 0
                            ? const Color(0xFFD97706)
                            : (provider.isFirebaseConfigured
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of Invoices
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            invoices.isEmpty
                                ? 'अभी तक कोई बिल सुरक्षित नहीं है (No bills saved yet)'
                                : 'खोज परिणाम नहीं मिला (No matching bills)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            invoices.isEmpty
                                ? 'डिटेल्स दर्ज करके "बिल जनरेट & सेव करें" पर क्लिक करें।'
                                : 'कृपया किसी अन्य ग्राहक के नाम या बिल नंबर से खोजें।',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          if (invoices.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => provider.resetToNew(),
                              icon: const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
                              label: const Text('पहला बिल बनाएं', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final inv = filtered[index];
                      final isCurrent = inv.id == provider.invoice.id;
                      final primaryName = inv.displayName;
                      final initial = primaryName.isNotEmpty
                          ? primaryName.substring(0, 1).toUpperCase()
                          : '#';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                            width: isCurrent ? 1.6 : 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 4,
                              offset: Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Customer Initial Avatar (Compact 36x36)
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isCurrent
                                      ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                                      : [const Color(0xFF0F172A), const Color(0xFF334155)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Customer & Invoice Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Customer / Saved Name
                                      Flexible(
                                        child: Text(
                                          primaryName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Proforma vs Tax Invoice Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: inv.invoiceTitle.toUpperCase().contains('TAX')
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: inv.invoiceTitle.toUpperCase().contains('TAX')
                                                ? const Color(0xFFA7F3D0)
                                                : const Color(0xFFC7D2FE),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          inv.invoiceTitle.toUpperCase().contains('TAX') ? 'TAX INVOICE' : 'PROFORMA',
                                          style: TextStyle(
                                            color: inv.invoiceTitle.toUpperCase().contains('TAX')
                                                ? const Color(0xFF047857)
                                                : const Color(0xFF4338CA),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'OPEN IN EDITOR',
                                            style: TextStyle(
                                              color: Color(0xFF059669),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: inv.isSynced
                                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                              : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              inv.isSynced ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                                              size: 10,
                                              color: inv.isSynced ? const Color(0xFF059669) : const Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              inv.isSynced ? 'Synced' : 'Offline',
                                              style: TextStyle(
                                                color: inv.isSynced ? const Color(0xFF059669) : const Color(0xFFD97706),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        inv.metadata.invoiceNo.isNotEmpty
                                            ? 'Inv #${inv.metadata.invoiceNo}'
                                            : 'No Invoice #',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                                      const SizedBox(width: 6),
                                      Text(
                                        inv.metadata.date.isNotEmpty ? inv.metadata.date : 'No Date',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${inv.items.length} item(s)',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                      ),
                                      if (inv.buyer.address.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            inv.buyer.address,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Total Amount & Actions Column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  NumberToWords.formatWithSymbol(inv.grandTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // Action Buttons (Compact row)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 1. View Bill Button
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        provider.loadSavedInvoice(inv, openPreview: true);
                                      },
                                      icon: const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
                                      label: const Text('बिल देखें', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00A86B),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // 2. WhatsApp Share Button
                                    IconButton(
                                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF00A86B)),
                                      tooltip: 'WhatsApp पर PDF शेयर करें',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => InvoicePdfService.sharePdf(inv),
                                    ),
                                    const SizedBox(width: 4),

                                    // 3. Edit Details Button
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        provider.loadSavedInvoice(inv);
                                        provider.setViewMode('form');
                                      },
                                      icon: const Icon(Icons.edit_outlined, size: 13),
                                      label: const Text('एडिट करें', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // 4. Print / PDF Button
                                    IconButton(
                                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF059669)),
                                      tooltip: 'प्रिंट / PDF डाउनलोड',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () async {
                                        try {
                                          await InvoicePdfService.printOrSave(inv);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Print error: $e')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 2),

                                    // 5. Use for Next Customer Button
                                    IconButton(
                                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Color(0xFF6366F1)),
                                      tooltip: 'इस सामान से नए ग्राहक का बिल बनाएं (Next Customer)',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        provider.createForNewCustomer(inv);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('सामान व डिटेल्स सेट हो गई! कृपया नए ग्राहक का नाम व पता दर्ज करें।'),
                                            backgroundColor: Color(0xFF6366F1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 2),

                                    // 6. Duplicate Button
                                    IconButton(
                                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF64748B)),
                                      tooltip: 'कॉपी बनाएं (Duplicate)',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => provider.duplicateSavedInvoice(inv),
                                    ),
                                    const SizedBox(width: 2),

                                    // 7. Delete Button
                                    IconButton(
                                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                      tooltip: 'डिलीट करें (Delete)',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('बिल हटाएं?'),
                                            content: Text('क्या आप सचमुच "${inv.displayName}" का बिल हटाना चाहते हैं? यह Cloud Firestore और लोकल मेमोरी दोनों से हट जाएगा।'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(),
                                                child: const Text('रद्द करें'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                                onPressed: () {
                                                  Navigator.of(ctx).pop();
                                                  if (inv.id != null) {
                                                    provider.deleteSavedInvoice(inv.id!);
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
