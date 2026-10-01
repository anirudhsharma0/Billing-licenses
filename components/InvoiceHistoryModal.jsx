import React, { useState, useEffect } from "react";
import { getInvoices, deleteInvoice, isFirebaseConfigured } from "../lib/firebase";
import { formatIndianCurrency } from "../lib/numberToWords";
import {
  X,
  Search,
  Trash2,
  ExternalLink,
  Copy,
  Clock,
  Database,
  HardDrive,
  RefreshCw,
  AlertCircle,
  FileSpreadsheet
} from "lucide-react";

export default function InvoiceHistoryModal({
  isOpen,
  onClose,
  onSelectInvoice,
  onDuplicateInvoice,
}) {
  const [invoices, setInvoices] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [isFirebase, setIsFirebase] = useState(false);

  useEffect(() => {
    if (isOpen) {
      loadInvoices();
      setIsFirebase(isFirebaseConfigured());
    }
  }, [isOpen]);

  const loadInvoices = async () => {
    setLoading(true);
    try {
      const list = await getInvoices();
      setInvoices(list);
    } catch (err) {
      console.error("Failed to load invoices:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id, e) => {
    e.stopPropagation();
    if (window.confirm("Are you sure you want to delete this invoice?")) {
      await deleteInvoice(id);
      loadInvoices();
    }
  };

  const calculateTotal = (inv) => {
    const items = inv.items || [];
    let taxable = 0;
    let tax = 0;
    items.forEach((item) => {
      const qty = parseFloat(item.quantity) || 0;
      const rate = parseFloat(item.rate) || 0;
      const lineTaxable = qty * rate;
      const taxRate = parseFloat(item.taxRate) || 18;
      taxable += lineTaxable;
      tax += lineTaxable * (taxRate / 100);
    });
    return Math.round(taxable + tax + (parseFloat(inv.roundOff) || 0));
  };

  const filteredInvoices = invoices.filter((inv) => {
    const term = searchTerm.toLowerCase();
    const invNo = (inv.metadata?.invoiceNo || "").toLowerCase();
    const buyer = (inv.buyer?.name || "").toLowerCase();
    const date = (inv.metadata?.date || "").toLowerCase();
    return invNo.includes(term) || buyer.includes(term) || date.includes(term);
  });

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm modal-overlay">
      <div className="bg-white w-full max-w-4xl rounded-2xl shadow-2xl border border-slate-200 flex flex-col max-h-[85vh] overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-slate-200 bg-slate-50">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-sky-100 text-sky-700 rounded-xl">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900">Saved Invoices</h2>
              <div className="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
                {isFirebase ? (
                  <span className="flex items-center gap-1 text-emerald-600 font-medium">
                    <Database className="w-3.5 h-3.5" /> Firebase Firestore Connected
                  </span>
                ) : (
                  <span className="flex items-center gap-1 text-amber-600 font-medium">
                    <HardDrive className="w-3.5 h-3.5" /> Local Storage (Add Firebase keys to .env.local to sync Cloud)
                  </span>
                )}
                <span>&bull;</span>
                <span>{invoices.length} invoices saved</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={loadInvoices}
              title="Refresh list"
              className="p-2 text-slate-500 hover:text-slate-800 hover:bg-slate-200/60 rounded-lg transition"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            </button>
            <button
              onClick={onClose}
              className="p-2 text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 rounded-lg transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Search Bar */}
        <div className="p-4 border-b border-slate-200 bg-white">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by invoice number, buyer business name, or date..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 text-sm border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-sky-500 bg-slate-50 focus:bg-white transition"
            />
          </div>
        </div>

        {/* Invoices List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-2.5">
          {loading ? (
            <div className="py-16 text-center text-slate-500">
              <RefreshCw className="w-8 h-8 animate-spin mx-auto mb-3 text-sky-600" />
              <p className="text-sm font-medium">Loading your saved invoices...</p>
            </div>
          ) : filteredInvoices.length === 0 ? (
            <div className="py-16 text-center text-slate-500 max-w-sm mx-auto">
              <AlertCircle className="w-10 h-10 mx-auto mb-2 text-slate-400" />
              <h3 className="font-bold text-slate-800 text-sm">No Invoices Found</h3>
              <p className="text-xs text-slate-500 mt-1">
                {searchTerm
                  ? "No invoices matched your search filter."
                  : "You haven't saved any invoices yet. Click 'Save Invoice' in the top bar to save your first invoice!"}
              </p>
            </div>
          ) : (
            filteredInvoices.map((inv) => {
              const total = calculateTotal(inv);
              const itemsCount = inv.items?.length || 0;
              const isLocal = inv.id?.startsWith("local_");

              return (
                <div
                  key={inv.id}
                  onClick={() => {
                    onSelectInvoice(inv);
                    onClose();
                  }}
                  className="flex items-center justify-between p-3.5 rounded-xl border border-slate-200 hover:border-sky-400 hover:bg-sky-50/30 transition cursor-pointer group bg-white shadow-xs"
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-slate-900 group-hover:text-sky-700">
                        {inv.metadata?.invoiceNo || "Untitled Invoice"}
                      </span>
                      {isLocal ? (
                        <span className="px-2 py-0.5 text-[10px] font-semibold bg-amber-100 text-amber-800 rounded-md">
                          Local
                        </span>
                      ) : (
                        <span className="px-2 py-0.5 text-[10px] font-semibold bg-emerald-100 text-emerald-800 rounded-md">
                          Firestore
                        </span>
                      )}
                      <span className="text-xs text-slate-400 font-mono">
                        {inv.metadata?.date || "No date"}
                      </span>
                    </div>

                    <div className="text-xs text-slate-600">
                      <span className="font-semibold text-slate-800">{inv.buyer?.name || "No Buyer Specified"}</span>
                      <span className="mx-1.5 text-slate-300">&bull;</span>
                      <span>{itemsCount} {itemsCount === 1 ? "Item" : "Items"}</span>
                      {inv.buyer?.gstin && (
                        <>
                          <span className="mx-1.5 text-slate-300">&bull;</span>
                          <span className="font-mono text-slate-500">{inv.buyer.gstin}</span>
                        </>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <div className="font-black text-sm font-mono text-slate-900">
                        ₹ {formatIndianCurrency(total)}
                      </div>
                      <div className="text-[10px] text-slate-400 uppercase">
                        {inv.taxMode === "IGST" ? "IGST (Inter-state)" : "CGST + SGST"}
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5" onClick={(e) => e.stopPropagation()}>
                      <button
                        type="button"
                        onClick={() => {
                          onDuplicateInvoice(inv);
                          onClose();
                        }}
                        title="Duplicate as new invoice"
                        className="p-2 text-slate-400 hover:text-sky-600 hover:bg-sky-50 rounded-lg transition"
                      >
                        <Copy className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={(e) => handleDelete(inv.id, e)}
                        title="Delete invoice"
                        className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          onSelectInvoice(inv);
                          onClose();
                        }}
                        title="Load into Editor"
                        className="p-2 text-sky-600 hover:bg-sky-100 rounded-lg transition font-medium text-xs flex items-center gap-1"
                      >
                        <ExternalLink className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Footer */}
        <div className="p-3.5 bg-slate-50 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500">
          <span>Click any invoice above to load and edit or print.</span>
          <button
            onClick={onClose}
            className="px-4 py-1.5 bg-slate-200 hover:bg-slate-300 text-slate-800 font-semibold rounded-lg transition"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
