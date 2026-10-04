import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import '../models/invoice_model.dart';

class FirebaseService {
  /// Base URL builder for Cloud Firestore REST API
  static String _buildBaseUrl(String projectId) {
    return 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  }

  /// Test Firestore connection and verify credentials
  static Future<Map<String, dynamic>> testConnection({
    required String projectId,
    required String apiKey,
  }) async {
    final pId = projectId.trim();
    final aKey = apiKey.trim();

    if (pId.isEmpty) {
      return {
        'success': false,
        'message': 'Please provide a valid Project ID.',
      };
    }

    if (aKey.startsWith('1:') || aKey.contains(':web:')) {
      return {
        'success': false,
        'message':
            'Aapne App ID copy kar diya hai! Web API Key "AIzaSy..." se start hoti hai. Firebase Console > Project Settings > General me "Web API Key" copy karein.',
      };
    }

    try {
      final url = Uri.parse(
        aKey.isNotEmpty
            ? '${_buildBaseUrl(pId)}/invoices?key=$aKey&pageSize=1'
            : '${_buildBaseUrl(pId)}/invoices?pageSize=1',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connected to Cloud Firestore successfully!',
        };
      } else {
        final errJson = json.decode(response.body);
        final errMsg = errJson['error']?['message'] ?? response.body;
        if (response.statusCode == 403 || errMsg.toString().contains('PERMISSION_DENIED')) {
          return {
            'success': false,
            'message':
                'Permission Denied (403): Firestore Rules update karein! Firebase Console > Firestore Database > Rules tab me "allow read, write: if true;" likhkar Publish karein.',
          };
        }
        return {
          'success': false,
          'message': 'Connection error (${response.statusCode}): $errMsg',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Save or update an invoice in Cloud Firestore collection "invoices"
  static Future<bool> saveInvoice(Invoice invoice) async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return false; // Not configured, caller will fallback to local storage
    }

    try {
      final docId = invoice.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/invoices/$docId?key=$apiKey'
            : '${_buildBaseUrl(projectId)}/invoices/$docId',
      );

      final syncedInvoice = invoice.copyWith(isSynced: true);
      final payload = {
        'fields': {
          'id': {'stringValue': docId},
          'savedName': {'stringValue': syncedInvoice.displayName},
          'invoiceNo': {'stringValue': syncedInvoice.metadata.invoiceNo},
          'date': {'stringValue': syncedInvoice.metadata.date},
          'buyerName': {'stringValue': syncedInvoice.buyer.name},
          'grandTotal': {'doubleValue': syncedInvoice.grandTotal},
          'invoiceJson': {'stringValue': syncedInvoice.toJsonString()},
          'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
          'isSynced': {'booleanValue': true},
        }
      };

      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all invoices from Cloud Firestore collection "invoices"
  static Future<List<Invoice>> fetchAllInvoices() async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return [];
    }

    try {
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/invoices?key=$apiKey&pageSize=100'
            : '${_buildBaseUrl(projectId)}/invoices?pageSize=100',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final List<dynamic>? docs = data['documents'];
      if (docs == null) return [];

      final List<Invoice> invoices = [];
      for (final doc in docs) {
        final fields = doc['fields'];
        if (fields != null && fields['invoiceJson'] != null) {
          final jsonString = fields['invoiceJson']['stringValue'];
          if (jsonString != null) {
            final inv = Invoice.fromJsonString(jsonString);
            invoices.add(inv.copyWith(isSynced: true));
          }
        }
      }
      return invoices;
    } catch (_) {
      return [];
    }
  }

  /// Delete an invoice from Cloud Firestore
  static Future<bool> deleteInvoice(String docId) async {
    final creds = await FirebaseConfig.loadCredentials();
    final projectId = creds['projectId'] ?? '';
    final apiKey = creds['apiKey'] ?? '';

    if (!FirebaseConfig.isConfigured(projectId, apiKey)) {
      return false;
    }

    try {
      final url = Uri.parse(
        apiKey.isNotEmpty
            ? '${_buildBaseUrl(projectId)}/invoices/$docId?key=$apiKey'
            : '${_buildBaseUrl(projectId)}/invoices/$docId',
      );
      final response = await http.delete(url).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
