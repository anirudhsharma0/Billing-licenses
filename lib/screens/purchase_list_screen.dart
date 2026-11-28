import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import '../providers/invoice_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/purchase_pdf_service.dart';
import '../utils/number_to_words.dart';
import 'add_purchase_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddEditScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddPurchaseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final buyerFirm = context.read<InvoiceProvider>().invoice.seller;
    final purchases = provider.savedPurchases;

    final filtered = purchases.where((p) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.supplier.name.toLowerCase().contains(q) ||
          p.metadata.invoiceNo.toLowerCase().contains(q) ||
          p.metadata.date.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5D0DC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Summary KPI Cards
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: const Color(0xFFF8FAFC),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 680;
                final cards = [
                  _KpiCard(
                    title: 'Total Purchase Amount',
                    value: NumberToWords.formatWithSymbol(provider.totalPurchaseAmount),
                    icon: Icons.shopping_bag_outlined,
                    iconColor: const Color(0xFFA0003A),
                    bgColor: const Color(0xFFFCE4EC),
                  ),
                  _KpiCard(
                    title: 'Total Input GST',
                    value: NumberToWords.formatWithSymbol(provider.totalInputGst),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFFC2185B),
                    bgColor: const Color(0xFFEEF2FF),
                  ),
                  _KpiCard(
                    title: 'Purchase Bills Count',
                    value: '${purchases.length} Bills',
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: cards[1]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[2]),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[2]),
                  ],
                );
              },
            ),
          ),

          // 2. Search Bar & + Add Purchase Bill Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'खरीद बिल खोजें (Supplier Name, Invoice No., Date)...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA0003A)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: provider.isSyncing ? null : () => provider.refreshPurchases(),
                  icon: provider.isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.prepareNewPurchase();
                    _openAddEditScreen(context);
                  },
                  icon: const Icon(Icons.add_rounded, size: 17, color: Colors.white),
                  label: const Text(
                    '+ नया खरीद बिल (Add Purchase Bill)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0003A),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // 3. Saved Purchase Bills List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 46, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'अभी कोई खरीद बिल सेव नहीं है।',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return _PurchaseBillCard(
                        purchase: p,
                        onViewPrint: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _PurchasePreviewPage(
                                purchase: p,
                                buyerFirm: buyerFirm,
                              ),
                            ),
                          );
                        },
                        onEdit: () {
                          provider.loadPurchaseForEdit(p);
                          _openAddEditScreen(context);
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('खरीद बिल हटाएं?'),
                              content: Text('क्या आप "${p.displayName}" का खरीद बिल हटाना चाहते हैं?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('रद्द करें'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    if (p.id != null) {
                                      provider.deletePurchase(p.id!);
                                    }
                                  },
                                  child: const Text('हटाएं', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5D0DC)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A0A10)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseBillCard extends StatelessWidget {
  final PurchaseBill purchase;
  final VoidCallback onViewPrint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PurchaseBillCard({
    required this.purchase,
    required this.onViewPrint,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              purchase.displayName.isNotEmpty ? purchase.displayName[0].toUpperCase() : 'P',
              style: const TextStyle(
                color: Color(0xFFA0003A),
                fontWeight: FontWeight.w800,
                fontSize: 15,
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
                        purchase.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A0A10)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      purchase.isSynced ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                      size: 13,
                      color: purchase.isSynced ? const Color(0xFF880E4F) : const Color(0xFFD97706),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Inv #${purchase.metadata.invoiceNo.isNotEmpty ? purchase.metadata.invoiceNo : '—'}  •  ${purchase.metadata.date}  •  ${purchase.items.length} item(s)  •  Input GST: ${NumberToWords.formatWithSymbol(purchase.totalInputGst)}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberToWords.formatWithSymbol(purchase.grandTotal),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1A0A10)),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: onViewPrint,
                    icon: const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
                    label: const Text('View / Print', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA0003A),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 13),
                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchasePreviewPage extends StatelessWidget {
  final PurchaseBill purchase;
  final SellerDetails buyerFirm;

  const _PurchasePreviewPage({
    required this.purchase,
    required this.buyerFirm,
  });

  @override
  Widget build(BuildContext context) {
    final safeName = purchase.supplier.name.trim().isNotEmpty
        ? purchase.supplier.name
            .trim()
            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'Purchase';
    final inv = purchase.metadata.invoiceNo.trim().isNotEmpty
        ? purchase.metadata.invoiceNo.trim()
        : 'Bill';

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Purchase Bill Preview — ${purchase.displayName}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () =>
                PurchasePdfService.printOrSave(purchase, buyerFirm: buyerFirm),
            icon: const Icon(Icons.print_rounded, size: 15, color: Colors.white),
            label: const Text(
              'Print / Save PDF',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA0003A),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: PdfPreview(
        build: (PdfPageFormat format) =>
            PurchasePdfService.generatePdf(purchase, buyerFirm: buyerFirm),
        initialPageFormat: PdfPageFormat.a4,
        maxPageWidth: 640,
        scrollViewDecoration: const BoxDecoration(
          color: Color(0xFFCBD5E1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: 'Purchase_${inv}_$safeName.pdf',
      ),
    );
  }
}

