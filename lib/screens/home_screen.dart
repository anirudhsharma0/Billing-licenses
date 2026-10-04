import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../services/invoice_pdf_service.dart';
import '../providers/license_provider.dart';
import '../utils/number_to_words.dart';
import '../config/update_config.dart';
import '../widgets/firebase_settings_dialog.dart';
import '../widgets/invoice_form_panel.dart';
import '../widgets/invoice_preview_sheet.dart';
import '../widgets/license_lock_screen.dart';
import '../widgets/save_invoice_dialog.dart';
import '../widgets/saved_bills_view.dart';
import '../widgets/update_dialog.dart';
import 'mobile_bills_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _forceDesktopMode;

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

    if (license.isLoading) {
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
  // 1. COMPACT TOP NAVIGATION BAR (Small Size, Zero-Overflow, Professional Header)
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 1. COMPACT TOP NAVIGATION BAR (All Options Visible On Screen)
  // ---------------------------------------------------------------------------
  Widget _buildCompactTopNavBar(
    BuildContext context,
    InvoiceProvider provider,
    Invoice invoice,
    String formattedDate,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width > 32
                  ? MediaQuery.of(context).size.width - 32
                  : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. LEFT: All 4 Main Navigation Tabs
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopNavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'डैशबोर्ड (All Bills)',
                        isSelected: provider.viewMode == 'records',
                        badgeCount: provider.savedInvoices.isNotEmpty ? provider.savedInvoices.length : null,
                        onTap: () => provider.setViewMode('records'),
                      ),
                      _buildTopNavItem(
                        icon: Icons.edit_note_rounded,
                        label: 'बिल बनाएं (Form)',
                        isSelected: provider.viewMode == 'form',
                        onTap: () => provider.setViewMode('form'),
                      ),
                      _buildTopNavItem(
                        icon: Icons.view_column_rounded,
                        label: 'स्प्लिट व्यू (Split View)',
                        isSelected: provider.viewMode == 'split',
                        onTap: () => provider.setViewMode('split'),
                      ),
                      _buildTopNavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'A4 बिल देखें (Preview)',
                        isSelected: provider.viewMode == 'preview',
                        onTap: () => provider.setViewMode('preview'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 2. RIGHT: Actions (All Options Directly Visible)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // + New Customer button
                    InkWell(
                      onTap: () {
                        provider.resetToNew();
                        provider.setViewMode('form');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_rounded, size: 14, color: Color(0xFF00A86B)),
                            SizedBox(width: 5),
                            Text(
                              '+ नया ग्राहक',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00A86B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Date Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cloud / Offline Sync Status Chip
                    InkWell(
                      onTap: (provider.isLoading || provider.isSyncing)
                          ? null
                          : () => provider.refreshInvoices(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: provider.pendingSyncCount > 0
                              ? const Color(0xFFFEF3C7)
                              : (provider.isFirebaseConfigured
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
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
                                width: 11,
                                height: 11,
                                child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF00A86B)),
                              )
                            else
                              Icon(
                                provider.pendingSyncCount > 0
                                    ? Icons.cloud_queue_rounded
                                    : (provider.isFirebaseConfigured
                                        ? Icons.cloud_done_rounded
                                        : Icons.storage_rounded),
                                size: 12.5,
                                color: provider.pendingSyncCount > 0
                                    ? const Color(0xFFD97706)
                                    : (provider.isFirebaseConfigured
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B)),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              provider.isSyncing
                                  ? 'Syncing...'
                                  : (provider.pendingSyncCount > 0
                                      ? '${provider.pendingSyncCount} Offline'
                                      : (provider.isFirebaseConfigured ? 'Synced' : 'Offline')),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: provider.pendingSyncCount > 0
                                    ? const Color(0xFFB45309)
                                    : (provider.isFirebaseConfigured
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Software Update / Version Chip
                    InkWell(
                      onTap: () => UpdateDialog.show(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.system_update_rounded, size: 12.5, color: Color(0xFF475569)),
                            SizedBox(width: 4),
                            Text(
                              'v${UpdateConfig.currentVersion}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Save Bill Button
                    ElevatedButton.icon(
                      onPressed: () => _handleSave(context, provider),
                      icon: const Icon(Icons.save_rounded, size: 14, color: Colors.white),
                      label: const Text('Save Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Print / PDF Button
                    ElevatedButton.icon(
                      onPressed: () => _handlePrint(context, invoice),
                      icon: const Icon(Icons.print_rounded, size: 14, color: Colors.white),
                      label: const Text('Print / PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF00A86B) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF00A86B) : const Color(0xFF475569),
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F5EE) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF00A86B) : const Color(0xFF475569),
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
