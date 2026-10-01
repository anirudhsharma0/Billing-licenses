# GST Proforma Invoice & Billing Web Application

A full-stack GST-compliant Proforma Invoice Generator web application built with **Next.js (App Router)**, **Tailwind CSS**, and **Firebase Firestore**.

Engineered to match the **A4 standard Indian Tally/GST Proforma Invoice layout** with high-precision grid borders, tax breakups (CGST/SGST/IGST), HSN/SAC summary table, bank details, and native pixel-perfect `@media print` styling for print and PDF generation.

---

## 🌟 Key Features

1. **A4 Tally / GST Standard Proforma Invoice Layout**:
   - Header with **PROFORMA INVOICE**.
   - Left Column: Seller Logo, Company Name, Address, GSTIN/UIN, State Name & Code, Email, Phone.
   - Right Column: Invoice No, Dated, Delivery Note, Mode/Terms of Payment, Reference No. & Date, Other References, Dispatch Doc No., Delivery Note Date, Dispatched through, Destination, Terms of Delivery.
   - Buyer & Consignee details with "Same as Buyer" quick copy button.
   - Item details table with:
     * Sl No., Description of Goods and Services, Specifications/Sub-text, HSN/SAC, Quantity, Rate, Unit (per), and Amount.
     * Taxes breakup inside items table (CGST @ X%, SGST @ X% or IGST @ X%).
     * Total Quantity and Final Total Amount (₹).
   - **Amount in Words**: Automatic Indian Numbering System conversion (Rupees and Paise).
   - **HSN/SAC Statutory Summary Table**: Separate tax calculation table with Taxable Value, CGST/SGST or IGST rates, and Total Tax in words.
   - **Footer Section**: Declaration note, Company Bank Details (A/c Holder, Bank, A/c No, IFSC, Branch, SWIFT), Jurisdiction note, and Authorised Signatory box.

2. **Real-time Live Preview & Responsive Form**:
   - Side-by-side split screen with zoom controls (50% to 140%).
   - Interactive data entry form with collapsible sections.
   - One-click "Load Sample Data" with realistic GST invoice items.
   - Quick "Reset" and "New Invoice" actions.
   - Keyboard shortcuts: `Ctrl + P` to Print / Save PDF, `Ctrl + S` to Save.

3. **Firebase Firestore Database Integration**:
   - Save invoices directly to Cloud Firestore collection (`invoices`).
   - Saved Invoices modal with search by Invoice No, Date, or Customer Name.
   - Duplicate or reload past invoices into the editor.
   - Built-in LocalStorage fallback so the app works seamlessly even before entering Firebase keys.

4. **Print / Save as PDF**:
   - Native CSS `@media print` styling tailored for A4 paper.
   - Automatically hides UI controls, form, buttons, and toasts when printing.
   - Zero page bleeding or border distortion.

---

## 📁 Project Structure

```
├── app/
│   ├── globals.css           # Custom print styling (@media print) & A4 page dimensions
│   ├── layout.jsx            # Root layout with fonts
│   └── page.jsx              # Main billing workspace (Form, Live Preview & Actions)
├── components/
│   ├── InvoiceTemplate.jsx   # Exact A4 Tally/GST Standard Invoice sheet
│   ├── InvoiceForm.jsx       # Dynamic reactive form with auto-calculation
│   └── InvoiceHistoryModal.jsx # Saved invoices drawer/modal (Firestore & Local)
├── lib/
│   ├── firebase.js           # Firebase Modular SDK initialization & CRUD methods
│   ├── numberToWords.js      # Indian currency number-to-words converter
│   └── defaultInvoice.js     # Realistic GST sample invoice data
├── firebase.js               # Root export for convenient imports
├── tailwind.config.js        # Tailwind CSS config
├── next.config.js            # Next.js configuration
├── .env.local.example        # Example environment variables for Firebase
└── package.json              # Dependencies and scripts
```

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
npm install
```

### 2. Run Locally
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## ☁️ Firebase Firestore Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new Firebase project (or use an existing one).
3. In Project Overview, click the **Web (</>)** icon to register a web app.
4. Go to **Firestore Database** in the left menu and click **Create Database** (Start in **Test mode** or configure rules below).
5. Copy your credentials into `.env.local`:
```env
NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSy...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-project-id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=1234567890
NEXT_PUBLIC_FIREBASE_APP_ID=1:1234567890:web:abcdef
```

### Firestore Security Rules (Optional / Recommended)
In Firebase Console > Firestore Database > Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /invoices/{document=**} {
      allow read, write: if true; // Or restrict with Firebase Authentication
    }
  }
}
```

---

## 🚢 Deploy to Vercel

1. Push this repository to **GitHub / GitLab / Bitbucket**.
2. Go to [Vercel](https://vercel.com/) and click **Add New > Project**.
3. Import your repository.
4. Under **Environment Variables**, add the `NEXT_PUBLIC_FIREBASE_*` variables from your `.env.local`.
5. Click **Deploy**. Your app will be live within seconds!
