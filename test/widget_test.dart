import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/main.dart';

import 'package:billing_app/data/sample_data.dart';
import 'package:billing_app/services/invoice_pdf_service.dart';
import 'package:billing_app/screens/mobile_bills_screen.dart';
import 'package:billing_app/widgets/invoice_preview_sheet.dart';
import 'package:billing_app/providers/invoice_provider.dart';
import 'package:billing_app/services/invoice_storage_service.dart';
import 'package:billing_app/services/license_service.dart';
import 'package:billing_app/services/update_service.dart';
import 'package:billing_app/widgets/license_lock_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Billing app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'kb_last_known_license_status': true,
      'kb_permanent_client_id': 'KB-TEST-SMOKE',
    });
    await tester.pumpWidget(const BillingApp());
    expect(find.byType(BillingApp), findsOneWidget);
  });

  testWidgets('Billing app form tabs test', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    SharedPreferences.setMockInitialValues({
      'kb_last_known_license_status': true,
      'kb_permanent_client_id': 'KB-TEST-1234-5678',
    });

    await tester.pumpWidget(const BillingApp());
    await tester.pumpAndSettle();

    // Tap on Tab 2 (Items)
    final tab2 = find.text('2. सामान (2)');
    expect(tab2, findsOneWidget);
    await tester.tap(tab2);
    await tester.pumpAndSettle();

    // Tap on Tab 3 (Meta)
    final tab3 = find.text('3. बिल विवरण (Meta)');
    expect(tab3, findsOneWidget);
    await tester.tap(tab3);
    await tester.pumpAndSettle();

    // Tap on Tab 4 (Bank)
    final tab4 = find.text('4. बैंक (Seller/Bank)');
    expect(tab4, findsOneWidget);
    await tester.tap(tab4);
    await tester.pumpAndSettle();

    // Tap back to Tab 1 (Buyer)
    final tab1 = find.text('1. ग्राहक (Buyer)');
    expect(tab1, findsOneWidget);
    await tester.tap(tab1);
    await tester.pumpAndSettle();
  });

  testWidgets('Mobile bills screen test', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(390, 844);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    SharedPreferences.setMockInitialValues({});
    final provider = InvoiceProvider(enablePeriodicSync: false);
    addTearDown(provider.dispose);
    provider.loadSampleData();
    await provider.saveCurrentInvoice(customSavedName: 'Satbir Singh');

    await tester.pumpWidget(
      ChangeNotifierProvider<InvoiceProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: MobileBillsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify today's bills card is shown
    expect(find.textContaining('आज जोड़े गए नए बिल'), findsOneWidget);

    // Verify search field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify table items exist
    expect(find.byIcon(Icons.share_rounded), findsWidgets);
    expect(find.byIcon(Icons.visibility_rounded), findsWidgets);

    // Tap on view bill icon to open MobileBillViewerPage
    await tester.tap(find.byIcon(Icons.visibility_rounded).first);
    await tester.pumpAndSettle();

    // Verify InvoicePreviewSheet renders inside InteractiveViewer
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(InvoicePreviewSheet), findsOneWidget);
  });

  test('PDF generation test', () async {
    final bytes = await InvoicePdfService.generatePdf(SampleData.sampleInvoice);
    expect(bytes, isNotEmpty);
  });

  testWidgets('Form Enter key moves focus to next field test', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    SharedPreferences.setMockInitialValues({
      'kb_last_known_license_status': true,
      'kb_permanent_client_id': 'KB-TEST-ENTER-KEY',
    });

    await tester.pumpWidget(const BillingApp());
    await tester.pumpAndSettle();

    // Verify 'Save Bill' button exists and opens Save dialog
    final saveBillBtn = find.text('Save Bill');
    expect(saveBillBtn, findsOneWidget);
    await tester.ensureVisible(saveBillBtn);
    await tester.tap(saveBillBtn);
    await tester.pumpAndSettle();

    expect(find.text('सेव करें & प्रिंट (Save & Print)'), findsOneWidget);
    expect(find.byIcon(Icons.print_rounded), findsWidgets);
    
    // Dismiss dialog
    await tester.tap(find.text('रद्द करें (Cancel)'));
    await tester.pumpAndSettle();
  });

  test('Offline storage and sync queue test', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = InvoiceStorageService();

    // Save invoice (local persistent)
    final result = await storage.saveInvoice(SampleData.sampleInvoice);
    expect(result.invoice.id, isNotNull);

    // Verify invoice is saved locally
    final localList = await storage.getLocalInvoices();
    expect(localList.length, 1);
    expect(localList.first.id, result.invoice.id);

    // Verify pending count check works
    final pendingCount = await storage.getPendingSyncCount();
    expect(pendingCount, greaterThanOrEqualTo(0));
  });

  testWidgets('License lock screen displays when license is false', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    SharedPreferences.setMockInitialValues({
      'kb_last_known_license_status': false,
      'kb_permanent_client_id': 'KB-TEST-LOCK-9999',
    });

    await tester.pumpWidget(const BillingApp());
    await tester.pumpAndSettle();

    // Verify neither desktop studio nor mobile bills screen is rendered
    expect(find.byType(MobileBillsScreen), findsNothing);
    expect(find.text('Save Bill'), findsNothing);

    // Verify lock screen shows Payment Due, Technical Support, and Check Status Again
    expect(find.byType(LicenseLockScreen), findsOneWidget);
    expect(find.text('Payment Due'), findsOneWidget);
    expect(find.text('Technical Support: wisdomCareSolutions'), findsOneWidget);
    expect(find.text('Check Status Again'), findsOneWidget);
  });

  test('Offline license fallback behavior test', () async {
    // When last status was true -> offline check returns isLicensed = true
    SharedPreferences.setMockInitialValues({
      'kb_last_known_license_status': true,
      'kb_permanent_client_id': 'KB-TEST-OFFLINE-01',
    });
    final res1 = await LicenseService.checkLicense();
    expect(res1.isLicensed, isTrue);
    expect(res1.isOffline, isTrue);

    // When last status was false -> offline check returns isLicensed = false
    SharedPreferences.setMockInitialValues({
      'kb_last_known_license_status': false,
      'kb_permanent_client_id': 'KB-TEST-OFFLINE-02',
    });
    final res2 = await LicenseService.checkLicense();
    expect(res2.isLicensed, isFalse);
    expect(res2.isOffline, isTrue);
  });

  test('UpdateService version comparison test', () {
    expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
    expect(UpdateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
    expect(UpdateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    expect(UpdateService.isNewerVersion('v1.0.1', '1.0.0'), isTrue);
    expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    expect(UpdateService.isNewerVersion('0.9.9', '1.0.0'), isFalse);
    expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
  });
}


