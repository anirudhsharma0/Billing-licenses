# GST Proforma Invoice & Billing Application (Flutter)

A cross-platform GST-compliant Proforma & Tax Invoice generator application built with **Flutter 3**, **Material 3**, and Dart.

Designed for **Windows Desktop**, **Web Browsers (Chrome / Edge)**, and **Mobile (Android / iOS)** with pixel-perfect A4 Indian Tally/GST grid styling, vector PDF export, direct native printing, and persistent invoice storage.

---

## 🌟 Key Features

1. **A4 Tally / GST Standard Proforma Invoice Layout**:
   - **Header**: Document Title (e.g. `PROFORMA INVOICE` / `TAX INVOICE`).
   - **Seller Section**: Company logo image, firm name, address, GSTIN/UIN, State & Code, Email.
   - **Buyer & Consignee Grid**: Bill To and Ship To with 1-click `Same as Buyer` copy action.
   - **Metadata Sub-grids**: Invoice No, Dated, Delivery Note, Ref No & Date, Destination, Dispatch Doc No, Terms of Delivery & Payment.
   - **Items Table**: Sl No, Description, Subtext/specs, HSN/SAC, Quantity, Unit, Rate, Amount, live Tax Breakup rows (`CGST @ X%`, `SGST @ X%` or `IGST @ X%`), and Total summary row.
   - **Amount Chargeable in Words**: Automatic Indian Numbering System conversion (Crores, Lakhs, Thousands, Hundreds, Rupees, and Paise).
   - **HSN/SAC Statutory Tax Summary Table**: Breakup with Taxable Value, CGST/SGST/IGST rates and amounts, and Total Tax in words.
   - **Footer**: Legal declaration, Company Bank Details (Holder, Bank, A/c No, IFSC, Branch, SWIFT), and Authorised Signatory box.

2. **Split-Screen Workspace & Zoom Controls**:
   - Responsive multi-view layout: **Split View** (Form on left, A4 sheet on right), **Form Only**, or **Sheet Preview Only**.
   - Zoom controls (**50% to 150%**) with 1-click 100% reset.
   - Mobile responsive layout with toggle between Form and Sheet preview.
   - Keyboard shortcuts: `Ctrl + P` to Print / Export PDF, `Ctrl + S` to Save Invoice.

3. **Persistent Local Invoice Storage**:
   - Full CRUD: Save new invoices, update existing drafts, duplicate invoices, and delete past drafts.
   - Searchable saved invoices modal with real-time filtering by Invoice No, Date, or Client Name.
   - 1-Click "Load Sample Data" replicating the realistic Kisan Bharti Cooperative Society GST invoice.

4. **Vector PDF Export & Native Printing**:
   - Uses `pdf` and `printing` packages to generate crisp, standard A4 vector documents.
   - Direct physical printing or 1-click Save as PDF on Windows Desktop, Chrome/Edge, and mobile devices.
5. **Offline Storage & Auto Background Firebase Sync**:
   - Saves bills locally first on disk with instant access.
   - Syncs automatically to Firebase Cloud Firestore when internet is connected.
   - Offline queue retries background sync seamlessly.

6. **Google Sheet Remote License Control**:
   - Checks client authorization against Google Sheet CSV feed.
   - Offline resilience: Caches last known license state if offline.
   - Minimalist payment due screen: Shows only "Payment Due", "Technical Support: wisdomCareSolutions", and "Check Status Again" button.

7. **One-Click In-App Auto-Updater**:
   - Connects to GitHub repository (`anirudhsharma0/Billing-licenses`).
   - Checks `version.json` and GitHub releases automatically or via navbar "Update" button.
   - Live download progress indicator with automatic background extraction/installation.

---

## 📁 Flutter Project Structure

```
├── lib/
│   ├── config/
│   │   ├── firebase_config.dart        # Firebase credentials & Firestore collection config
│   │   ├── license_config.dart         # Google Sheet CSV URL & client ID setup
│   │   └── update_config.dart          # GitHub repo, release URLs & current app version
│   ├── data/
│   │   └── sample_data.dart            # Realistic sample GST invoice data
│   ├── models/
│   │   └── invoice_model.dart          # Complete invoice data model with GST calculations & JSON serialization
│   ├── providers/
│   │   ├── invoice_provider.dart       # State management (ChangeNotifier)
│   │   └── license_provider.dart       # Remote license status provider
│   ├── screens/
│   │   ├── home_screen.dart            # Main workspace (AppBar, Split View, Zoom, Update Chip & Shortcuts)
│   │   └── mobile_bills_screen.dart    # Mobile responsive saved bills screen
│   ├── services/
│   │   ├── firebase_service.dart       # Firestore sync & cloud backup
│   │   ├── invoice_pdf_service.dart    # Vector A4 PDF generation & native print handler
│   │   ├── invoice_storage_service.dart# SharedPreferences persistent storage & offline sync queue
│   │   ├── license_service.dart        # Google Sheet CSV client verification & offline cache
│   │   └── update_service.dart         # GitHub Releases & version.json auto-updater engine
│   ├── utils/
│   │   └── number_to_words.dart        # Indian currency words converter (Lakhs, Crores, etc.)
│   ├── widgets/
│   │   ├── invoice_form_panel.dart     # Dynamic tabbed form (Items, Buyer, Meta, Seller)
│   │   ├── invoice_history_dialog.dart # Searchable saved invoices modal
│   │   ├── invoice_preview_sheet.dart  # High-precision A4 on-screen preview sheet
│   │   ├── license_lock_screen.dart    # Minimalist payment due lock screen
│   │   └── update_dialog.dart          # Live download progress & update installation modal
│   └── main.dart                       # App entry point & Material 3 theme
├── assets/
│   └── images/
│       ├── coop-logo.png               # Company logo asset
│       └── coop-logo.svg
├── version.json                        # Version metadata file for GitHub raw manifest auto-update
├── pubspec.yaml                        # Dependencies and assets configuration
└── README.md
```


---

## 🚀 How to Run

### 1. Run on Chrome / Edge (Web)
```bash
flutter run -d chrome
```

### 2. Run on Windows Desktop
```bash
flutter run -d windows
```

### 3. Run on Android Device / Emulator
```bash
flutter run -d android
```

### 4. Build Release Packages
- **Web**: `flutter build web --release`
- **Windows**: `flutter build windows --release`
- **Android APK**: `flutter build apk --release`
