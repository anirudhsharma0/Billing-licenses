import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../services/invoice_pdf_service.dart';
import '../utils/number_to_words.dart';
import '../widgets/invoice_preview_sheet.dart';

class MobileBillsScreen extends StatefulWidget {
  const MobileBillsScreen({super.key});

  @override
  State<MobileBillsScreen> createState() => _MobileBillsScreenState();
}

class _MobileBillsScreenState extends State<MobileBillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sharingInvoiceId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _shareOnWhatsApp(Invoice invoice) async {
    final invId = invoice.id ?? invoice.metadata.invoiceNo;
    setState(() {
      _sharingInvoiceId = invId;
    });

    try {
      await InvoicePdfService.sharePdf(invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${invoice.displayName} का बिल PDF WhatsApp पर शेयर किया गया!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('शेयर करने में त्रुटि: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sharingInvoiceId = null;
        });
      }
    }
  }

  void _openBillViewer(BuildContext context, Invoice invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MobileBillViewerPage(invoice: invoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final invoices = provider.savedInvoices;

    // Filter bills by search query
    final filtered = invoices.where((inv) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = inv.displayName.toLowerCase();
      final customer = inv.buyer.name.toLowerCase();
      final invoiceNo = inv.metadata.invoiceNo.toLowerCase();
      final date = inv.metadata.date.toLowerCase();
      final gstin = inv.buyer.gstin.toLowerCase();
      return name.contains(q) ||
          customer.contains(q) ||
          invoiceNo.contains(q) ||
          date.contains(q) ||
          gstin.contains(q);
    }).toList();

    // Calculate bills added today
    final now = DateTime.now();
    final todayStr1 = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final todayStr2 = '${now.day}/${now.month}/${now.year}';
    final todayStr3 = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final todayBillsCount = invoices.where((inv) {
      if (inv.updatedAt != null &&
          inv.updatedAt!.year == now.year &&
          inv.updatedAt!.month == now.month &&
          inv.updatedAt!.day == now.day) {
        return true;
      }
      final d = inv.metadata.date.trim();
      return d == todayStr1 ||
          d == todayStr2 ||
          d == todayStr3 ||
          (d.contains('${now.day}') && d.contains('${now.year}'));
    }).length;

    final sellerName = provider.invoice.seller.name.isNotEmpty
        ? provider.invoice.seller.name
        : 'The Kishan Bharti Coop. M.P. Society Ltd.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.refreshInvoices(),
          color: const Color(0xFF00A86B),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Sleek Top Header (Zero overflow)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      // Logo Icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A86B),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00A86B).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Society Brand (Clean & overflow-free)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sellerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'Mandi Adampur, Hisar',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Refresh / Sync Icon Button
                      IconButton(
                        icon: (provider.isLoading || provider.isSyncing)
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A86B)),
                              )
                            : Icon(
                                provider.pendingSyncCount > 0
                                    ? Icons.cloud_queue_rounded
                                    : Icons.sync_rounded,
                                size: 20,
                                color: provider.pendingSyncCount > 0
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF00A86B),
                              ),
                        tooltip: provider.pendingSyncCount > 0
                            ? '${provider.pendingSyncCount} bills pending sync'
                            : 'Sync Cloud',
                        visualDensity: VisualDensity.compact,
                        onPressed: (provider.isLoading || provider.isSyncing)
                            ? null
                            : () => provider.refreshInvoices(),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Small Top Card: ONLY Today's Added Bills (Small Size as requested)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.today_rounded, size: 16, color: Color(0xFF00A86B)),
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'आज जोड़े गए नए बिल (Today\'s Bills)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A86B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$todayBillsCount नए बिल',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Compact Search Box (Fast Customer Search)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty ? const Color(0xFF00A86B) : const Color(0xFFCBD5E1),
                        width: 1.1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'ग्राहक का नाम खोजें (Search Customer Name)...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF00A86B),
                          size: 19,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ),
              ),

              // 4. Table Header Row: Total Filtered Bills Count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ग्राहक बिल सूची (Recent Bills)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'कुल: ${filtered.length} बिल',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00A86B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Compact Table-Like Bills List (Small rows so maximum data fits on screen)
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(context, provider),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final inv = filtered[index];
                        final isSharing = _sharingInvoiceId == (inv.id ?? inv.metadata.invoiceNo);
                        return _buildCompactBillRow(context, inv, isSharing);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPACT TABLE-LIKE BILL ROW (Small height, tight padding, maximum density)
  // ---------------------------------------------------------------------------
  Widget _buildCompactBillRow(BuildContext context, Invoice inv, bool isSharing) {
    final customerName = inv.buyer.name.trim().isNotEmpty
        ? inv.buyer.name.trim()
        : (inv.savedName.trim().isNotEmpty ? inv.savedName.trim() : 'Customer');

    final invoiceNo = inv.metadata.invoiceNo.trim().isNotEmpty
        ? inv.metadata.invoiceNo.trim()
        : '—';

    final invoiceDate = inv.metadata.date.trim().isNotEmpty
        ? inv.metadata.date.trim()
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openBillViewer(context, inv),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // 1. Small Avatar Box (32x32)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00A86B).withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Color(0xFF00A86B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),

            // 2. Customer Name & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$invoiceNo',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        inv.isSynced ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                        size: 11,
                        color: inv.isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$invoiceDate • ${inv.items.length} item${inv.items.length > 1 ? "s" : ""}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Amount & Tax Tag
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹ ${NumberToWords.formatCurrency(inv.grandTotal)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  inv.taxMode == TaxMode.cgstSgst ? 'CGST+SGST' : 'IGST',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00A86B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // 4. WhatsApp Share Icon (Bilkul Chota / Very Small: 30x30)
            Tooltip(
              message: 'WhatsApp पर शेयर करें',
              child: InkWell(
                onTap: isSharing ? null : () => _shareOnWhatsApp(inv),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isSharing
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white),
                          )
                        : const Icon(Icons.share_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),

            // 5. View Bill Eye Icon (Bilkul Chota / Very Small: 30x30)
            Tooltip(
              message: 'बिल देखें',
              child: InkWell(
                onTap: () => _openBillViewer(context, inv),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Center(
                    child: Icon(Icons.visibility_rounded, size: 15, color: Color(0xFF4F46E5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty Search / Empty List State
  Widget _buildEmptyState(BuildContext context, InvoiceProvider provider) {
    if (_searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text(
                '"$_searchQuery" नाम से कोई बिल नहीं मिला',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear_rounded, size: 15),
                label: const Text('सर्च साफ़ करें', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open_rounded, size: 40, color: Color(0xFF00A86B)),
            const SizedBox(height: 10),
            const Text(
              'कोई सेव किया हुआ बिल मौजूद नहीं है',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => provider.refreshInvoices(),
              icon: const Icon(Icons.sync_rounded, size: 15),
              label: const Text('Cloud Sync', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen Viewer for A4 Bill on Mobile
class MobileBillViewerPage extends StatefulWidget {
  final Invoice invoice;

  const MobileBillViewerPage({super.key, required this.invoice});

  @override
  State<MobileBillViewerPage> createState() => _MobileBillViewerPageState();
}

class _MobileBillViewerPageState extends State<MobileBillViewerPage> {
  final TransformationController _transformController = TransformationController();
  bool _isSharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fitToWidth();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _fitToWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    const sheetWidth = 794.0;
    // Scale so the full 794px A4 sheet fits neatly within the phone screen
    final scale = (screenWidth - 16) / sheetWidth;
    final clampedScale = scale.clamp(0.2, 1.2);
    _transformController.value = Matrix4.identity()..scale(clampedScale, clampedScale);
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale + 0.15).clamp(0.25, 3.5);
    _transformController.value = Matrix4.identity()..scale(newScale, newScale);
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale - 0.15).clamp(0.25, 3.5);
    _transformController.value = Matrix4.identity()..scale(newScale, newScale);
  }

  Future<void> _shareOnWhatsApp() async {
    setState(() {
      _isSharing = true;
    });
    try {
      await InvoicePdfService.sharePdf(widget.invoice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final title = inv.displayName;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Inv #${inv.metadata.invoiceNo} • ₹ ${NumberToWords.formatCurrency(inv.grandTotal)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF00A86B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded, color: Color(0xFF475569), size: 20),
            tooltip: 'Zoom Out (-)',
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen_rounded, color: Color(0xFF475569), size: 19),
            tooltip: 'Fit to Screen',
            onPressed: _fitToWidth,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, color: Color(0xFF475569), size: 20),
            tooltip: 'Zoom In (+)',
            onPressed: _zoomIn,
          ),
          // Print / PDF Button
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Color(0xFF475569), size: 20),
            tooltip: 'Print / Save PDF',
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
        ],
      ),
      body: Container(
        color: const Color(0xFFE2E8F0),
        child: InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          minScale: 0.2,
          maxScale: 3.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: SizedBox(
              width: 794,
              child: InvoicePreviewSheet(invoice: inv),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF1EBE5D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareOnWhatsApp,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                    label: Text(
                      _isSharing ? 'PDF तैयार हो रहा है...' : 'WhatsApp पर भेजें',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
