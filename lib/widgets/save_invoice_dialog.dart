import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../services/invoice_pdf_service.dart';
import '../utils/number_to_words.dart';

class SaveInvoiceDialog extends StatefulWidget {
  final bool openPreviewAfterSave;

  const SaveInvoiceDialog({
    super.key,
    this.openPreviewAfterSave = false,
  });

  @override
  State<SaveInvoiceDialog> createState() => _SaveInvoiceDialogState();
}

class _SaveInvoiceDialogState extends State<SaveInvoiceDialog> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _saveAsNew = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();
    final inv = provider.invoice;
    final initialName = inv.savedName.isNotEmpty
        ? inv.savedName
        : (inv.buyer.name.isNotEmpty
            ? inv.buyer.name
            : (inv.metadata.invoiceNo.isNotEmpty
                ? 'Bill #${inv.metadata.invoiceNo}'
                : ''));
    _nameController = TextEditingController(text: initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({required bool printBill}) async {
    final saveName = _nameController.text.trim();
    if (saveName.isEmpty) {
      setState(() {
        _errorMessage = 'कृपया ग्राहक या बिल का नाम दर्ज करें (Please enter customer/bill name)';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final provider = context.read<InvoiceProvider>();
    final result = await provider.saveCurrentInvoice(
      customSavedName: saveName,
      asNew: _saveAsNew,
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop(true);
      if (printBill) {
        await InvoicePdfService.printOrSave(result.invoice);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.isCloudSaved ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.isCloudSaved
                      ? '"$saveName" का बिल Firebase क्लाउड पर सुरक्षित हो गया!'
                      : '"$saveName" का बिल ऑफलाइन सुरक्षित हो गया! नेट ऑन होते ही अपने आप सिंक हो जाएगा।',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: result.isCloudSaved ? const Color(0xFF059669) : const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = 'बिल सुरक्षित करने में समस्या आई। पुनः प्रयास करें।';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final inv = provider.invoice;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF818CF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save Bill to Firebase Cloud',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'नाम से बिल सेव करें ताकि बाद में कभी भी देख सकें',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice quick recap card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inv.metadata.invoiceNo.isNotEmpty
                                    ? 'Invoice #${inv.metadata.invoiceNo}'
                                    : 'New Invoice',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Date: ${inv.metadata.date.isNotEmpty ? inv.metadata.date : "Today"} • ${inv.items.length} item(s)',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                            const Text(
                              'Grand Total',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              NumberToWords.formatWithSymbol(inv.grandTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Input
                  const Text(
                    'Bill / Customer Name (ग्राहक या बिल का नाम)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'उदा. Deepak Godara, Satbir Singh, Solar Project...',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF6366F1)),
                      errorText: _errorMessage,
                    ),
                    onSubmitted: (_) => _handleSave(printBill: false),
                  ),
                  const SizedBox(height: 12),

                  // If currently editing an existing saved bill, allow choosing New Bill vs Update
                  if (inv.id != null && inv.id!.isNotEmpty && inv.id != 'sample-inv-01') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'सेव करने का प्रकार (Save Mode):',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _saveAsNew,
                                activeColor: const Color(0xFF6366F1),
                                onChanged: (val) {
                                  setState(() {
                                    _saveAsNew = val ?? true;
                                  });
                                },
                              ),
                              const Text('नया बिल बनाएं (New Bill)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Radio<bool>(
                                value: false,
                                groupValue: _saveAsNew,
                                activeColor: const Color(0xFF6366F1),
                                onChanged: (val) {
                                  setState(() {
                                    _saveAsNew = val ?? false;
                                  });
                                },
                              ),
                              const Text('मौजूदा बिल अपडेट करें', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Firebase status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: provider.isFirebaseConfigured
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: provider.isFirebaseConfigured
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.isFirebaseConfigured
                              ? Icons.cloud_done_rounded
                              : Icons.info_outline_rounded,
                          size: 16,
                          color: provider.isFirebaseConfigured
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            provider.isFirebaseConfigured
                                ? 'Cloud Firestore Sync Active: बिल क्लाउड पर सुरक्षित रहेगा।'
                                : 'Local Storage Mode: Firebase Settings में क्रेडेंशियल्स दर्ज करके क्लाउड सिंक ऑन करें।',
                            style: TextStyle(
                              fontSize: 11,
                              color: provider.isFirebaseConfigured
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (Responsive Wrap so ZERO overflow occurs)
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('रद्द करें (Cancel)'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : () => _handleSave(printBill: false),
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('सेव करें (Save)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _handleSave(printBill: true),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                        label: Text(
                          _isSaving ? 'सेव हो रहा है...' : 'सेव करें & प्रिंट (Save & Print)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A86B),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
