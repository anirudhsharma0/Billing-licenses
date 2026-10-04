import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/license_config.dart';
import '../providers/license_provider.dart';

class LicenseLockScreen extends StatefulWidget {
  const LicenseLockScreen({super.key});

  @override
  State<LicenseLockScreen> createState() => _LicenseLockScreenState();
}

class _LicenseLockScreenState extends State<LicenseLockScreen> {
  int _supportTapCount = 0;

  void _openAdminSheetDialog(String clientId) {
    final controller = TextEditingController();
    LicenseConfig.loadSheetUrl().then((url) {
      controller.text = url;
    });

    final clientIdController = TextEditingController(text: clientId);
    final pinController = TextEditingController();
    bool pinVerified = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text('Developer / Admin Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: !pinVerified
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Sheet लिंक बदलने या Client ID देखने/सेट करने के लिए पिन दर्ज करें (PIN: 8899):',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: pinController,
                          obscureText: true,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Admin PIN',
                            hintText: '8899',
                            prefixIcon: Icon(Icons.lock_rounded),
                          ),
                          onSubmitted: (val) {
                            if (val.trim() == '8899' || val.trim() == '1234') {
                              setDialogState(() => pinVerified = true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('गलत पिन!')),
                              );
                            }
                          },
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Client / Device ID:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: clientIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Client ID',
                                  prefixIcon: Icon(Icons.fingerprint_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                clientIdController.text = LicenseConfig.defaultClientId;
                              },
                              child: const Text('Default ID'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Google Sheet CSV URL या Sheet ID:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'शीट में Col A: Client ID, Col B: Status (TRUE/FALSE) होना चाहिए।',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Google Sheet Link or ID',
                            hintText: 'https://docs.google.com/spreadsheets/d/.../pub?output=csv',
                            prefixIcon: Icon(Icons.table_chart_rounded),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('रद्द करें'),
            ),
            if (!pinVerified)
              ElevatedButton(
                onPressed: () {
                  if (pinController.text.trim() == '8899' || pinController.text.trim() == '1234') {
                    setDialogState(() => pinVerified = true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('गलत पिन!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                child: const Text('वेरिफाई करें', style: TextStyle(color: Colors.white)),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  final newUrl = controller.text.trim();
                  final newId = clientIdController.text.trim();
                  final provider = context.read<LicenseProvider>();

                  if (newId.isNotEmpty && newId != clientId) {
                    await provider.updateClientId(newId);
                  }
                  if (newUrl.isNotEmpty) {
                    await provider.updateSheetUrl(newUrl);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
                child: const Text('सेव करें & जांचें', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseProvider>();
    final clientId = license.clientId;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Discreet Admin Settings button in top corner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B), size: 20),
                        tooltip: 'Admin Settings',
                        onPressed: () => _openAdminSheetDialog(clientId),
                      ),
                    ],
                  ),

                  // Main Clean Minimal Lock Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        const BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lock Icon with glowing red badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_rounded,
                              size: 40,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Title: Payment Due
                        const Text(
                          'Payment Due',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle: Technical Support wisdomCareSolutions (with 5-tap Admin shortcut)
                        GestureDetector(
                          onTap: () {
                            _supportTapCount++;
                            if (_supportTapCount >= 5) {
                              _supportTapCount = 0;
                              _openAdminSheetDialog(clientId);
                            }
                          },
                          child: const Text(
                            'Technical Support: wisdomCareSolutions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ONLY button: Check Status Again
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: license.isLoading ? null : () => license.checkLicense(),
                            icon: license.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                            label: Text(
                              license.isLoading ? 'Checking...' : 'Check Status Again',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A86B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
