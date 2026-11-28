import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/solar_purchase_catalog.dart';
import '../models/stock_model.dart';
import '../providers/invoice_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/stock_provider.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'in_stock', 'low', 'out'
  bool _includeCatalogDefaults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    if (qty == qty.truncateToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  Future<void> _confirmResetStock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'स्टॉक को 0 पर रीसेट करें?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'इससे अभी तक का सारा स्टॉक 0 हो जाएगा और अब से जो भी नया Purchase या Sale बिल बनेगा, सिर्फ़ वही स्टॉक में जुड़ेगा।',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('नहीं'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('हाँ, 0 करें'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<StockProvider>().resetStockToZero();
    }
  }

  Future<void> _showAddOrEditOpeningDialog(
    BuildContext context, {
    StockItemSummary? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.itemName ?? '');
    final hsnCtrl = TextEditingController(text: existing?.hsn ?? '');
    final qtyCtrl = TextEditingController(
      text: existing != null && existing.openingQty != 0
          ? _formatQty(existing.openingQty)
          : '',
    );
    String selectedUnit = existing?.unit.isNotEmpty == true ? existing!.unit : 'PCS';
    const units = ['PCS', 'MTR', 'KG', 'PKT', 'SET', 'NOS'];
    if (!units.contains(selectedUnit)) {
      selectedUnit = 'PCS';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFFA0003A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      existing == null
                          ? 'नया स्टॉक / Opening Stock जोड़ें'
                          : 'Opening Stock अपडेट करें',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A0A10),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (existing == null) ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'सोलर कैटलॉग से चुनें (Optional)',
                          ),
                          hint: const Text('कैटलॉग आइटम चुनें या नीचे नाम लिखें'),
                          items: SolarPurchaseCatalog.items
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.description,
                                  child: Text(
                                    item.description,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final match = SolarPurchaseCatalog.items.firstWhere(
                              (e) => e.description == val,
                            );
                            setDialogState(() {
                              nameCtrl.text = match.description;
                              hsnCtrl.text = match.hsn;
                              if (units.contains(match.unit)) {
                                selectedUnit = match.unit;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: nameCtrl,
                        readOnly: existing != null,
                        decoration: const InputDecoration(
                          labelText: 'आइटम का नाम (Item Name) *',
                          hintText: 'जैसे: Waaree Topcon 610 Wp Dcr',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: hsnCtrl,
                              decoration: const InputDecoration(
                                labelText: 'HSN / SAC Code',
                                hintText: '85414300',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(labelText: 'Unit'),
                              items: units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u, style: const TextStyle(fontSize: 13)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedUnit = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Opening / Manual Stock Qty *',
                          hintText: 'जितना पहले से स्टॉक में है (जैसे 25)',
                        ),
                      ),
                      if (existing != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'खरीद (In): ${_formatQty(existing.purchasedQty)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFA0003A),
                                ),
                              ),
                              Text(
                                'बिक्री (Out): ${_formatQty(existing.soldQty)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFC2185B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('रद्द करें'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0003A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                    if (name.isEmpty) return;

                    await context.read<StockProvider>().setOpeningStock(
                          itemName: name,
                          openingQty: qty,
                          hsn: hsnCtrl.text.trim(),
                          unit: selectedUnit,
                        );
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 17),
                  label: const Text('सेव करें'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    hsnCtrl.dispose();
    qtyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final purchaseProvider = context.watch<PurchaseProvider>();
    final invoiceProvider = context.watch<InvoiceProvider>();

    final allItems = stockProvider.buildStockSummary(
      purchases: purchaseProvider.savedPurchases,
      invoices: invoiceProvider.savedInvoices,
      includeCatalogDefaults: _includeCatalogDefaults,
    );

    final totalIn = allItems.fold<double>(0.0, (s, e) => s + e.totalInQty);
    final totalSold = allItems.fold<double>(0.0, (s, e) => s + e.soldQty);
    final totalAvailable = allItems.fold<double>(0.0, (s, e) => s + e.availableQty);

    final filtered = allItems.where((item) {
      if (_statusFilter == 'in_stock' && item.availableQty <= 0) return false;
      if (_statusFilter == 'low' && !item.isLowStock) return false;
      if (_statusFilter == 'out' && !item.isOutOfStock) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return item.itemName.toLowerCase().contains(q) ||
            item.hsn.toLowerCase().contains(q);
      }
      return true;
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
          // 1. Top KPI Summary Cards
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: const Color(0xFFF8FAFC),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 760;
                final cards = [
                  _StockKpiCard(
                    title: 'कुल आइटम (Total Items)',
                    value: '${allItems.length}',
                    subtitle: 'Active + Catalog',
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                  ),
                  _StockKpiCard(
                    title: 'आया स्टॉक (Stock In)',
                    value: _formatQty(totalIn),
                    subtitle: 'Opening + Purchased',
                    icon: Icons.arrow_downward_rounded,
                    iconColor: const Color(0xFFA0003A),
                    bgColor: const Color(0xFFFCE4EC),
                  ),
                  _StockKpiCard(
                    title: 'बिका स्टॉक (Sold)',
                    value: _formatQty(totalSold),
                    subtitle: 'From Saved Bills',
                    icon: Icons.arrow_upward_rounded,
                    iconColor: const Color(0xFFC2185B),
                    bgColor: const Color(0xFFEEF2FF),
                  ),
                  _StockKpiCard(
                    title: 'अभी उपलब्ध (Available)',
                    value: _formatQty(totalAvailable),
                    subtitle: 'Current Closing Stock',
                    icon: Icons.inventory_rounded,
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: cards[2]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[2]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[3]),
                  ],
                );
              },
            ),
          ),

          // 2. Search, Filters & Add Opening Stock Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'आइटम या HSN खोजें...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FilterChipBtn(
                      label: 'सभी',
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    _FilterChipBtn(
                      label: 'उपलब्ध',
                      selected: _statusFilter == 'in_stock',
                      onTap: () => setState(() => _statusFilter = 'in_stock'),
                    ),
                    _FilterChipBtn(
                      label: 'कम (≤5)',
                      selected: _statusFilter == 'low',
                      onTap: () => setState(() => _statusFilter = 'low'),
                    ),
                    _FilterChipBtn(
                      label: 'खत्म (0)',
                      selected: _statusFilter == 'out',
                      onTap: () => setState(() => _statusFilter = 'out'),
                    ),
                    FilterChip(
                      label: const Text('Catalog', style: TextStyle(fontSize: 11.5)),
                      selected: _includeCatalogDefaults,
                      selectedColor: const Color(0xFFFCE4EC),
                      checkmarkColor: const Color(0xFFA0003A),
                      onSelected: (v) => setState(() => _includeCatalogDefaults = v),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA0003A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _showAddOrEditOpeningDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('Opening Stock जोड़ें'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () => _confirmResetStock(context),
                      icon: const Icon(Icons.restart_alt_rounded, size: 17),
                      label: const Text('Reset 0'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Stock Table / Responsive List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'कोई स्टॉक आइटम नहीं मिला',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'खरीद बिल या सेल बिल जोड़ें, या ऊपर से Opening Stock सेट करें।',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 720) {
                        return ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _buildMobileStockCard(ctx, filtered[i]),
                        );
                      }
                      return _buildDesktopStockTable(context, filtered);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStockTable(BuildContext context, List<StockItemSummary> items) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'आइटम (Item Name & HSN)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Unit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Opening',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'आया (Purchased)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA0003A),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'बिका (Sold)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC2185B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'उपलब्ध (Available)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A0A10),
                    ),
                  ),
                ),
                SizedBox(width: 90),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = items[i];
                final badgeColor = item.isOutOfStock
                    ? const Color(0xFFDC2626)
                    : item.isLowStock
                        ? const Color(0xFFD97706)
                        : const Color(0xFFA0003A);
                final badgeBg = item.isOutOfStock
                    ? const Color(0xFFFEE2E2)
                    : item.isLowStock
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFCE4EC);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A0A10),
                              ),
                            ),
                            if (item.hsn.isNotEmpty)
                              Text(
                                'HSN: ${item.hsn}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            const SizedBox(height: 5),
                            // ── Progress Bar ──────────────────────────────
                            Builder(builder: (_) {
                              final total = item.totalInQty;
                              final ratio = total > 0
                                  ? (item.availableQty / total).clamp(0.0, 1.0)
                                  : 0.0;
                              final barColor = ratio > 0.5
                                  ? const Color(0xFF10B981)
                                  : ratio > 0.1
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFDC2626);
                              return LayoutBuilder(builder: (ctx, bc) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 5,
                                      width: bc.maxWidth * 0.85,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: FractionallySizedBox(
                                        widthFactor: ratio,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (item.isOutOfStock || item.isLowStock)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          item.isOutOfStock ? '⚠ स्टॉक खत्म' : '⚠ कम स्टॉक',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: barColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              });
                            }),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item.unit,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatQty(item.openingQty),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '+${_formatQty(item.purchasedQty)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA0003A),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '-${_formatQty(item.soldQty)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC2185B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_formatQty(item.availableQty)} ${item.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Opening Stock एडिट करें',
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () =>
                                _showAddOrEditOpeningDialog(context, existing: item),
                          ),
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

  Widget _buildMobileStockCard(BuildContext context, StockItemSummary item) {
    final badgeColor = item.isOutOfStock
        ? const Color(0xFFDC2626)
        : item.isLowStock
            ? const Color(0xFFD97706)
            : const Color(0xFFA0003A);
    final badgeBg = item.isOutOfStock
        ? const Color(0xFFFEE2E2)
        : item.isLowStock
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFCE4EC);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A0A10),
                      ),
                    ),
                    if (item.hsn.isNotEmpty)
                      Text(
                        'HSN: ${item.hsn} • ${item.unit}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'उपलब्ध: ${_formatQty(item.availableQty)} ${item.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                onPressed: () => _showAddOrEditOpeningDialog(context, existing: item),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Opening: ${_formatQty(item.openingQty)}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              Text(
                'आया: +${_formatQty(item.purchasedQty)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA0003A),
                ),
              ),
              Text(
                'बिका: -${_formatQty(item.soldQty)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC2185B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StockKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
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
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A0A10),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCE4EC) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFA0003A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? const Color(0xFF700028) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

