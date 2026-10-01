"use client";

import React, { useState, useRef, useEffect } from "react";
import InvoicePreview from "../components/InvoicePreview";
import InvoiceForm from "../components/InvoiceForm";
import InvoiceHistoryModal from "../components/InvoiceHistoryModal";
import { defaultInvoice } from "../lib/defaultInvoice";
import { saveInvoice, isFirebaseConfigured } from "../firebase";
import { formatIndianCurrency } from "../lib/numberToWords";
import {
  Printer,
  Save,
  FolderOpen,
  PlusCircle,
  Eye,
  Edit3,
  ZoomIn,
  ZoomOut,
  Maximize2,
  Columns,
  CheckCircle2,
  AlertCircle,
  Database
} from "lucide-react";

/**
 * Main Application Page (Clean, Spacious, Simple)
 */
export default function Home() {
  const [invoice, setInvoice] = useState(defaultInvoice);
  
  // Layout View Modes: 'split' | 'form' | 'preview'
  const [viewMode, setViewMode] = useState("split");
  
  // Zoom level for A4 Sheet preview (Default 0.90 for comfortable reading)
  const [zoomLevel, setZoomLevel] = useState(0.90);
  
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [isCloudReady, setIsCloudReady] = useState(false);

  const printAreaRef = useRef(null);

  useEffect(() => {
    setIsCloudReady(isFirebaseConfigured());

    // Adjust view & zoom based on screen width
    const handleResize = () => {
      if (window.innerWidth < 1024) {
        // Mobile / Small Tablet: default to form view
        setViewMode((current) => (current === "split" ? "form" : current));
        setZoomLevel(0.80);
      } else if (window.innerWidth < 1366) {
        // Standard 1024-1366px laptop: comfortable 0.85 zoom
        setZoomLevel(0.85);
      } else {
        // Large screen
        setZoomLevel(0.95);
      }
    };
    handleResize();
    window.addEventListener("resize", handleResize);

    // Keyboard shortcuts: Ctrl+P -> Print, Ctrl+S -> Save
    const handleKeyDown = (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "p") {
        e.preventDefault();
        handlePrint();
      } else if ((e.ctrlKey || e.metaKey) && e.key === "s") {
        e.preventDefault();
        handleSaveInvoice();
      }
    };
    window.addEventListener("keydown", handleKeyDown);

    return () => {
      window.removeEventListener("resize", handleResize);
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  const showToast = (message, type = "success") => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 4500);
  };

  // Browser Native Print (Ctrl+P)
  const handlePrint = () => {
    try {
      if (typeof window !== "undefined") {
        window.print();
      }
    } catch (err) {
      console.error("Print failed:", err);
    }
  };

  // Save Invoice (Firestore with Local fallback)
  const handleSaveInvoice = async () => {
    setSaving(true);
    try {
      const res = await saveInvoice(invoice);
      if (res && res.success) {
        setInvoice((prev) => ({ ...prev, id: res.id }));
        const msg = res.source === "firestore"
          ? `Invoice #${invoice.metadata?.invoiceNo || "1"} saved to Cloud Firestore!`
          : `Invoice #${invoice.metadata?.invoiceNo || "1"} saved to Browser Storage!`;
        showToast(msg, "success");
      } else {
        showToast("Save failed. Please check console.", "error");
      }
    } catch (err) {
      console.error("Save error:", err);
      showToast("Error saving invoice: " + (err.message || "Failed"), "error");
    } finally {
      setSaving(false);
    }
  };

  // New Blank Draft
  const handleNewInvoice = () => {
    if (window.confirm("Start a new blank invoice? Any unsaved edits will be cleared.")) {
      const emptyInvoice = {
        ...defaultInvoice,
        id: null,
        metadata: {
          ...defaultInvoice.metadata,
          invoiceNo: `PI-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`,
          date: new Date().toLocaleDateString("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" }),
        },
        items: [
          {
            description: "",
            subtext: "",
            hsn: "",
            quantity: 1,
            unit: "Nos",
            rate: 0,
            taxRate: 18,
          },
        ],
      };
      setInvoice(emptyInvoice);
      showToast("Started fresh invoice draft", "info");
    }
  };

  // Load sample GST invoice
  const handleLoadSample = () => {
    setInvoice(defaultInvoice);
    showToast("Sample GST Proforma Invoice loaded!", "info");
  };

  // Load selected invoice from history modal
  const handleSelectInvoice = (selected) => {
    setInvoice(selected);
    showToast(`Loaded invoice #${selected.metadata?.invoiceNo || selected.id}`, "success");
  };

  // Duplicate invoice
  const handleDuplicateInvoice = (selected) => {
    const duplicated = {
      ...selected,
      id: null,
      metadata: {
        ...selected.metadata,
        invoiceNo: `${selected.metadata?.invoiceNo || "PI"}-COPY`,
        date: new Date().toLocaleDateString("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" }),
      },
    };
    setInvoice(duplicated);
    showToast("Duplicated invoice as new draft", "info");
  };

  // Calculate grand total for header badge
  const calculateTotal = () => {
    let taxable = 0;
    let tax = 0;
    invoice.items?.forEach((item) => {
      const lineTaxable = (parseFloat(item.quantity) || 0) * (parseFloat(item.rate) || 0);
      taxable += lineTaxable;
      tax += lineTaxable * ((parseFloat(item.taxRate) || 18) / 100);
    });
    return Math.round(taxable + tax + (parseFloat(invoice.roundOff) || 0));
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-100 font-sans">
      
      {/* 1. CLEAN TOP HEADER */}
      <header className="sticky top-0 z-30 bg-slate-900 text-white shadow-md border-b border-slate-800 no-print">
        <div className="max-w-[1920px] mx-auto px-4 py-2.5 flex items-center justify-between gap-4">
          
          {/* Logo & Title */}
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-sky-500 flex items-center justify-center font-black text-white text-lg shadow-sm">
              ₹
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-extrabold text-base tracking-tight text-white">
                  GST Billing & Invoice
                </h1>
                <span className="hidden sm:inline-block px-2.5 py-0.5 text-xs font-semibold bg-emerald-950 text-emerald-300 border border-emerald-800 rounded-full">
                  Total: ₹{formatIndianCurrency(calculateTotal())}
                </span>
              </div>
              <div className="text-xs text-slate-400">
                Invoice No: <span className="font-mono font-bold text-slate-200">{invoice.metadata?.invoiceNo || "1"}</span>
              </div>
            </div>
          </div>

          {/* Center: View Switcher (Form / Split / Large Bill Preview) */}
          <div className="flex items-center p-1 bg-slate-800 rounded-xl border border-slate-700">
            <button
              type="button"
              onClick={() => setViewMode("form")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                viewMode === "form"
                  ? "bg-sky-600 text-white shadow-sm"
                  : "text-slate-300 hover:text-white"
              }`}
              title="Full width form editing"
            >
              <Edit3 className="w-4 h-4" />
              <span>Edit Form</span>
            </button>

            <button
              type="button"
              onClick={() => setViewMode("split")}
              className={`hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                viewMode === "split"
                  ? "bg-sky-600 text-white shadow-sm"
                  : "text-slate-300 hover:text-white"
              }`}
              title="Side-by-side editing and preview"
            >
              <Columns className="w-4 h-4" />
              <span>Split View</span>
            </button>

            <button
              type="button"
              onClick={() => {
                setViewMode("preview");
                setZoomLevel(1.0); // automatically scale to full size when previewing!
              }}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                viewMode === "preview"
                  ? "bg-sky-600 text-white shadow-sm"
                  : "text-slate-300 hover:text-white"
              }`}
              title="Full size large A4 preview"
            >
              <Eye className="w-4 h-4" />
              <span>Large Preview</span>
            </button>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setIsHistoryOpen(true)}
              className="hidden sm:flex items-center gap-1.5 px-3 py-2 text-xs font-bold text-slate-200 hover:text-white bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-xl transition"
              title="Saved Invoices History"
            >
              <FolderOpen className="w-4 h-4 text-amber-400" />
              <span>Saved Bills</span>
            </button>

            <button
              onClick={handleNewInvoice}
              className="hidden sm:flex items-center gap-1.5 px-3 py-2 text-xs font-bold text-slate-200 hover:text-white bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-xl transition"
              title="New Blank Invoice"
            >
              <PlusCircle className="w-4 h-4 text-emerald-400" />
              <span>New</span>
            </button>

            <button
              onClick={handleSaveInvoice}
              disabled={saving}
              className="flex items-center gap-1.5 px-4 py-2 text-xs sm:text-sm font-bold text-white bg-emerald-600 hover:bg-emerald-500 rounded-xl shadow-md transition disabled:opacity-50"
              title="Save to Firebase Firestore (Ctrl+S)"
            >
              <Save className="w-4 h-4" />
              <span>{saving ? "Saving..." : "Save"}</span>
            </button>

            <button
              onClick={handlePrint}
              className="flex items-center gap-1.5 px-4 py-2 text-xs sm:text-sm font-bold text-white bg-sky-600 hover:bg-sky-500 rounded-xl shadow-md transition"
              title="Print or Save as PDF (Ctrl+P)"
            >
              <Printer className="w-4 h-4" />
              <span>Print Bill</span>
            </button>
          </div>
        </div>
      </header>

      {/* 2. MAIN WORKSPACE */}
      <main className="flex-1 flex overflow-hidden">
        
        {/* LEFT PANEL: ENTRY FORM */}
        {(viewMode === "form" || viewMode === "split") && (
          <section
            className={`${
              viewMode === "split"
                ? "w-full lg:w-[48%] xl:w-[45%]"
                : "w-full max-w-4xl mx-auto"
            } h-[calc(100vh-58px)] overflow-y-auto p-4 sm:p-6 bg-slate-100 border-r border-slate-300 invoice-form-panel`}
          >
            <div className="max-w-2xl mx-auto space-y-4">
              <InvoiceForm
                invoice={invoice}
                onChange={setInvoice}
                onReset={handleNewInvoice}
                onLoadSample={handleLoadSample}
                onSave={handleSaveInvoice}
                onPrint={handlePrint}
                isSaving={saving}
              />
            </div>
          </section>
        )}

        {/* RIGHT PANEL: A4 PREVIEW CANVAS */}
        {(viewMode === "preview" || viewMode === "split") && (
          <section
            className={`flex-1 h-[calc(100vh-58px)] overflow-y-auto bg-slate-200/90 p-4 sm:p-8 flex flex-col items-center relative preview-wrapper`}
          >
            {/* Preview Zoom Controls Bar */}
            <div className="w-full max-w-4xl flex items-center justify-between mb-4 px-2 no-print">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
                <span className="text-xs sm:text-sm font-bold text-slate-700">
                  {viewMode === "preview" ? "Full Size A4 Invoice Preview" : "Live A4 Bill Preview"}
                </span>
              </div>

              {/* Zoom Buttons */}
              <div className="flex items-center gap-1.5 bg-white px-2.5 py-1.5 rounded-xl shadow-sm border border-slate-300 text-xs font-bold">
                <button
                  type="button"
                  onClick={() => setZoomLevel((z) => Math.max(0.5, Number((z - 0.1).toFixed(2))))}
                  className="p-1 hover:bg-slate-100 rounded text-slate-700"
                  title="Zoom Out (Chhota Karo)"
                >
                  <ZoomOut className="w-4 h-4" />
                </button>
                <span className="font-mono font-black text-slate-800 w-12 text-center text-xs">
                  {Math.round(zoomLevel * 100)}%
                </span>
                <button
                  type="button"
                  onClick={() => setZoomLevel((z) => Math.min(1.5, Number((z + 0.1).toFixed(2))))}
                  className="p-1 hover:bg-slate-100 rounded text-slate-700"
                  title="Zoom In (Bada Karo)"
                >
                  <ZoomIn className="w-4 h-4" />
                </button>
                <div className="h-4 w-px bg-slate-300 mx-1"></div>
                <button
                  type="button"
                  onClick={() => setZoomLevel(1.0)}
                  className={`px-2 py-0.5 rounded text-xs transition ${
                    zoomLevel === 1.0 ? "bg-sky-100 text-sky-800 font-extrabold" : "text-slate-600 hover:bg-slate-100"
                  }`}
                  title="100% Original Size"
                >
                  100%
                </button>
                <button
                  type="button"
                  onClick={() => setZoomLevel(0.85)}
                  className="px-2 py-0.5 text-slate-600 hover:bg-slate-100 rounded text-xs"
                >
                  Fit
                </button>
                <div className="h-4 w-px bg-slate-300 mx-1"></div>
                <button
                  type="button"
                  onClick={handlePrint}
                  className="flex items-center gap-1 px-3 py-1 font-bold text-xs bg-sky-600 hover:bg-sky-500 text-white rounded-lg shadow-sm transition"
                  title="Print Bill"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span>Print</span>
                </button>
              </div>
            </div>

            {/* Scaled A4 Sheet Canvas */}
            <div
              className="transition-transform origin-top duration-150 ease-out print-wrapper"
              style={{
                transform: `scale(${zoomLevel})`,
                marginBottom: `${(zoomLevel - 1) * 350}px`,
              }}
            >
              <InvoicePreview invoice={invoice} printRef={printAreaRef} />
            </div>
          </section>
        )}
      </main>

      {/* Floating Toast Notification */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-2 px-4 py-3 bg-slate-900 text-white rounded-xl shadow-2xl border border-slate-700 text-xs font-semibold animate-in slide-in-from-bottom-5 duration-200">
          {toast.type === "success" && <CheckCircle2 className="w-4 h-4 text-emerald-400" />}
          {toast.type === "error" && <AlertCircle className="w-4 h-4 text-rose-400" />}
          {toast.type === "info" && <Database className="w-4 h-4 text-sky-400" />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Saved Invoices History Modal */}
      <InvoiceHistoryModal
        isOpen={isHistoryOpen}
        onClose={() => setIsHistoryOpen(false)}
        onSelectInvoice={handleSelectInvoice}
        onDuplicateInvoice={handleDuplicateInvoice}
      />
    </div>
  );
}
