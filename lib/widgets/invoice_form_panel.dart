import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../utils/number_to_words.dart';
import 'save_invoice_dialog.dart';

class InvoiceFormPanel extends StatefulWidget {
  const InvoiceFormPanel({super.key});

  @override
  State<InvoiceFormPanel> createState() => _InvoiceFormPanelState();
}

class _InvoiceFormPanelState extends State<InvoiceFormPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _sameAsBuyer = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final prov = context.read<InvoiceProvider>();
        if (prov.selectedFormTab != _tabController.index) {
          prov.setSelectedFormTab(_tabController.index);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prov = context.watch<InvoiceProvider>();
    if (_tabController.index != prov.selectedFormTab) {
      _tabController.animateTo(prov.selectedFormTab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final invoice = provider.invoice;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Full-Width 4-Step Form Navigation (No cutoffs, No "4. Sel" bug)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: const Color(0xFF00A86B),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF00A86B),
              indicatorWeight: 3.5,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                const Tab(
                  icon: Icon(Icons.person_pin_rounded, size: 20),
                  text: '1. ग्राहक (Buyer)',
                ),
                Tab(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  text: '2. सामान (${invoice.items.length})',
                ),
                const Tab(
                  icon: Icon(Icons.receipt_long_outlined, size: 20),
                  text: '3. बिल विवरण (Meta)',
                ),
                const Tab(
                  icon: Icon(Icons.account_balance_outlined, size: 20),
                  text: '4. बैंक (Seller/Bank)',
                ),
              ],
            ),
          ),

          // 3. Spacious Form Workspace Body (Clean Form Design)
          Expanded(
            child: TabBarView(
              key: ValueKey(provider.editSessionId),
              controller: _tabController,
              children: [
                _buildBuyerConsigneeTab(context, provider, invoice),
                _buildItemsTab(context, provider, invoice),
                _buildInvoiceMetaTab(context, provider, invoice),
                _buildSellerBankTab(context, provider, invoice),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: BUYER & CONSIGNEE DETAILS (Form View)
  // ---------------------------------------------------------------------------

  Widget _buildBuyerConsigneeTab(BuildContext context, InvoiceProvider provider, Invoice invoice) {
    final isTax = invoice.invoiceTitle.toUpperCase().contains('TAX');

    return ListView(
      key: ValueKey('buyer_tab_${provider.editSessionId}'),
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Bill Type Card (Proforma vs Tax Invoice)
        _buildFormCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                icon: isTax ? Icons.receipt_long_rounded : Icons.description_outlined,
                iconColor: isTax ? const Color(0xFF00A86B) : const Color(0xFF4F46E5),
                title: 'बिल का प्रकार (Invoice Document Type)',
                subtitle: isTax
                    ? 'पक्का जीएसटी बिल (TAX INVOICE - GST Compliant)'
                    : 'कोटेशन / कच्चा बिल (PROFORMA INVOICE)',
                trailing: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    selectedBackgroundColor: isTax ? const Color(0xFFE8F5EE) : const Color(0xFFEEF2FF),
                    selectedForegroundColor: isTax ? const Color(0xFF00A86B) : const Color(0xFF4F46E5),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'PROFORMA INVOICE',
                      icon: Icon(Icons.description_outlined, size: 16),
                      label: Text('Proforma (कच्चा)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'TAX INVOICE',
                      icon: Icon(Icons.receipt_long_rounded, size: 16),
                      label: Text('Tax Invoice (पक्का)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  selected: {isTax ? 'TAX INVOICE' : 'PROFORMA INVOICE'},
                  onSelectionChanged: (set) => provider.setInvoiceTitle(set.first),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF00A86B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'सोलर सिस्टम पैकेज (₹${NumberToWords.formatCurrency(invoice.grandTotal)}) व सोसाइटी बैंक विवरण सेट हैं। नीचे ग्राहक का नाम व पता दर्ज करें।',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Customer / Buyer Details Form Card
        _buildFormCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                icon: Icons.person_pin_rounded,
                iconColor: const Color(0xFF00A86B),
                title: 'ग्राहक का विवरण (Customer / Buyer Details)',
                subtitle: 'बिल प्राप्तकर्ता का नाम, पूरा पता और राज्य दर्ज करें',
                trailing: invoice.buyer.name.trim().isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF00A86B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF00A86B)),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                invoice.buyer.name.trim(),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A86B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Field 1: Customer Name
              _buildTextField(
                label: 'ग्राहक / फर्म का नाम (Buyer / Customer Name)',
                hintText: 'उदा. SATBIR SINGH S/O JAGDISH (श्री सतबीर सिंह)',
                initialValue: invoice.buyer.name,
                isRequired: true,
                onChanged: (val) {
                  final updated = invoice.buyer.copyWith(name: val);
                  if (_sameAsBuyer) {
                    provider.updateBuyerAndSyncConsignee(updated, syncConsignee: true);
                  } else {
                    provider.updateBuyer(updated);
                  }
                },
              ),
              const SizedBox(height: 18),

              // Field 2: Address (Spacious)
              _buildTextField(
                label: 'गाँव / पूरा बिलिंग पता (Billing Address / Village)',
                hintText: 'उदा. VPO SISHWAL TEHSIL MANDI ADAMPUR HISAR (गाँव सिशवाल, मंडी आदमपुर)',
                initialValue: invoice.buyer.address,
                isRequired: true,
                maxLines: 1,
                onChanged: (val) {
                  final updated = invoice.buyer.copyWith(address: val);
                  if (_sameAsBuyer) {
                    provider.updateBuyerAndSyncConsignee(updated, syncConsignee: true);
                  } else {
                    provider.updateBuyer(updated);
                  }
                },
              ),
              const SizedBox(height: 18),

              // Field 3 & 4: State Name & State Code (Side by Side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      label: 'राज्य का नाम (State Name)',
                      hintText: 'उदा. Haryana',
                      initialValue: invoice.buyer.state,
                      onChanged: (val) {
                        final updated = invoice.buyer.copyWith(state: val);
                        if (_sameAsBuyer) {
                          provider.updateBuyerAndSyncConsignee(updated, syncConsignee: true);
                        } else {
                          provider.updateBuyer(updated);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'स्टेट कोड (State Code)',
                      hintText: '06',
                      initialValue: invoice.buyer.stateCode,
                      onChanged: (val) {
                        final updated = invoice.buyer.copyWith(stateCode: val);
                        if (_sameAsBuyer) {
                          provider.updateBuyerAndSyncConsignee(updated, syncConsignee: true);
                        } else {
                          provider.updateBuyer(updated);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Field 5: Buyer GSTIN
              _buildTextField(
                label: 'ग्राहक GSTIN / UIN नंबर (वैकल्पिक / Optional)',
                hintText: 'उदा. 06ABCDE1234F1Z5 (यदि उपलब्ध हो)',
                initialValue: invoice.buyer.gstin,
                onChanged: (val) {
                  final updated = invoice.buyer.copyWith(gstin: val);
                  if (_sameAsBuyer) {
                    provider.updateBuyerAndSyncConsignee(updated, syncConsignee: true);
                  } else {
                    provider.updateBuyer(updated);
                  }
                },
              ),
            ],
          ),
        ),

        // 3. Consignee Same-As-Buyer Toggle Card
        _buildFormCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: _sameAsBuyer,
                activeColor: const Color(0xFF00A86B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  setState(() {
                    _sameAsBuyer = val ?? true;
                    if (_sameAsBuyer) {
                      provider.copyBuyerToConsignee();
                    }
                  });
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _sameAsBuyer = !_sameAsBuyer;
                      if (_sameAsBuyer) {
                        provider.copyBuyerToConsignee();
                      }
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'डिलीवरी भी इसी पते पर होगी (Delivery Address is same as Buyer)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _sameAsBuyer
                          ? '✓ ग्राहक का नाम व पता स्वतः डिलीवरी विवरण (Consignee) में कॉपी हो रहा है'
                          : 'अलग डिलीवरी पता भरने के लिए नीचे फ़ील्ड्स उपलब्ध हैं',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _sameAsBuyer ? const Color(0xFF00A86B) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. Separate Consignee Form Card (Only if _sameAsBuyer is false)
        if (!_sameAsBuyer) ...[
          _buildFormCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(
                  icon: Icons.local_shipping_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: 'डिलीवरी का विवरण (Consignee / Shipping Details)',
                  subtitle: 'यदि सामान किसी अन्य स्थान पर भेजा जाना है',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                _buildTextField(
                  label: 'प्राप्तकर्ता का नाम (Consignee Name)',
                  hintText: 'उदा. श्री सतबीर सिंह',
                  initialValue: invoice.consignee.name,
                  onChanged: (val) {
                    provider.updateConsignee(invoice.consignee.copyWith(name: val));
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'डिलीवरी का पूरा पता (Shipping Address)',
                  hintText: 'डिलीवरी का गाँव / कस्बा',
                  initialValue: invoice.consignee.address,
                  maxLines: 1,
                  onChanged: (val) {
                    provider.updateConsignee(invoice.consignee.copyWith(address: val));
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        label: 'राज्य (State Name)',
                        hintText: 'Haryana',
                        initialValue: invoice.consignee.state,
                        onChanged: (val) {
                          provider.updateConsignee(invoice.consignee.copyWith(state: val));
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        label: 'स्टेट कोड (State Code)',
                        hintText: '06',
                        initialValue: invoice.consignee.stateCode,
                        onChanged: (val) {
                          provider.updateConsignee(invoice.consignee.copyWith(stateCode: val));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Consignee GSTIN / UIN',
                  hintText: 'GSTIN (यदि उपलब्ध हो)',
                  initialValue: invoice.consignee.gstin,
                  onChanged: (val) {
                    provider.updateConsignee(invoice.consignee.copyWith(gstin: val));
                  },
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // 5. Friendly Step Navigation Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(1);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'सामान व दरें देखें (Next: Check Items & Rates ➔)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: ITEMS & PRICING (Form View)
  // ---------------------------------------------------------------------------
  Widget _buildItemsTab(BuildContext context, InvoiceProvider provider, Invoice invoice) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Items Header Banner
        _buildFormCard(
          padding: const EdgeInsets.all(18),
          child: _buildCardHeader(
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFF00A86B),
            title: 'बिल किए जाने वाले सामान (Bill Line Items)',
            subtitle: 'सोलर पैनल, मोटर पंप, स्ट्रक्चर व इंस्टॉलेशन दरें',
            trailing: ElevatedButton.icon(
              onPressed: () => provider.addItem(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('सामान जोड़ें (+ Item)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),

        // List of Item Form Cards
        ...invoice.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;

          return _buildFormCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00A86B).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'आइटम #${idx + 1}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00A86B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.description.isNotEmpty ? item.description : 'बिना नाम का सामान',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Duplicate
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Duplicate Item',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => provider.duplicateItem(idx),
                    ),
                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Item',
                      visualDensity: VisualDensity.compact,
                      onPressed: invoice.items.length > 1 ? () => provider.removeItem(idx) : null,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),

                // Description
                _buildTextField(
                  label: 'सामान या सेवा का नाम (Item Description)',
                  hintText: 'उदा. 10 HP Solar Monoblock Pumping System',
                  initialValue: item.description,
                  isRequired: true,
                  onChanged: (val) {
                    provider.updateItem(idx, item.copyWith(description: val));
                  },
                ),
                const SizedBox(height: 14),

                // Subtext / Specifications
                _buildTextField(
                  label: 'विस्तृत स्पेसिफिकेशन / विवरण (Specifications - Optional)',
                  hintText: 'तकनीकी विवरण जैसे 30 Nos 335W Solar Modules, Controller, Structure...',
                  initialValue: item.subtext,
                  maxLines: 1,
                  onChanged: (val) {
                    provider.updateItem(idx, item.copyWith(subtext: val));
                  },
                ),
                const SizedBox(height: 16),

                // 3 Columns: HSN, Quantity, Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        label: 'HSN / SAC कोड',
                        hintText: '8413',
                        initialValue: item.hsn,
                        onChanged: (val) {
                          provider.updateItem(idx, item.copyWith(hsn: val));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        label: 'मात्रा (Quantity)',
                        hintText: '1',
                        initialValue: item.quantity.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final q = double.tryParse(val) ?? 1;
                          provider.updateItem(idx, item.copyWith(quantity: q));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        label: 'इकाई (Unit)',
                        hintText: 'Set / Nos',
                        initialValue: item.unit,
                        onChanged: (val) {
                          provider.updateItem(idx, item.copyWith(unit: val));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2 Columns: Rate & GST Rate %
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildTextField(
                        label: 'दर / रेट प्रति यूनिट (Rate ₹)',
                        hintText: '320000',
                        initialValue: item.rate.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final r = double.tryParse(val) ?? 0;
                          provider.updateItem(idx, item.copyWith(rate: r));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildDropdownField<double>(
                        label: 'GST दर (GST Rate %)',
                        value: [0.0, 5.0, 12.0, 18.0, 28.0].contains(item.taxRate)
                            ? item.taxRate
                            : 18.0,
                        items: const [
                          DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                          DropdownMenuItem(value: 5.0, child: Text('5% GST')),
                          DropdownMenuItem(value: 12.0, child: Text('12% GST')),
                          DropdownMenuItem(value: 18.0, child: Text('18% GST')),
                          DropdownMenuItem(value: 28.0, child: Text('28% GST')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            provider.updateItem(idx, item.copyWith(taxRate: val));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Line Total Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'मात्रा: ${item.quantity} ${item.unit} × ₹${NumberToWords.formatCurrency(item.rate)} (${item.taxRate.toStringAsFixed(0)}% GST)',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'आइटम कुल: ${NumberToWords.formatWithSymbol(item.lineTotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Round Off Card
        _buildFormCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('राउंड ऑफ समायोजन (Round Off Adjustment)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A))),
                    const SizedBox(height: 3),
                    Text(
                      'स्वतः समायोजित: ${invoice.roundOff >= 0 ? "+" : ""}${invoice.roundOff.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: _buildTextField(
                  label: 'Round Off (₹)',
                  initialValue: invoice.roundOff.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (val) {
                    final ro = double.tryParse(val) ?? 0;
                    provider.setRoundOff(ro);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Stepper: Go to Tab 3
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(2);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'बिल नंबर व तारीख देखें (Next: Invoice Meta ➔)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: INVOICE META & DISPATCH (Form View)
  // ---------------------------------------------------------------------------
  Widget _buildInvoiceMetaTab(BuildContext context, InvoiceProvider provider, Invoice invoice) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Invoice Identification Card
        _buildFormCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF4F46E5),
                title: 'बिल की पहचान व प्रकार (Invoice Document Settings)',
                subtitle: 'बिल नंबर, दिनांक व टैक्स मोड सेट करें',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDropdownField<String>(
                      label: 'बिल का प्रकार (Document Title)',
                      value: ['PROFORMA INVOICE', 'TAX INVOICE', 'QUOTATION', 'DELIVERY CHALLAN'].contains(invoice.invoiceTitle.toUpperCase().trim())
                          ? invoice.invoiceTitle.toUpperCase().trim()
                          : 'PROFORMA INVOICE',
                      items: const [
                        DropdownMenuItem(value: 'PROFORMA INVOICE', child: Text('PROFORMA INVOICE (कच्चा बिल)')),
                        DropdownMenuItem(value: 'TAX INVOICE', child: Text('TAX INVOICE (पक्का बिल)')),
                        DropdownMenuItem(value: 'QUOTATION', child: Text('QUOTATION (कोटेशन)')),
                        DropdownMenuItem(value: 'DELIVERY CHALLAN', child: Text('DELIVERY CHALLAN')),
                      ],
                      onChanged: (val) {
                        if (val != null) provider.setInvoiceTitle(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: _buildDropdownField<TaxMode>(
                      label: 'GST टैक्स सिस्टम (Tax Mode)',
                      value: invoice.taxMode,
                      items: const [
                        DropdownMenuItem(value: TaxMode.cgstSgst, child: Text('Intra-State (CGST + SGST)')),
                        DropdownMenuItem(value: TaxMode.igst, child: Text('Inter-State (IGST)')),
                      ],
                      onChanged: (val) {
                        if (val != null) provider.setTaxMode(val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'बिल नंबर (Invoice No.)',
                      hintText: 'उदा. 01/2024-25',
                      initialValue: invoice.metadata.invoiceNo,
                      isRequired: true,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(invoiceNo: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'बिल दिनांक (Dated DD/MM/YYYY)',
                      hintText: 'DD/MM/YYYY',
                      initialValue: invoice.metadata.date,
                      isRequired: true,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(date: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'डिलीवरी नोट (Delivery Note)',
                      hintText: 'डिलीवरी नोट नंबर',
                      initialValue: invoice.metadata.deliveryNote,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(deliveryNote: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'डिलीवरी नोट दिनांक (Delivery Note Date)',
                      hintText: 'दिनांक',
                      initialValue: invoice.metadata.deliveryNoteDate,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(deliveryNoteDate: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'रेफरेंस नंबर (Reference No. & Date)',
                      hintText: 'ऑर्डर / कोटेशन रेफरेंस',
                      initialValue: invoice.metadata.referenceNo,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(referenceNo: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'अन्य संदर्भ (Other References)',
                      hintText: 'अन्य संदर्भ',
                      initialValue: invoice.metadata.otherReferences,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(otherReferences: val));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Dispatch & Logistics Card
        _buildFormCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFF0284C7),
                title: 'डिस्पैच व ट्रांसपोर्ट विवरण (Dispatch & Delivery Terms)',
                subtitle: 'ट्रांसपोर्टर, गंतव्य व भुगतान की शर्तें',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'गंतव्य स्थान (Destination Place)',
                      hintText: 'उदा. Mandi Adampur / Hisar',
                      initialValue: invoice.metadata.destination,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(destination: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'डिस्पैच डॉक नंबर (Dispatch Doc No.)',
                      hintText: 'बिल्टी / GR नंबर',
                      initialValue: invoice.metadata.dispatchDocNo,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(dispatchDocNo: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'ट्रांसपोर्टर का नाम (Dispatched Through)',
                      hintText: 'उदा. By Vehicle / Self Transport',
                      initialValue: invoice.metadata.dispatchedThrough,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(dispatchedThrough: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'भुगतान की शर्तें (Mode / Terms of Payment)',
                      hintText: 'उदा. 100% Against Delivery / Bank Transfer',
                      initialValue: invoice.metadata.paymentTerms,
                      onChanged: (val) {
                        provider.updateMetadata(invoice.metadata.copyWith(paymentTerms: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'डिलीवरी की शर्तें (Terms of Delivery)',
                hintText: 'उदा. F.O.R. Site Installation / Freight Paid',
                initialValue: invoice.metadata.termsOfDelivery,
                onChanged: (val) {
                  provider.updateMetadata(invoice.metadata.copyWith(termsOfDelivery: val));
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Stepper: Go to Tab 4
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(3);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'कंपनी व बैंक विवरण देखें (Next: Company & Bank ➔)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: SELLER PROFILE & BANK DETAILS (Form View)
  // ---------------------------------------------------------------------------
  Widget _buildSellerBankTab(BuildContext context, InvoiceProvider provider, Invoice invoice) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Seller / Company Information Card
        _buildFormCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                icon: Icons.business_rounded,
                iconColor: const Color(0xFF0F172A),
                title: 'कंपनी / फर्म की जानकारी (Seller Company Information)',
                subtitle: 'बिल जारी करने वाली संस्था का विवरण',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _buildTextField(
                label: 'कंपनी / फर्म का नाम (Company / Firm Name)',
                hintText: 'The Kishan Bharti Coop. M.P. Society Ltd.',
                initialValue: invoice.seller.name,
                isRequired: true,
                onChanged: (val) {
                  provider.updateSeller(invoice.seller.copyWith(name: val));
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'कंपनी का पूरा पता (Company Address)',
                hintText: 'पता, मंडी आदमपुर',
                initialValue: invoice.seller.address,
                isRequired: true,
                minLines: 2,
                maxLines: 3,
                onChanged: (val) {
                  provider.updateSeller(invoice.seller.copyWith(address: val));
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'कंपनी GSTIN नंबर (Company GSTIN)',
                      hintText: '06AAEAT5833H1ZE',
                      initialValue: invoice.seller.gstin,
                      isRequired: true,
                      onChanged: (val) {
                        provider.updateSeller(invoice.seller.copyWith(gstin: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'ईमेल पता (Email Address)',
                      hintText: 'info@kishanbharti.com',
                      initialValue: invoice.seller.email,
                      onChanged: (val) {
                        provider.updateSeller(invoice.seller.copyWith(email: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      label: 'राज्य (State Name)',
                      hintText: 'Haryana',
                      initialValue: invoice.seller.state,
                      onChanged: (val) {
                        provider.updateSeller(invoice.seller.copyWith(state: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'स्टेट कोड (State Code)',
                      hintText: '06',
                      initialValue: invoice.seller.stateCode,
                      onChanged: (val) {
                        provider.updateSeller(invoice.seller.copyWith(stateCode: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'कानूनी क्षेत्राधिकार (Legal Jurisdiction)',
                hintText: 'Hisar / मंडी आदमपुर',
                initialValue: invoice.seller.jurisdiction,
                onChanged: (val) {
                  provider.updateSeller(invoice.seller.copyWith(jurisdiction: val));
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'घोषणा पत्र (Legal Declaration Text)',
                hintText: 'बिल पर प्रिंट होने वाली कानूनी घोषणा',
                initialValue: invoice.seller.declaration,
                minLines: 2,
                maxLines: 3,
                onChanged: (val) {
                  provider.updateSeller(invoice.seller.copyWith(declaration: val));
                },
              ),
            ],
          ),
        ),

        // 2. Official Bank Settlement Details Card
        _buildFormCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                icon: Icons.account_balance_rounded,
                iconColor: const Color(0xFF00A86B),
                title: 'सोसायटी बैंक खाता विवरण (Official Bank Settlement Details)',
                subtitle: 'बिल पर प्रिंट होने वाले बैंक भुगतान विवरण',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _buildTextField(
                label: "खाता धारक का नाम (Account Holder's Name)",
                hintText: "THE KISHAN BHARTI COOP M P SOCIETY LTD",
                initialValue: invoice.bankDetails.holderName,
                onChanged: (val) {
                  provider.updateBankDetails(invoice.bankDetails.copyWith(holderName: val));
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'बैंक का नाम (Bank Name)',
                      hintText: 'State Bank of India',
                      initialValue: invoice.bankDetails.bankName,
                      onChanged: (val) {
                        provider.updateBankDetails(invoice.bankDetails.copyWith(bankName: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'खाता संख्या (Account Number)',
                      hintText: '30712959828',
                      initialValue: invoice.bankDetails.accountNo,
                      onChanged: (val) {
                        provider.updateBankDetails(invoice.bankDetails.copyWith(accountNo: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'IFSC कोड (IFSC Code)',
                      hintText: 'SBIN0001557',
                      initialValue: invoice.bankDetails.ifsc,
                      onChanged: (val) {
                        provider.updateBankDetails(invoice.bankDetails.copyWith(ifsc: val));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      label: 'शाखा का नाम (Branch Name)',
                      hintText: 'Mandi Adampur',
                      initialValue: invoice.bankDetails.branch,
                      onChanged: (val) {
                        provider.updateBankDetails(invoice.bankDetails.copyWith(branch: val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'SWIFT कोड (SWIFT Code - Optional)',
                hintText: 'वैकल्पिक',
                initialValue: invoice.bankDetails.swiftCode,
                onChanged: (val) {
                  provider.updateBankDetails(invoice.bankDetails.copyWith(swiftCode: val));
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Generate Bill Trigger Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              provider.generateBill();
            },
            icon: const Icon(Icons.bolt_rounded, size: 20),
            label: const Text(
              'बिल जनरेट करें व A4 शीट देखें ⚡ (Generate Bill & Preview)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A86B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BAR (Overflow-proof & Responsive)
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(BuildContext context, InvoiceProvider provider, Invoice invoice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: [
            // Quick Payable Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TOTAL PAYABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  NumberToWords.formatWithSymbol(invoice.grandTotal),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),

            // Next Customer quick button
            TextButton.icon(
              onPressed: () => provider.resetToNew(),
              icon: const Icon(Icons.person_add_rounded, size: 16, color: Color(0xFF00A86B)),
              label: const Text('+ Next Customer', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                backgroundColor: const Color(0xFFE8F5EE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),

            // Save with Name button
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const SaveInvoiceDialog(openPreviewAfterSave: false),
                );
              },
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('सेव करें (Save)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),

            // Generate Bill & Preview button (Gradient Indigo)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A86B), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.generateBill();
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 17, color: Colors.white),
                label: const Text(
                  'बिल जनरेट करें (Generate Bill) ⚡',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER REUSABLE FORM DESIGN SYSTEM WIDGETS
  // ---------------------------------------------------------------------------

  /// Standard Form Card Container
  Widget _buildFormCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 16),
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Card Header with Icon Box, Title, and Subtitle
  Widget _buildCardHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Prominent Field Label Above Input
  Widget _buildFieldLabel(String label, {bool isRequired = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              letterSpacing: -0.2,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
          if (hint != null) ...[
            const SizedBox(width: 6),
            Text(
              hint,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Spacious, High-Contrast Form Text Input
  Widget _buildTextField({
    required String label,
    String? hintText,
    String? initialValue,
    bool isRequired = false,
    int maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    Widget? prefixIcon,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          minLines: minLines ?? maxLines,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffix,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00A86B), width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Spacious Dropdown Field
  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00A86B), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
