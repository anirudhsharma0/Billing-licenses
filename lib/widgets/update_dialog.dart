import 'dart:io';
import 'package:flutter/material.dart';
import '../config/update_config.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const UpdateDialog(),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isChecking = true;
  UpdateInfo? _info;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';
  File? _downloadedFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final info = await UpdateService.checkForUpdate();
    if (!mounted) return;

    setState(() {
      _info = info;
      _isChecking = false;
    });
  }

  Future<void> _startDownloadAndInstall() async {
    if (_info == null || _info!.downloadUrl.isEmpty) {
      setState(() {
        _errorMessage = 'डाउनलोड लिंक उपलब्ध नहीं है। कृपया GitHub Releases जांचें।';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatusText = 'डाउनलोड शुरू हो रहा है...';
      _errorMessage = null;
    });

    final file = await UpdateService.downloadUpdateFile(
      _info!.downloadUrl,
      onProgress: (progress, received, total) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
          final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = total > 0 ? (total / (1024 * 1024)).toStringAsFixed(1) : '?';
          final percent = (progress * 100).toInt();
          _downloadStatusText = '$percent% ($mbReceived MB / $mbTotal MB)';
        });
      },
    );

    if (!mounted) return;

    if (file != null && file.existsSync()) {
      setState(() {
        _downloadedFile = file;
        _isDownloading = false;
        _downloadStatusText = 'डाउनलोड पूर्ण! ऐप अपडेट किया जा रहा है...';
      });

      // Apply update and restart automatically
      await UpdateService.applyUpdate(file);
    } else {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'डाउनलोड करने में समस्या आई। कृपया इंटरनेट कनेक्शन जांचें।';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Icon and Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.system_update_rounded, color: Color(0xFF00A86B), size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'सॉफ्टवेयर अपडेट',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Billing App Software Update',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (!_isDownloading && !_isChecking)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Content State
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF00A86B)),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'नए अपडेट की जांच की जा रही है...',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else if (_info != null && !_info!.hasUpdate)
              // Up to date state
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
                    const SizedBox(height: 10),
                    const Text(
                      'आप पहले से ही नवीनतम वर्जन का उपयोग कर रहे हैं!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Version: v${UpdateConfig.currentVersion}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else if (_info != null && _info!.hasUpdate)
              // New update available state
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Version badge row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'वर्तमान: v${UpdateConfig.currentVersion}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2563EB)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'नया: v${_info!.latestVersion}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Release notes box
                  const Text(
                    'इस अपडेट में क्या नया है (What\'s New):',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Text(
                        _info!.releaseNotes.isNotEmpty
                            ? _info!.releaseNotes
                            : '• नए फीचर्स और बेहतर परफॉरमेंस\n• बग फिक्स और सुरक्षा सुधार',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar if Downloading
                  if (_isDownloading) ...[
                    LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _downloadStatusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00A86B)),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 16),

            // Action Buttons
            if (!_isChecking)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_info != null && _info!.hasUpdate && !_isDownloading)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('बाद में (Later)', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  const SizedBox(width: 8),
                  if (_info != null && _info!.hasUpdate)
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _startDownloadAndInstall,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: Text(
                        _isDownloading ? 'डाउनलोड हो रहा है...' : 'अपडेट करें (Download & Install)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('ठीक है (OK)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
