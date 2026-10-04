import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/agency_config.dart';
import '../providers/license_provider.dart';

class LicenseLockScreen extends StatelessWidget {
  const LicenseLockScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label कॉपी हो गया: $text'),
        backgroundColor: const Color(0xFF00A86B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
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
                      width: 76,
                      height: 76,
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
                          size: 38,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title: Payment Due
                    const Text(
                      'Payment Due',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle: Technical Support: wisdomCareSolutions
                    const Text(
                      'Technical Support: wisdomCareSolutions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact & Support Card (Prominently showing 9050524678)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.headset_mic_rounded, size: 15, color: Color(0xFF38BDF8)),
                              SizedBox(width: 6),
                              Text(
                                'Technical Support & Agency',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AgencyConfig.agencyName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Direct WhatsApp / Phone Call Box (Responsive FittedBox)
                          InkWell(
                            onTap: () => _copyToClipboard(context, AgencyConfig.phoneDisplay, 'फ़ोन नंबर'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone_in_talk_rounded, size: 16, color: Color(0xFF4ADE80)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Call / WhatsApp: ${AgencyConfig.phoneDisplay}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF4ADE80),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF86EFAC)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Email row (Responsive FittedBox)
                          InkWell(
                            onTap: () => _copyToClipboard(context, AgencyConfig.email, 'ईमेल'),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mail_outline_rounded, size: 13, color: Color(0xFFA78BFA)),
                                    const SizedBox(width: 5),
                                    Text(
                                      AgencyConfig.email,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFA78BFA),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ONLY Primary Action: Check Status Again
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
                            fontSize: 14,
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
            ),
          ),
        ),
      ),
    );
  }
}
