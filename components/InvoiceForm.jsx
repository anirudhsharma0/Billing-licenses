import React, { useState } from "react";
import {
  Plus,
  Trash2,
  Copy,
  Building,
  UserCheck,
  FileText,
  CreditCard,
  Layers,
  Sparkles,
  RotateCcw,
  Save,
  Printer,
  ChevronDown,
  ChevronUp
} from "lucide-react";

/**
 * InvoiceForm Component (Simplified, Clean & Spacious Entry Form)
 */
export default function InvoiceForm({
  invoice,
  onChange,
  onReset,
  onLoadSample,
  onSave,
  onPrint,
  isSaving = false,
}) {
  // Active Tab for clean, step-by-step editing: 'items' | 'buyer' | 'invoice' | 'seller' | 'all'
  const [activeTab, setActiveTab] = useState("items");

  // Helper updater
  const updateNested = (parentKey, fieldKey, value) => {
    onChange({
      ...invoice,
      [parentKey]: {
        ...invoice[parentKey],
        [fieldKey]: value,
      },
    });
  };

  // Sync Buyer to Consignee
  const copyBuyerToConsignee = () => {
    onChange({
      ...invoice,
      consignee: {
        ...invoice.buyer,
      },
    });
  };

  // Item helpers
  const addItem = () => {
    const newItem = {
      description: "",
      subtext: "",
      hsn: "",
      quantity: 1,
      unit: "Nos",
      rate: 0,
      taxRate: 18,
    };
    onChange({
      ...invoice,
      items: [...(invoice.items || []), newItem],
    });
  };

  const updateItem = (index, field, value) => {
    const updated = [...(invoice.items || [])];
    updated[index] = {
      ...updated[index],
      [field]: value,
    };
    onChange({
      ...invoice,
      items: updated,
    });
  };

  const removeItem = (index) => {
    if ((invoice.items || []).length <= 1) {
      alert("At least one item is required in the invoice.");
      return;
    }
    const updated = invoice.items.filter((_, idx) => idx !== index);
    onChange({
      ...invoice,
      items: updated,
    });
  };

  const duplicateItem = (index) => {
    const itemToDup = { ...invoice.items[index] };
    const updated = [...invoice.items];
    updated.splice(index + 1, 0, itemToDup);
    onChange({
      ...invoice,
      items: updated,
    });
  };

  // Logo upload preview
  const handleLogoUpload = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event) => {
        updateNested("seller", "logoUrl", event.target?.result);
      };
      reader.readAsDataURL(file);
    }
  };

  return (
    <div className="space-y-4 text-slate-800">
      
      {/* 1. Quick Bar & Primary Action Buttons */}
      <div className="bg-white border border-slate-300 rounded-2xl p-4 shadow-sm space-y-3">
        
        {/* Save and Print Buttons - Big & Clear */}
        <div className="grid grid-cols-2 gap-3">
          <button
            type="button"
            onClick={onSave}
            disabled={isSaving}
            className="flex items-center justify-center gap-2 py-3 px-4 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm sm:text-base rounded-xl shadow-md transition disabled:opacity-50 active:scale-[0.98]"
          >
            <Save className="w-5 h-5" />
            <span>{isSaving ? "Saving..." : "Save Invoice"}</span>
          </button>
          
          <button
            type="button"
            onClick={onPrint}
            className="flex items-center justify-center gap-2 py-3 px-4 bg-sky-600 hover:bg-sky-700 text-white font-bold text-sm sm:text-base rounded-xl shadow-md transition active:scale-[0.98]"
          >
            <Printer className="w-5 h-5" />
            <span>Print / PDF</span>
          </button>
        </div>

        {/* GST Type & Sample Tools */}
        <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-slate-200">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-slate-600">GST:</span>
            <div className="inline-flex rounded-lg border border-slate-300 p-0.5 bg-slate-100 text-xs">
              <button
                type="button"
                onClick={() => onChange({ ...invoice, taxMode: "CGST_SGST" })}
                className={`px-3 py-1 rounded-md font-semibold transition ${
                  invoice.taxMode === "CGST_SGST"
                    ? "bg-white text-slate-900 shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Intra-State (CGST+SGST)
              </button>
              <button
                type="button"
                onClick={() => onChange({ ...invoice, taxMode: "IGST" })}
                className={`px-3 py-1 rounded-md font-semibold transition ${
                  invoice.taxMode === "IGST"
                    ? "bg-white text-slate-900 shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Inter-State (IGST)
              </button>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={onLoadSample}
              className="flex items-center gap-1 px-2.5 py-1 text-xs font-semibold text-sky-700 bg-sky-50 hover:bg-sky-100 border border-sky-200 rounded-lg transition"
            >
              <Sparkles className="w-3.5 h-3.5" />
              <span>Sample</span>
            </button>
            <button
              type="button"
              onClick={onReset}
              className="flex items-center gap-1 px-2.5 py-1 text-xs font-semibold text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Reset</span>
            </button>
          </div>
        </div>
      </div>

      {/* 2. Simplified Clean Section Tabs */}
      <div className="flex items-center gap-1.5 p-1 bg-slate-200/90 rounded-xl overflow-x-auto text-xs font-bold">
        <button
          type="button"
          onClick={() => setActiveTab("items")}
          className={`flex-1 min-w-[100px] flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg transition ${
            activeTab === "items"
              ? "bg-white text-sky-800 shadow-sm font-extrabold"
              : "text-slate-600 hover:text-slate-900"
          }`}
        >
          <Layers className="w-4 h-4 text-sky-600" />
          <span>Items ({invoice.items?.length || 0})</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("buyer")}
          className={`flex-1 min-w-[100px] flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg transition ${
            activeTab === "buyer"
              ? "bg-white text-emerald-800 shadow-sm font-extrabold"
              : "text-slate-600 hover:text-slate-900"
          }`}
        >
          <UserCheck className="w-4 h-4 text-emerald-600" />
          <span>Buyer Details</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("invoice")}
          className={`flex-1 min-w-[100px] flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg transition ${
            activeTab === "invoice"
              ? "bg-white text-indigo-800 shadow-sm font-extrabold"
              : "text-slate-600 hover:text-slate-900"
          }`}
        >
          <FileText className="w-4 h-4 text-indigo-600" />
          <span>Bill No & Date</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("seller")}
          className={`flex-1 min-w-[100px] flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg transition ${
            activeTab === "seller"
              ? "bg-white text-purple-800 shadow-sm font-extrabold"
              : "text-slate-600 hover:text-slate-900"
          }`}
        >
          <Building className="w-4 h-4 text-purple-600" />
          <span>Seller & Bank</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab(activeTab === "all" ? "items" : "all")}
          className={`px-3 py-2 rounded-lg transition ${
            activeTab === "all"
              ? "bg-slate-900 text-white font-extrabold"
              : "text-slate-600 hover:text-slate-900"
          }`}
          title="Show all sections together"
        >
          All
        </button>
      </div>

      {/* 3. SECTION CONTENT */}

      {/* TAB A: ITEMS & RATES */}
      {(activeTab === "items" || activeTab === "all") && (
        <div className="bg-white border border-slate-300 rounded-2xl p-4 shadow-sm space-y-4">
          <div className="flex items-center justify-between pb-2 border-b border-slate-200">
            <h3 className="font-bold text-base text-slate-800 flex items-center gap-2">
              <Layers className="w-5 h-5 text-sky-600" />
              <span>Items List ({invoice.items?.length || 0})</span>
            </h3>
            <button
              type="button"
              onClick={addItem}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-sky-600 hover:bg-sky-700 text-white rounded-lg font-bold text-xs shadow-sm transition"
            >
              <Plus className="w-4 h-4" />
              <span>Add Item</span>
            </button>
          </div>

          <div className="space-y-3">
            {invoice.items?.map((item, idx) => {
              const qty = parseFloat(item.quantity) || 0;
              const rate = parseFloat(item.rate) || 0;
              const lineTotal = qty * rate;

              return (
                <div
                  key={idx}
                  className="p-4 border-2 border-slate-200 rounded-xl bg-slate-50/70 hover:border-sky-300 transition space-y-3"
                >
                  {/* Top Bar of Item */}
                  <div className="flex items-center justify-between">
                    <span className="flex items-center justify-center w-7 h-7 rounded-lg bg-slate-900 text-white font-black text-xs">
                      #{idx + 1}
                    </span>
                    
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-bold text-slate-500">
                        Total: <span className="text-slate-900 font-mono text-sm">₹{lineTotal.toLocaleString("en-IN", { minimumFractionDigits: 2 })}</span>
                      </span>
                      <button
                        type="button"
                        onClick={() => duplicateItem(idx)}
                        title="Duplicate item"
                        className="p-1.5 text-slate-500 hover:text-sky-600 hover:bg-white rounded-lg border border-slate-300 transition"
                      >
                        <Copy className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => removeItem(idx)}
                        title="Remove item"
                        className="p-1.5 text-slate-500 hover:text-rose-600 hover:bg-white rounded-lg border border-slate-300 transition"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  {/* Item Description & HSN */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div className="sm:col-span-2">
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Item Description / Goods & Services Name *
                      </label>
                      <input
                        type="text"
                        value={item.description || ""}
                        onChange={(e) => updateItem(idx, "description", e.target.value)}
                        placeholder="e.g. Solar Power Generating System 5KW"
                        className="w-full px-3 py-2 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:outline-none bg-white font-medium"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        HSN / SAC Code
                      </label>
                      <input
                        type="text"
                        value={item.hsn || ""}
                        onChange={(e) => updateItem(idx, "hsn", e.target.value)}
                        placeholder="e.g. 854140"
                        className="w-full px-3 py-2 text-sm font-mono border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:outline-none bg-white font-bold"
                      />
                    </div>
                  </div>

                  {/* Subtext / Specifications */}
                  <div>
                    <label className="block text-xs font-semibold text-slate-600 mb-1">
                      Specifications / Details (Optional sub-text)
                    </label>
                    <textarea
                      rows={2}
                      value={item.subtext || ""}
                      onChange={(e) => updateItem(idx, "subtext", e.target.value)}
                      placeholder="e.g. Waaree 580wp Topcon Dcr Pv Module, Polycab inverter..."
                      className="w-full px-3 py-1.5 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:outline-none bg-white font-sans"
                    />
                  </div>

                  {/* Qty, Unit, Rate, GST% */}
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-1">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Quantity
                      </label>
                      <input
                        type="number"
                        min="0.01"
                        step="any"
                        value={item.quantity}
                        onChange={(e) => updateItem(idx, "quantity", e.target.value)}
                        className="w-full px-3 py-2 text-sm font-bold border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 bg-white"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Unit (per)
                      </label>
                      <select
                        value={item.unit || "Nos"}
                        onChange={(e) => updateItem(idx, "unit", e.target.value)}
                        className="w-full px-3 py-2 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 bg-white font-medium"
                      >
                        <option value="Nos">Nos</option>
                        <option value="set">set</option>
                        <option value="Pcs">Pcs</option>
                        <option value="Box">Box</option>
                        <option value="Kg">Kg</option>
                        <option value="Mtr">Mtr</option>
                        <option value="Hours">Hours</option>
                        <option value="Pack">Pack</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Rate (₹)
                      </label>
                      <input
                        type="number"
                        min="0"
                        step="any"
                        value={item.rate}
                        onChange={(e) => updateItem(idx, "rate", e.target.value)}
                        className="w-full px-3 py-2 text-sm font-mono font-bold border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 bg-white"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        GST %
                      </label>
                      <select
                        value={item.taxRate ?? 18}
                        onChange={(e) => updateItem(idx, "taxRate", parseFloat(e.target.value))}
                        className="w-full px-3 py-2 text-sm font-bold border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 bg-white"
                      >
                        <option value={0}>0% (Exempt)</option>
                        <option value={5}>5%</option>
                        <option value={12}>12%</option>
                        <option value={18}>18%</option>
                        <option value={28}>28%</option>
                      </select>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          <button
            type="button"
            onClick={addItem}
            className="w-full py-3 flex items-center justify-center gap-2 border-2 border-dashed border-sky-400 text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-xl font-bold text-sm transition"
          >
            <Plus className="w-5 h-5" />
            <span>Add Another Item</span>
          </button>
        </div>
      )}

      {/* TAB B: BUYER DETAILS */}
      {(activeTab === "buyer" || activeTab === "all") && (
        <div className="bg-white border border-slate-300 rounded-2xl p-4 shadow-sm space-y-3.5">
          <div className="flex items-center justify-between pb-2 border-b border-slate-200">
            <h3 className="font-bold text-base text-slate-800 flex items-center gap-2">
              <UserCheck className="w-5 h-5 text-emerald-600" />
              <span>Buyer Details (Client / Customer)</span>
            </h3>
            <button
              type="button"
              onClick={copyBuyerToConsignee}
              className="text-xs font-bold text-sky-700 hover:underline"
            >
              Sync to Consignee (Ship to)
            </button>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Client / Company Name *</label>
            <input
              type="text"
              value={invoice.buyer?.name || ""}
              onChange={(e) => updateNested("buyer", "name", e.target.value)}
              placeholder="e.g. SATBIR SINGH S/O JAGDISH"
              className="w-full px-3.5 py-2.5 text-sm font-semibold border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Billing Address *</label>
            <textarea
              rows={2}
              value={invoice.buyer?.address || ""}
              onChange={(e) => updateNested("buyer", "address", e.target.value)}
              placeholder="Village/Post, Tehsil, City, District"
              className="w-full px-3.5 py-2 text-sm border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Buyer GSTIN (Optional)</label>
              <input
                type="text"
                value={invoice.buyer?.gstin || ""}
                onChange={(e) => updateNested("buyer", "gstin", e.target.value)}
                placeholder="06ABCDE1234F1Z5"
                className="w-full px-3 py-2 text-sm font-mono uppercase border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">State Name</label>
              <input
                type="text"
                value={invoice.buyer?.state || ""}
                onChange={(e) => updateNested("buyer", "state", e.target.value)}
                placeholder="Haryana"
                className="w-full px-3 py-2 text-sm border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">State Code</label>
              <input
                type="text"
                value={invoice.buyer?.stateCode || ""}
                onChange={(e) => updateNested("buyer", "stateCode", e.target.value)}
                placeholder="06"
                className="w-full px-3 py-2 text-sm font-mono border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>
          </div>
        </div>
      )}

      {/* TAB C: INVOICE DETAILS */}
      {(activeTab === "invoice" || activeTab === "all") && (
        <div className="bg-white border border-slate-300 rounded-2xl p-4 shadow-sm space-y-3.5">
          <div className="pb-2 border-b border-slate-200">
            <h3 className="font-bold text-base text-slate-800 flex items-center gap-2">
              <FileText className="w-5 h-5 text-indigo-600" />
              <span>Invoice Details</span>
            </h3>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Invoice / Proforma No. *</label>
              <input
                type="text"
                value={invoice.metadata?.invoiceNo || ""}
                onChange={(e) => updateNested("metadata", "invoiceNo", e.target.value)}
                placeholder="1"
                className="w-full px-3.5 py-2.5 text-sm font-mono font-bold border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Dated *</label>
              <input
                type="text"
                value={invoice.metadata?.date || ""}
                onChange={(e) => updateNested("metadata", "date", e.target.value)}
                placeholder="29/09/2026"
                className="w-full px-3.5 py-2.5 text-sm font-bold border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Destination</label>
              <input
                type="text"
                value={invoice.metadata?.destination || ""}
                onChange={(e) => updateNested("metadata", "destination", e.target.value)}
                placeholder="Adampur / Hisar"
                className="w-full px-3 py-2 text-sm border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Payment Terms</label>
              <input
                type="text"
                value={invoice.metadata?.paymentTerms || ""}
                onChange={(e) => updateNested("metadata", "paymentTerms", e.target.value)}
                placeholder="100% Advance / Net 30 Days"
                className="w-full px-3 py-2 text-sm border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>
          </div>
        </div>
      )}

      {/* TAB D: SELLER & BANK DETAILS */}
      {(activeTab === "seller" || activeTab === "all") && (
        <div className="bg-white border border-slate-300 rounded-2xl p-4 shadow-sm space-y-4">
          <div className="pb-2 border-b border-slate-200">
            <h3 className="font-bold text-base text-slate-800 flex items-center gap-2">
              <Building className="w-5 h-5 text-purple-600" />
              <span>Seller Company & Bank Details</span>
            </h3>
          </div>

          <div className="space-y-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Seller / Company Name *</label>
              <input
                type="text"
                value={invoice.seller?.name || ""}
                onChange={(e) => updateNested("seller", "name", e.target.value)}
                placeholder="The Kishan Bharti Coop. M.P. Society Ltd."
                className="w-full px-3.5 py-2.5 text-sm font-bold border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Address *</label>
              <textarea
                rows={2}
                value={invoice.seller?.address || ""}
                onChange={(e) => updateNested("seller", "address", e.target.value)}
                placeholder="Additonal Anaj Mandi ShopNo-1-2 Mandi Adampur"
                className="w-full px-3.5 py-2 text-sm border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Seller GSTIN/UIN *</label>
                <input
                  type="text"
                  value={invoice.seller?.gstin || ""}
                  onChange={(e) => updateNested("seller", "gstin", e.target.value)}
                  placeholder="06AAEAT5833H1ZE"
                  className="w-full px-3 py-2 text-sm font-mono font-bold uppercase border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">State Name</label>
                <input
                  type="text"
                  value={invoice.seller?.state || ""}
                  onChange={(e) => updateNested("seller", "state", e.target.value)}
                  placeholder="Haryana"
                  className="w-full px-3 py-2 text-sm border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">State Code</label>
                <input
                  type="text"
                  value={invoice.seller?.stateCode || ""}
                  onChange={(e) => updateNested("seller", "stateCode", e.target.value)}
                  placeholder="06"
                  className="w-full px-3 py-2 text-sm font-mono border border-slate-300 rounded-xl focus:ring-2 focus:ring-sky-500 bg-white"
                />
              </div>
            </div>

            {/* Bank details grid */}
            <div className="pt-2 border-t border-slate-200">
              <h4 className="font-bold text-xs text-slate-700 mb-2 flex items-center gap-1.5">
                <CreditCard className="w-4 h-4 text-purple-600" />
                <span>Bank Information</span>
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Bank Name</label>
                  <input
                    type="text"
                    value={invoice.bankDetails?.bankName || ""}
                    onChange={(e) => updateNested("bankDetails", "bankName", e.target.value)}
                    placeholder="State Bank of India C/A"
                    className="w-full px-3 py-2 text-sm border border-slate-300 rounded-xl bg-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Account Number</label>
                  <input
                    type="text"
                    value={invoice.bankDetails?.accountNo || ""}
                    onChange={(e) => updateNested("bankDetails", "accountNo", e.target.value)}
                    placeholder="39302189235"
                    className="w-full px-3 py-2 text-sm font-mono font-bold border border-slate-300 rounded-xl bg-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Branch & IFSC Code</label>
                  <input
                    type="text"
                    value={invoice.bankDetails?.ifsc || ""}
                    onChange={(e) => updateNested("bankDetails", "ifsc", e.target.value)}
                    placeholder="SBIN00011845"
                    className="w-full px-3 py-2 text-sm font-mono border border-slate-300 rounded-xl bg-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Branch Name</label>
                  <input
                    type="text"
                    value={invoice.bankDetails?.branch || ""}
                    onChange={(e) => updateNested("bankDetails", "branch", e.target.value)}
                    placeholder="Mandi Adampur"
                    className="w-full px-3 py-2 text-sm border border-slate-300 rounded-xl bg-white"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
