import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billing_app/models/invoice_model.dart';
import 'package:billing_app/models/purchase_model.dart';
import 'package:billing_app/providers/stock_provider.dart';

void main() {
  test('StockProvider starts at 0 from baseline, tracks new buy/sell, and removes deleted bills', () async {
    final baseline = DateTime.now().subtract(const Duration(minutes: 30));
    SharedPreferences.setMockInitialValues({
      'stock_baseline_at': baseline.toIso8601String(),
    });
    final stockProvider = StockProvider(initialBaseline: baseline);

    // Old bills before baseline must be ignored (stock starts at 0)
    final oldPurchase = PurchaseBill(
      id: 'old-p1',
      updatedAt: baseline.subtract(const Duration(days: 1)),
      items: const [
        PurchaseItem(description: 'Waaree Topcon 610 Wp Dcr', quantity: 50, unit: 'PCS'),
      ],
    );
    final oldInvoice = Invoice(
      id: 'old-i1',
      updatedAt: baseline.subtract(const Duration(hours: 2)),
      items: const [
        InvoiceItem(description: 'Waaree Topcon 610 Wp Dcr', quantity: 10, unit: 'PCS'),
      ],
    );

    final initialSummary = stockProvider.buildStockSummary(
      purchases: [oldPurchase],
      invoices: [oldInvoice],
      includeCatalogDefaults: false,
    );
    expect(initialSummary, isEmpty);

    // New purchase & new sale after baseline
    final newPurchase = PurchaseBill(
      id: 'new-p1',
      updatedAt: baseline.add(const Duration(minutes: 5)),
      items: const [
        PurchaseItem(
          description: 'Waaree Topcon 610 Wp Dcr',
          hsn: '85414300',
          quantity: 20,
          unit: 'PCS',
          rate: 15555,
        ),
      ],
    );
    final newInvoice = Invoice(
      id: 'new-i1',
      updatedAt: baseline.add(const Duration(minutes: 10)),
      items: const [
        InvoiceItem(
          description: 'waaree topcon 610 wp dcr',
          hsn: '85414300',
          quantity: 8,
          unit: 'PCS',
          rate: 18000,
        ),
      ],
    );

    final activeSummary = stockProvider.buildStockSummary(
      purchases: [oldPurchase, newPurchase],
      invoices: [oldInvoice, newInvoice],
      includeCatalogDefaults: false,
    );
    expect(activeSummary.length, 1);
    expect(activeSummary.first.purchasedQty, 20);
    expect(activeSummary.first.soldQty, 8);
    expect(activeSummary.first.availableQty, 12);

    // Deleting the sale invoice removes soldQty -> available becomes 20
    final afterDeleteSale = stockProvider.buildStockSummary(
      purchases: [oldPurchase, newPurchase],
      invoices: [oldInvoice],
      includeCatalogDefaults: false,
    );
    expect(afterDeleteSale.first.soldQty, 0);
    expect(afterDeleteSale.first.availableQty, 20);

    // Deleting the purchase bill removes purchasedQty -> stock becomes empty (0)
    final afterDeletePurchase = stockProvider.buildStockSummary(
      purchases: [oldPurchase],
      invoices: [oldInvoice],
      includeCatalogDefaults: false,
    );
    expect(afterDeletePurchase, isEmpty);

    // Resetting stock to 0 clears everything and moves baseline forward
    await stockProvider.resetStockToZero();
    final afterReset = stockProvider.buildStockSummary(
      purchases: [oldPurchase, newPurchase],
      invoices: [oldInvoice, newInvoice],
      includeCatalogDefaults: false,
    );
    expect(afterReset, isEmpty);
  });
}
