import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/firebase_config.dart';
import '../providers/invoice_provider.dart';
import '../services/firebase_service.dart';

class FirebaseSettingsDialog extends StatefulWidget {
  const FirebaseSettingsDialog({super.key});

  @override
  State<FirebaseSettingsDialog> createState() => _FirebaseSettingsDialogState();
}

class _FirebaseSettingsDialogState extends State<FirebaseSettingsDialog> {
  final TextEditingController _projectIdController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isLoading = true;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final creds = await FirebaseConfig.loadCredentials();
    setState(() {
      _projectIdController.text = creds['projectId'] ?? '';
      _apiKeyController.text = creds['apiKey'] ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final pId = _projectIdController.text.trim();
    final aKey = _apiKeyController.text.trim();

    if (pId.isEmpty || aKey.isEmpty) {
      setState(() {
        _testResult = 'Please fill both Project ID and API Key.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final res = await FirebaseService.testConnection(
      projectId: pId,
      apiKey: aKey,
    );

    setState(() {
      _isTesting = false;
      _testSuccess = res['success'] == true;
      _testResult = res['message'] ?? '';
    });
  }

  Future<void> _saveConfig() async {
    final pId = _projectIdController.text.trim();
    final aKey = _apiKeyController.text.trim();

    await FirebaseConfig.saveCredentials(
      projectId: pId,
      apiKey: aKey,
    );

    if (!mounted) return;
    final provider = context.read<InvoiceProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await provider.checkFirebaseStatus();
    await provider.refreshInvoices();

    if (!mounted) return;
    nav.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          FirebaseConfig.isConfigured(pId, aKey)
              ? 'Firebase Firestore credentials saved & synced!'
              : 'Using Local Storage Mode.',
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final isConfigured = provider.isFirebaseConfigured;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 660),
        child: Column(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFFFBBF24), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Firebase Cloud Firestore Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Sync invoices securely with Google Cloud Firestore',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Status Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isConfigured ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isConfigured ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isConfigured ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                                color: isConfigured ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isConfigured
                                          ? 'Cloud Firestore is Active'
                                          : 'Local Storage Mode Active',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isConfigured ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isConfigured
                                          ? 'All invoices are automatically backed up to Cloud Firestore collection "invoices".'
                                          : 'Invoices are safely saved locally on this machine. Add your Firebase keys below to sync with Cloud.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isConfigured ? const Color(0xFF166534) : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Form Inputs
                        TextFormField(
                          controller: _projectIdController,
                          decoration: InputDecoration(
                            labelText: 'Firebase Project ID *',
                            hintText: 'e.g. billing-proforma-12345',
                            prefixIcon: const Icon(Icons.folder_special_outlined, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            labelText: 'Web API Key *',
                            hintText: 'e.g. AIzaSy...',
                            prefixIcon: const Icon(Icons.key_outlined, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Test Result feedback
                        if (_testResult != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _testSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _testSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _testSuccess ? Icons.check_circle : Icons.error_outline,
                                  color: _testSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _testResult!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _testSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Test button
                        OutlinedButton.icon(
                          onPressed: _isTesting ? null : _testConnection,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check_rounded, size: 16),
                          label: Text(_isTesting ? 'Testing connection...' : 'Test Firebase Connection'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Step-by-Step Guide toggle
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showGuide = !_showGuide;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                _showGuide ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                size: 20,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Kaise banayein Firebase Project? (Step-by-step)',
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_showGuide) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '1. console.firebase.google.com par jaayein aur "Add project" par click karein.\n'
                                  '2. Left menu me "Firestore Database" par click karein aur "Create Database" (Test Mode) select karein.\n'
                                  '3. Project Overview me Web icon (</>) par click karke web app register karein.\n'
                                  '4. Wahan se projectId aur apiKey copy karke upar paste karein aur "Save" par click karein!',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Save & Apply'),
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
