import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/receipt_provider.dart';
import '../services/invoice_pdf_service.dart';
import '../providers/license_provider.dart';
import '../services/update_service.dart';
import '../utils/number_to_words.dart';
import '../config/update_config.dart';
import '../widgets/invoice_form_panel.dart';
import '../widgets/invoice_preview_sheet.dart';
import '../widgets/license_lock_screen.dart';
import '../widgets/save_invoice_dialog.dart';
import '../widgets/saved_bills_view.dart';
import '../widgets/app_settings_dialog.dart';
import '../widgets/update_dialog.dart';
import 'mobile_bills_screen.dart';
import 'purchase_list_screen.dart';
import 'receipt_voucher_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _forceDesktopMode;
  bool _hasCheckedStartupUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkStartupUpdate();
  }

  Future<void> _checkStartupUpdate() async {
    if (_hasCheckedStartupUpdate) return;
    _hasCheckedStartupUpdate = true;
    final info = await UpdateService.checkForUpdate();
    if (!mounted) return;
    if (info.hasUpdate && context.read<LicenseProvider>().isLicensed) {
      UpdateDialog.show(context);
    }
  }

  bool _isMobileView(BoxConstraints constraints) {
    if (_forceDesktopMode != null) {
      return !_forceDesktopMode!;
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return true;
    }
    return constraints.maxWidth < 900;
  }

  @override
  Widget build(BuildContext context) {
    // 1. License Verification: Check if license is active
    final license = context.watch<LicenseProvider>();

    if (license.isLoading && license.lastChecked == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF00A86B),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'सॉफ्टवेयर लाइसेंस सत्यापित किया जा रहा है...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. If status is FALSE in Google Sheet (or not active), lock the entire app!
    if (!license.isLicensed) {
      return const LicenseLockScreen();
    }

    // 3. License is valid (TRUE) or cached offline valid -> Open App!
    final provider = context.watch<InvoiceProvider>();
    final invoice = provider.invoice;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isMobileView(constraints)) {
          return const MobileBillsScreen();
        }
        return _buildDesktopStudio(context, provider, invoice, constraints);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP STUDIO (Clean, Zero-Overflow, Oripio-Inspired Professional Design)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopStudio(
    BuildContext context,
    InvoiceProvider provider,
    Invoice invoice,
    BoxConstraints constraints,
  ) {
    final totalInvoiced = provider.savedInvoices.fold(
      0.0,
      (sum, inv) => sum + inv.grandTotal,
    );
    final displayBalance = totalInvoiced > 0 ? totalInvoiced : invoice.grandTotal;
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _handleSave(context, provider);
        },
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          _handlePrint(context, invoice);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sleek, Compact Top Navbar (Small size, zero overflow)
              _buildCompactTopNavBar(context, provider, invoice, formattedDate),

              // Full-Width Main Workspace
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: provider.viewMode == 'records'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // In Dashboard view, show the 3 summary metrics cards
                            _buildDashboardKpiRow(context, provider, invoice, displayBalance),
                            const SizedBox(height: 16),
                            // Followed by the full Bills table
                            Expanded(child: _buildDesktopContent(provider, invoice)),
                          ],
                        )
                      : _buildDesktopContent(provider, invoice),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. BOOTSTRAP-STYLE SINGLE-ROW TOP NAVBAR (Zero Horizontal Scroll + Dropdown)
  // ---------------------------------------------------------------------------
  Widget _buildCompactTopNavBar(
    BuildContext context,
    InvoiceProvider provider,
    Invoice invoice,
    String formattedDate,
  ) {
    final receiptsCount = context.watch<ReceiptProvider>().savedReceipts.length;
    final purchasesCount = context.watch<PurchaseProvider>().savedPurchases.length;

    // Determine dropdown label based on active viewMode
    final bool isDropdownViewActive = provider.viewMode == 'split' ||
        provider.viewMode == 'preview' ||
        provider.viewMode == 'receipts' ||
        provider.viewMode == 'purchases';

    String dropdownLabel = 'मेनू / Views';
    IconData dropdownIcon = Icons.grid_view_rounded;
    if (provider.viewMode == 'split') {
      dropdownLabel = 'स्प्लिट व्यू (Split View)';
      dropdownIcon = Icons.view_column_rounded;
    } else if (provider.viewMode == 'preview') {
      dropdownLabel = 'A4 बिल देखें (Preview)';
      dropdownIcon = Icons.receipt_long_rounded;
    } else if (provider.viewMode == 'receipts') {
      dropdownLabel = 'रसीद (Receipts)';
      dropdownIcon = Icons.receipt_rounded;
    } else if (provider.viewMode == 'purchases') {
      dropdownLabel = 'खरीद बिल (Purchases)';
      dropdownIcon = Icons.shopping_bag_rounded;
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 1040;
            final isVeryCompact = constraints.maxWidth < 860;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. LEFT SECTION: Primary Tabs + Dropdown Menu
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tab 1: डैशबोर्ड (All Bills)
                      _buildTopNavItem(
                        icon: Icons.dashboard_rounded,
                        label: isCompact ? 'डैशबोर्ड' : 'डैशबोर्ड (All Bills)',
                        isSelected: provider.viewMode == 'records',
                        badgeCount: provider.savedInvoices.isNotEmpty
                            ? provider.savedInvoices.length
                            : null,
                        onTap: () => provider.setViewMode('records'),
                      ),
                      const SizedBox(width: 6),

                      // Tab 2: बिल बनाएं (Form)
                      _buildTopNavItem(
                        icon: Icons.edit_note_rounded,
                        label: isCompact ? 'बिल बनाएं' : 'बिल बनाएं (Form)',
                        isSelected: provider.viewMode == 'form',
                        onTap: () => provider.setViewMode('form'),
                      ),
                      const SizedBox(width: 6),

                      // Dropdown Menu: मेनू / Views ▼
                      PopupMenuButton<String>(
                        tooltip: 'अन्य विकल्प (More Views & Tools)',
                        offset: const Offset(0, 44),
                        elevation: 6,
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'split':
                            case 'preview':
                            case 'receipts':
                            case 'purchases':
                              provider.setViewMode(value);
                              break;
                            case 'add_customer':
                              provider.resetToNew();
                              provider.setViewMode('form');
                              break;
                            case 'settings':
                              AppSettingsDialog.show(context);
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          _buildDropdownItem(
                            value: 'split',
                            icon: Icons.view_column_rounded,
                            label: 'स्प्लिट व्यू (Split View)',
                            isSelected: provider.viewMode == 'split',
                          ),
                          _buildDropdownItem(
                            value: 'preview',
                            icon: Icons.receipt_long_rounded,
                            label: 'A4 बिल देखें (Preview)',
                            isSelected: provider.viewMode == 'preview',
                          ),
                          _buildDropdownItem(
                            value: 'receipts',
                            icon: Icons.receipt_rounded,
                            label: 'रसीद (Receipts)',
                            isSelected: provider.viewMode == 'receipts',
                            badgeCount: receiptsCount > 0 ? receiptsCount : null,
                          ),
                          _buildDropdownItem(
                            value: 'purchases',
                            icon: Icons.shopping_bag_rounded,
                            label: 'खरीद बिल (Purchases)',
                            isSelected: provider.viewMode == 'purchases',
                            badgeCount: purchasesCount > 0 ? purchasesCount : null,
                          ),
                          const PopupMenuDivider(height: 8),
                          const PopupMenuItem<String>(
                            value: 'add_customer',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(Icons.person_add_rounded, size: 17, color: Color(0xFF00A86B)),
                                SizedBox(width: 10),
                                Text(
                                  '+ नया ग्राहक (Add Customer)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00A86B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'settings',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(Icons.settings_outlined, size: 17, color: Color(0xFF475569)),
                                SizedBox(width: 10),
                                Text(
                                  'सेटिंग्स (v${UpdateConfig.currentVersion})',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDropdownViewActive
                                ? Colors.green.shade50
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDropdownViewActive
                                  ? const Color(0xFF00A86B)
                                  : const Color(0xFFE2E8F0),
                              width: isDropdownViewActive ? 1.2 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                dropdownIcon,
                                size: 15,
                                color: isDropdownViewActive
                                    ? Colors.green.shade800
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dropdownLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isDropdownViewActive
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isDropdownViewActive
                                      ? Colors.green.shade800
                                      : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 17,
                                color: isDropdownViewActive
                                    ? Colors.green.shade800
                                    : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // 2. RIGHT SECTION: Compact Status Pill + Save Bill + Print / PDF
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Synced Status Pill
                    InkWell(
                      onTap: (provider.isLoading || provider.isSyncing)
                          ? null
                          : () => provider.refreshInvoices(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isVeryCompact ? 8 : 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: provider.pendingSyncCount > 0
                              ? const Color(0xFFFEF3C7)
                              : (provider.isFirebaseConfigured
                                  ? Colors.green.shade50
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: provider.pendingSyncCount > 0
                                ? const Color(0xFFFCD34D)
                                : (provider.isFirebaseConfigured
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (provider.isSyncing)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: Color(0xFF00A86B),
                                ),
                              )
                            else
                              Icon(
                                provider.pendingSyncCount > 0
                                    ? Icons.cloud_queue_rounded
                                    : (provider.isFirebaseConfigured
                                        ? Icons.cloud_done_rounded
                                        : Icons.storage_rounded),
                                size: 13.5,
                                color: provider.pendingSyncCount > 0
                                    ? const Color(0xFFD97706)
                                    : (provider.isFirebaseConfigured
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B)),
                              ),
                            if (!isVeryCompact) ...[
                              const SizedBox(width: 5),
                              Text(
                                provider.isSyncing
                                    ? 'Syncing...'
                                    : (provider.pendingSyncCount > 0
                                        ? '${provider.pendingSyncCount} Offline'
                                        : (provider.isFirebaseConfigured ? 'Synced' : 'Offline')),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: provider.pendingSyncCount > 0
                                      ? const Color(0xFFB45309)
                                      : (provider.isFirebaseConfigured
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Save Bill Button (Emerald Green)
                    ElevatedButton.icon(
                      onPressed: () => _handleSave(context, provider),
                      icon: const Icon(Icons.save_rounded, size: 15, color: Colors.white),
                      label: Text(
                        isVeryCompact ? 'Save' : 'Save Bill',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        minimumSize: const Size(0, 34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Print / PDF Button (Dark Slate)
                    ElevatedButton.icon(
                      onPressed: () => _handlePrint(context, invoice),
                      icon: const Icon(Icons.print_rounded, size: 15, color: Colors.white),
                      label: Text(
                        isVeryCompact ? 'PDF' : 'Print / PDF',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        minimumSize: const Size(0, 34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildDropdownItem({
    required String value,
    required IconData icon,
    required String label,
    required bool isSelected,
    int? badgeCount,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.green.shade800 : const Color(0xFF475569),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.green.shade800 : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00A86B) : const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF00A86B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A86B) : Colors.transparent,
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.green.shade800 : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.green.shade800 : const Color(0xFF475569),
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00A86B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. DASHBOARD KPI CARDS (Only shown on Dashboard/All Bills view)
  // ---------------------------------------------------------------------------
  Widget _buildDashboardKpiRow(
    BuildContext context,
    InvoiceProvider provider,
    Invoice invoice,
    double displayBalance,
  ) {
    return Row(
      children: [
        // CARD 1: Total Sales
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF00A86B)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Total Invoiced Sales', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹ ${NumberToWords.formatCurrency(displayBalance)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text('All saved customer bills', style: TextStyle(fontSize: 10.5, color: Color(0xFF00A86B), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // CARD 2: Total GST Tax
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_outlined, size: 16, color: Color(0xFF4F46E5)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Total GST Output', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹ ${NumberToWords.formatCurrency(invoice.totalTaxAmount)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.taxMode == TaxMode.cgstSgst ? 'CGST + SGST (Intra-State)' : 'IGST (Inter-State)',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // CARD 3: Total Saved Bills
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_shared_outlined, size: 16, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Saved Bills Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${provider.savedInvoices.length} Bills',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.isFirebaseConfigured ? '● Cloud Synced' : '● Local Storage',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF00A86B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. MAIN WORKSPACE (Form, Split, Preview, or Dashboard)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopContent(InvoiceProvider provider, Invoice invoice) {
    final mode = provider.viewMode;

    switch (mode) {
      case 'records':
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EAE8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: const SavedBillsView(),
        );

      case 'receipts':
        return const ReceiptVoucherScreen();

      case 'purchases':
        return const PurchaseListScreen();

      case 'form':
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EAE8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: const InvoiceFormPanel(),
        );

      case 'preview':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Transform.scale(
                scale: provider.zoomLevel,
                alignment: Alignment.topCenter,
                child: InvoicePreviewSheet(invoice: invoice),
              ),
            ),
          ),
        );

      case 'split':
      default:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Form Editor Panel (Generous form width)
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5EAE8)),
                ),
                clipBehavior: Clip.antiAlias,
                child: const InvoiceFormPanel(),
              ),
            ),
            const SizedBox(width: 14),

            // Right: Live A4 Sheet Preview Desk
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                    child: Transform.scale(
                      scale: provider.zoomLevel,
                      alignment: Alignment.topCenter,
                      child: InvoicePreviewSheet(invoice: invoice),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  void _handleSave(BuildContext context, InvoiceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => const SaveInvoiceDialog(openPreviewAfterSave: false),
    );
  }

  void _handlePrint(BuildContext context, Invoice invoice) async {
    try {
      await InvoicePdfService.printOrSave(invoice);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF / Print: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
