import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../utils/number_to_words.dart';

class InvoiceHistoryDialog extends StatefulWidget {
  const InvoiceHistoryDialog({super.key});

  @override
  State<InvoiceHistoryDialog> createState() => _InvoiceHistoryDialogState();
}

class _InvoiceHistoryDialogState extends State<InvoiceHistoryDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final invoices = provider.savedInvoices;

    final filtered = invoices.where((inv) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = inv.displayName.toLowerCase();
      final no = inv.metadata.invoiceNo.toLowerCase();
      final customer = inv.buyer.name.toLowerCase();
      final date = inv.metadata.date.toLowerCase();
      return name.contains(q) || no.contains(q) || customer.contains(q) || date.contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Luxury Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF818CF8), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saved Invoice Drafts',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${invoices.length} persistent invoice(s) stored locally',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFFF8FAFC),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Invoice No., Customer Name, or Date...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Invoices List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              invoices.isEmpty
                                  ? 'No saved invoices yet.'
                                  : 'No invoices match your search query.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoices.isEmpty
                                  ? 'Click "Save" on the top bar to store your current invoice in local memory.'
                                  : 'Try searching with another keyword or invoice number.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final inv = filtered[index];
                        final isCurrent = inv.id == provider.invoice.id;
                        final initial = inv.buyer.name.isNotEmpty
                            ? inv.buyer.name.substring(0, 1).toUpperCase()
                            : '#';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar Initial
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCurrent
                                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                        : [const Color(0xFF0F172A), const Color(0xFF334155)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Invoice Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            inv.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha:0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                color: Color(0xFF059669),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${inv.metadata.invoiceNo.isNotEmpty ? "Inv #${inv.metadata.invoiceNo} • " : ""}${inv.metadata.date.isNotEmpty ? inv.metadata.date : "No Date"} • ${inv.items.length} item(s)',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (inv.buyer.address.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        inv.buyer.address,
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Grand Total & Actions
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    NumberToWords.formatWithSymbol(inv.grandTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // View Bill button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          provider.loadSavedInvoice(inv, openPreview: true);
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
                                        label: const Text('बिल देखें'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6366F1),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Edit button
                                      OutlinedButton(
                                        onPressed: () {
                                          provider.loadSavedInvoice(inv);
                                          provider.setViewMode('form');
                                          Navigator.of(context).pop();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        child: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 4),

                                      // Duplicate
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 17, color: Color(0xFF64748B)),
                                        tooltip: 'Clone as new draft',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          provider.duplicateSavedInvoice(inv);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Invoice cloned as new draft.'),
                                              backgroundColor: Color(0xFF0F172A),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),

                                      // Delete
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                        tooltip: 'Delete Draft',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Invoice Draft'),
                                              content: Text(
                                                'Are you sure you want to permanently delete Invoice #${inv.metadata.invoiceNo}?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFDC2626),
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true && inv.id != null) {
                                            await provider.deleteSavedInvoice(inv.id!);
                                          }
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
      ),
    );
  }
}
