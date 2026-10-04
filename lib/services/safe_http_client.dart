import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Global HttpOverrides to bypass CERTIFICATE_VERIFY_FAILED on client Windows PCs
/// where BoringSSL / OS lacks updated root CAs or an antivirus intercepts SSL.
class SafeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

/// Creates a safe http.Client that accepts certificates even if local issuer certs are missing
http.Client createSafeClient() {
  if (kIsWeb) {
    return http.Client();
  }
  final ioClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return IOClient(ioClient);
}
