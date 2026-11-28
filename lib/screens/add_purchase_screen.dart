import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/solar_purchase_catalog.dart';
import '../models/purchase_model.dart';
import '../providers/invoice_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/purchase_pdf_service.dart';
import '../utils/number_to_words.dart';

class AddPurchaseScreen extends StatefulWidget {
  final VoidCallback? onDone;

  const AddPurchaseScreen({super.key, this.onDone});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _supplierNameCtrl = TextEditingController();
  final _supplierGstinCtrl = TextEditingController();
  final _supplierAddressCtrl = TextEditingController();
  final _supplierStateCtrl = TextEditingController();
  final _supplierStateCodeCtrl = TextEditingController();

  final _invoiceNoCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _refNoCtrl = TextEditingController();
  final _ewayBillCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  final _roundOffCtrl = TextEditingController();

  String _lastSessionId = '';

  @override
  void dispose() {
    _supplierNameCtrl.dispose();
    _supplierGstinCtrl.dispose();
    _supplierAddressCtrl.dispose();
    _supplierStateCtrl.dispose();
    _supplierStateCodeCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _dateCtrl.dispose();
    _refNoCtrl.dispose();
    _ewayBillCtrl.dispose();
    _vehicleNoCtrl.dispose();
    _roundOffCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(PurchaseProvider provider) {
    if (_lastSessionId == provider.editSessionId) return;
    _lastSessionId = provider.editSessionId;
    final p = provider.currentPurchase;
    _supplierNameCtrl.text = p.supplier.name;
    _supplierGstinCtrl.text = p.supplier.gstin;
    _supplierAddressCtrl.text = p.supplier.address;
    _supplierStateCtrl.text = p.supplier.state;
    _supplierStateCodeCtrl.text = p.supplier.stateCode;
    _invoiceNoCtrl.text = p.metadata.invoiceNo;
    _dateCtrl.text = p.metadata.date;
    _refNoCtrl.text = p.metadata.referenceNo;
    _ewayBillCtrl.text = p.metadata.ewayBillNo;
    _vehicleNoCtrl.text = p.metadata.vehicleNo;
    _roundOffCtrl.text = p.roundOff == 0 ? '' : p.roundOff.toStringAsFixed(2);
  }

  Future<void> _pickDate(PurchaseProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      _dateCtrl.text = formatted;
      provider.updateCurrentPurchase(
        provider.currentPurchase.copyWith(
          metadata: provider.currentPurchase.metadata.copyWith(date: formatted),
        ),
      );
    }
  }

  Future<void> _handleSave(PurchaseProvider provider) async {
    final p = provider.currentPurchase;
    if (p.supplier.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया Supplier Name दर्ज करें।'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await provider.saveCurrentPurchase();
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isCloudSaved
                ? 'खरीद बिल सेव और Cloud Firestore पर सिंक हो गया!'
                : 'खरीद बिल डिवाइस पर ऑफलाइन सेव हो गया।',
          ),
          backgroundColor: const Color(0xFFA0003A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.onDone != null) {
        widget.onDone!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final buyerFirm = context.read<InvoiceProvider>().invoice.seller;
    _syncControllers(provider);
    final p = provider.currentPurchase;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A0A10)),
          onPressed: () {
            if (widget.onDone != null) {
              widget.onDone!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          p.id != null ? 'खरीद बिल एडिट करें' : 'नया खरीद बिल (Add Purchase Bill)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A0A10),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => PurchasePdfService.printOrSave(p, buyerFirm: buyerFirm),
            icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF1A0A10)),
            label: const Text('Print / PDF', style: TextStyle(color: Color(0xFF1A0A10))),
          ),
          const SizedBox(width: 8),
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
              p.id != null ? 'अपडेट करें' : 'सेव करें',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA0003A)),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Supplier Details + Invoice Metadata
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 780;
                    final supplierCard = _buildSupplierCard(provider, p);
                    final metaCard = _buildMetadataCard(provider, p);
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: supplierCard),
                          const SizedBox(width: 14),
                          Expanded(child: metaCard),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        supplierCard,
                        const SizedBox(height: 14),
                        metaCard,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. Dynamic Items Table
                _buildItemsCard(provider, p),
                const SizedBox(height: 16),

                // 3. Totals Summary Card
                _buildTotalsCard(provider, p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(PurchaseProvider provider, PurchaseBill p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.store_rounded, size: 18, color: Color(0xFFA0003A)),
                SizedBox(width: 8),
                Text(
                  'Supplier Details (विक्रेता विवरण)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ActionChip(
              avatar: const Icon(Icons.flash_on_rounded, size: 15, color: Color(0xFFA0003A)),
              label: const Text(
                'Fill: HAM SOLAR POWER PVT. LTD.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF700028),
                ),
              ),
              backgroundColor: const Color(0xFFFCE4EC),
              side: const BorderSide(color: Color(0xFFA7F3D0)),
              onPressed: () {
                const preset = SolarPurchaseCatalog.hamSolarSupplier;
                _supplierNameCtrl.text = preset.name;
                _supplierGstinCtrl.text = preset.gstin;
                _supplierAddressCtrl.text = preset.address;
                _supplierStateCtrl.text = preset.state;
                _supplierStateCodeCtrl.text = preset.stateCode;
                provider.updateCurrentPurchase(p.copyWith(supplier: preset));
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _supplierNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Supplier Name *',
                hintText: 'e.g. Ham Solar Power Pvt. Ltd.',
              ),
              onChanged: (v) => provider.updateCurrentPurchase(
                p.copyWith(supplier: p.supplier.copyWith(name: v)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _supplierGstinCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Supplier GSTIN'),
              onChanged: (v) => provider.updateCurrentPurchase(
                p.copyWith(supplier: p.supplier.copyWith(gstin: v)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _supplierAddressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
              onChanged: (v) => provider.updateCurrentPurchase(
                p.copyWith(supplier: p.supplier.copyWith(address: v)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _supplierStateCtrl,
                    decoration: const InputDecoration(labelText: 'State'),
                    onChanged: (v) => provider.updateCurrentPurchase(
                      p.copyWith(supplier: p.supplier.copyWith(state: v)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _supplierStateCodeCtrl,
                    decoration: const InputDecoration(labelText: 'State Code'),
                    onChanged: (v) => provider.updateCurrentPurchase(
                      p.copyWith(supplier: p.supplier.copyWith(stateCode: v)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(PurchaseProvider provider, PurchaseBill p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFFA0003A)),
                SizedBox(width: 8),
                Text(
                  'Invoice Metadata (बिल जानकारी)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _invoiceNoCtrl,
                    decoration: const InputDecoration(labelText: 'Purchase Invoice No.'),
                    onChanged: (v) => provider.updateCurrentPurchase(
                      p.copyWith(metadata: p.metadata.copyWith(invoiceNo: v)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Invoice Date',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today_rounded, size: 17),
                        onPressed: () => _pickDate(provider),
                      ),
                    ),
                    onChanged: (v) => provider.updateCurrentPurchase(
                      p.copyWith(metadata: p.metadata.copyWith(date: v)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _refNoCtrl,
              decoration: const InputDecoration(labelText: 'Reference No. (Optional)'),
              onChanged: (v) => provider.updateCurrentPurchase(
                p.copyWith(metadata: p.metadata.copyWith(referenceNo: v)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ewayBillCtrl,
                    decoration: const InputDecoration(labelText: 'e-Way Bill No. (Optional)'),
                    onChanged: (v) => provider.updateCurrentPurchase(
                      p.copyWith(metadata: p.metadata.copyWith(ewayBillNo: v)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _vehicleNoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Vehicle No. (Optional)'),
                    onChanged: (v) => provider.updateCurrentPurchase(
                      p.copyWith(metadata: p.metadata.copyWith(vehicleNo: v)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(PurchaseProvider provider, PurchaseBill p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Items (${p.items.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        provider.loadAllItems(SolarPurchaseCatalog.items);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('सभी 24 Solar Items लोड हो गए! अब आप Qty और Rate एडिट कर सकते हैं।'),
                            backgroundColor: Color(0xFFA0003A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.playlist_add_check_rounded, size: 17, color: Color(0xFFC2185B)),
                      label: const Text(
                        'Load All Solar Items (24)',
                        style: TextStyle(color: Color(0xFFC2185B), fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                        backgroundColor: const Color(0xFFEEF2FF),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => provider.addItem(),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      label: const Text('Add Item', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA0003A)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final tableContent = Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Fixed Table Header Row
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Row(
                          children: [
                            _TableHeaderCell(label: '#', width: 35, align: TextAlign.center),
                            Expanded(
                              flex: 4,
                              child: _TableHeaderCell(label: 'Item Description'),
                            ),
                            _TableHeaderCell(label: 'HSN/SAC', width: 95),
                            _TableHeaderCell(label: 'Qty', width: 70, align: TextAlign.right),
                            _TableHeaderCell(label: 'Unit', width: 80, align: TextAlign.center),
                            _TableHeaderCell(label: 'Rate (₹)', width: 95, align: TextAlign.right),
                            _TableHeaderCell(label: 'GST %', width: 75, align: TextAlign.center),
                            _TableHeaderCell(label: 'Total (₹)', width: 105, align: TextAlign.right),
                            _TableHeaderCell(label: '', width: 40, isLast: true),
                          ],
                        ),
                      ),
                      // Compact Editable Rows
                      ...List.generate(p.items.length, (index) {
                        final item = p.items[index];
                        return _PurchaseItemEditorRow(
                          key: ValueKey('${provider.editSessionId}_item_$index'),
                          index: index,
                          item: item,
                          canDelete: p.items.length > 1,
                          onChanged: (updated) => provider.updateItem(index, updated),
                          onDelete: () => provider.removeItem(index),
                        );
                      }),
                    ],
                  ),
                );

                if (constraints.maxWidth > 750) {
                  return tableContent;
                }

                // Mobile / narrow screen: horizontal scroll so spreadsheet stays aligned
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 860,
                    child: tableContent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(PurchaseProvider provider, PurchaseBill p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tax & Total Summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _summaryRow('Taxable Value', NumberToWords.formatWithSymbol(p.totalTaxableValue)),
            _summaryRow('CGST Input', NumberToWords.formatWithSymbol(p.totalCgstInput)),
            _summaryRow('SGST Input', NumberToWords.formatWithSymbol(p.totalSgstInput)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Round Off (+/-)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _roundOffCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(hintText: '0.00'),
                    onChanged: (v) {
                      final val = double.tryParse(v.trim()) ?? 0.0;
                      provider.updateCurrentPurchase(p.copyWith(roundOff: val));
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A0A10)),
                ),
                Text(
                  NumberToWords.formatWithSymbol(p.grandTotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFA0003A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String label;
  final double? width;
  final TextAlign align;
  final bool isLast;

  const _TableHeaderCell({
    required this.label,
    this.width,
    this.align = TextAlign.left,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : (align == TextAlign.center ? Alignment.center : Alignment.centerLeft),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A0A10),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return child;
  }
}

class _PurchaseItemEditorRow extends StatefulWidget {
  final int index;
  final PurchaseItem item;
  final bool canDelete;
  final ValueChanged<PurchaseItem> onChanged;
  final VoidCallback onDelete;

  const _PurchaseItemEditorRow({
    super.key,
    required this.index,
    required this.item,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_PurchaseItemEditorRow> createState() => _PurchaseItemEditorRowState();
}

class _PurchaseItemEditorRowState extends State<_PurchaseItemEditorRow> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _hsnCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _rateCtrl;
  final FocusNode _descFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _hsnCtrl = TextEditingController(text: widget.item.hsn);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _rateCtrl = TextEditingController(
      text: widget.item.rate == 0 ? '' : widget.item.rate.toString(),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _hsnCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _descFocusNode.dispose();
    super.dispose();
  }

  void _applyCatalogItem(PurchaseItem selected) {
    final currentQty = double.tryParse(_qtyCtrl.text.trim()) ?? widget.item.quantity;
    _descCtrl.text = selected.description;
    _hsnCtrl.text = selected.hsn;
    _rateCtrl.text = selected.rate.toStringAsFixed(2);
    widget.onChanged(
      selected.copyWith(quantity: currentQty > 0 ? currentQty : 1),
    );
  }

  Future<void> _openCatalogPicker() async {
    final picked = await showDialog<PurchaseItem>(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = SolarPurchaseCatalog.items.where((c) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase();
              return c.description.toLowerCase().contains(q) ||
                  c.hsn.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: const Text('Select Solar Item from Catalog'),
              content: SizedBox(
                width: 480,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search item or HSN...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setDialogState(() => query = v),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, idx) {
                          final c = filtered[idx];
                          return ListTile(
                            dense: true,
                            title: Text(
                              c.description,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              'HSN: ${c.hsn}  •  Unit: ${c.unit}  •  GST: ${c.gstRate.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            trailing: Text(
                              '₹${c.rate.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFA0003A),
                              ),
                            ),
                            onTap: () => Navigator.of(ctx).pop(c),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      _applyCatalogItem(picked);
    }
  }

  InputDecoration _cellDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFA0003A), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final unitValue = PurchaseItem.allowedUnits.contains(item.unit)
        ? item.unit
        : PurchaseItem.allowedUnits.first;
    final gstValue = PurchaseItem.allowedGstRates.contains(item.gstRate)
        ? item.gstRate
        : 18.0;

    final rowBg = widget.index.isEven ? Colors.white : Colors.grey.shade50;
    final borderColor = Colors.grey.shade300;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. # (35px)
            Container(
              width: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),

            // 2. Item Description (Expanded flex: 4 + Catalog Icon)
            Expanded(
              flex: 4,
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: borderColor)),
                ),
                child: RawAutocomplete<PurchaseItem>(
                  textEditingController: _descCtrl,
                  focusNode: _descFocusNode,
                  displayStringForOption: (opt) => opt.description,
                  optionsBuilder: (TextEditingValue textValue) {
                    final q = textValue.text.trim().toLowerCase();
                    if (q.isEmpty) return SolarPurchaseCatalog.items;
                    return SolarPurchaseCatalog.items.where((c) =>
                        c.description.toLowerCase().contains(q) ||
                        c.hsn.toLowerCase().contains(q));
                  },
                  onSelected: _applyCatalogItem,
                  fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      decoration: _cellDecoration(
                        hintText: 'Item name / search...',
                        suffixIcon: IconButton(
                          tooltip: 'Select from Catalog',
                          icon: const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFFC2185B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                          onPressed: _openCatalogPicker,
                        ),
                      ),
                      onChanged: (v) => widget.onChanged(item.copyWith(description: v)),
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 480),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final opt = options.elementAt(idx);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  opt.description,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                subtitle: Text(
                                  'HSN: ${opt.hsn} • ${opt.unit} • GST ${opt.gstRate.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 10.5),
                                ),
                                trailing: Text(
                                  '₹${opt.rate.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFA0003A),
                                    fontSize: 11.5,
                                  ),
                                ),
                                onTap: () => onSelected(opt),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. HSN/SAC (95px)
            Container(
              width: 95,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: TextFormField(
                controller: _hsnCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: _cellDecoration(hintText: 'HSN'),
                onChanged: (v) => widget.onChanged(item.copyWith(hsn: v)),
              ),
            ),

            // 4. Qty (70px)
            Container(
              width: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: TextFormField(
                controller: _qtyCtrl,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                decoration: _cellDecoration(hintText: '1'),
                onChanged: (v) {
                  final q = double.tryParse(v.trim()) ?? 0;
                  widget.onChanged(item.copyWith(quantity: q));
                },
              ),
            ),

            // 5. Unit (80px)
            Container(
              width: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: DropdownButtonFormField<String>(
                key: ValueKey('unit_${widget.index}_$unitValue'),
                initialValue: unitValue,
                isDense: true,
                isExpanded: true,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF1A0A10), fontWeight: FontWeight.w600),
                decoration: _cellDecoration(),
                items: PurchaseItem.allowedUnits
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) widget.onChanged(item.copyWith(unit: v));
                },
              ),
            ),

            // 6. Rate (₹) (95px)
            Container(
              width: 95,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: TextFormField(
                controller: _rateCtrl,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                decoration: _cellDecoration(hintText: '0.00'),
                onChanged: (v) {
                  final r = double.tryParse(v.trim()) ?? 0;
                  widget.onChanged(item.copyWith(rate: r));
                },
              ),
            ),

            // 7. GST % (75px)
            Container(
              width: 75,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: DropdownButtonFormField<double>(
                key: ValueKey('gst_${widget.index}_$gstValue'),
                initialValue: gstValue,
                isDense: true,
                isExpanded: true,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF1A0A10), fontWeight: FontWeight.w600),
                decoration: _cellDecoration(),
                items: PurchaseItem.allowedGstRates
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text('${g.toStringAsFixed(0)}%'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) widget.onChanged(item.copyWith(gstRate: v));
                },
              ),
            ),

            // 8. Total (₹) (105px - read-only including GST)
            Container(
              width: 105,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: Text(
                NumberToWords.formatCurrency(item.lineTotalWithGst),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A0A10),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 9. Action (40px - Delete icon)
            SizedBox(
              width: 40,
              child: widget.canDelete
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 17),
                      padding: EdgeInsets.zero,
                      tooltip: 'Remove item',
                      onPressed: widget.onDelete,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

