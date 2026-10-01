import React from "react";
import { numberToWords, formatIndianCurrency } from "../lib/numberToWords";

/**
 * InvoicePreview Component
 * 
 * Standard A4 Indian GST Proforma & Tax Invoice format (Tally GST standard).
 * Designed for crisp on-screen viewing and exact single-page A4 printing (@media print).
 */
export default function InvoicePreview({ invoice, printRef }) {
  const seller = invoice?.seller || {};
  const buyer = invoice?.buyer || {};
  const consignee = invoice?.consignee || {};
  const meta = invoice?.metadata || {};
  const items = invoice?.items || [];
  const bank = invoice?.bankDetails || {};
  const taxMode = invoice?.taxMode || "CGST_SGST";

  // Calculations
  let totalQty = 0;
  let totalTaxableValue = 0;
  const hsnSummary = {};
  const taxBreakupList = [];

  items.forEach((item) => {
    const qty = parseFloat(item.quantity) || 0;
    const rate = parseFloat(item.rate) || 0;
    const lineTaxable = qty * rate;
    const taxRate = parseFloat(item.taxRate) || 0;
    const hsn = item.hsn ? item.hsn.trim() : "—";
    const unit = item.unit || "Nos";

    totalQty += qty;
    totalTaxableValue += lineTaxable;

    if (!hsnSummary[hsn]) {
      hsnSummary[hsn] = {
        hsn,
        taxableValue: 0,
        taxRate,
        cgstRate: taxRate / 2,
        sgstRate: taxRate / 2,
        cgstAmount: 0,
        sgstAmount: 0,
        igstAmount: 0,
        totalTax: 0,
      };
    }

    hsnSummary[hsn].taxableValue += lineTaxable;

    if (taxMode === "CGST_SGST") {
      const cgst = lineTaxable * (taxRate / 2 / 100);
      const sgst = lineTaxable * (taxRate / 2 / 100);
      hsnSummary[hsn].cgstAmount += cgst;
      hsnSummary[hsn].sgstAmount += sgst;
      hsnSummary[hsn].totalTax += cgst + sgst;

      taxBreakupList.push({
        label: `CGST OUTPUT@${(taxRate / 2).toFixed(1).replace(/\.0$/, "")}%`,
        rateStr: `${(taxRate / 2).toFixed(2).replace(/\.00$/, "").replace(/(\.\d)0$/, "$1")} %`,
        amount: cgst,
      });
      taxBreakupList.push({
        label: `SGST OUTPUT@${(taxRate / 2).toFixed(1).replace(/\.0$/, "")}%`,
        rateStr: `${(taxRate / 2).toFixed(2).replace(/\.00$/, "").replace(/(\.\d)0$/, "$1")} %`,
        amount: sgst,
      });
    } else {
      const igst = lineTaxable * (taxRate / 100);
      hsnSummary[hsn].igstAmount += igst;
      hsnSummary[hsn].totalTax += igst;

      taxBreakupList.push({
        label: `IGST OUTPUT@${taxRate}%`,
        rateStr: `${taxRate} %`,
        amount: igst,
      });
    }
  });

  let totalCgst = 0;
  let totalSgst = 0;
  let totalIgst = 0;
  let totalTaxSum = 0;

  Object.values(hsnSummary).forEach((h) => {
    totalCgst += h.cgstAmount;
    totalSgst += h.sgstAmount;
    totalIgst += h.igstAmount;
    totalTaxSum += h.totalTax;
  });

  const rawGrandTotal = totalTaxableValue + totalTaxSum;
  const roundOff = parseFloat(invoice?.roundOff) || 0;
  const grandTotal = Math.round(rawGrandTotal + roundOff);

  const amountInWords = numberToWords(grandTotal, "");
  const taxInWords = numberToWords(totalTaxSum, "INR");

  return (
    <div
      ref={printRef}
      id="invoice-print-area"
      className="a4-page p-6 sm:p-7 text-black bg-white select-text text-[12px] leading-snug shadow-xl"
      style={{
        fontFamily: "Arial, Helvetica, sans-serif",
      }}
    >
      {/* 1. Header Document Title */}
      <div className="text-center font-extrabold text-[15px] tracking-wider uppercase mb-1.5 text-black">
        {invoice?.invoiceTitle || "PROFORMA INVOICE"}
      </div>

      {/* Main Single Outer Border Box */}
      <div className="border border-black bg-white text-black">
        
        {/* 2. Seller Details Section with Logo */}
        <div className="p-3 border-b border-black flex items-center justify-between gap-4">
          {/* Logo on Left */}
          {seller.logoUrl ? (
            <div className="w-[110px] h-[95px] flex-shrink-0 flex items-center justify-center p-1">
              <img
                src={seller.logoUrl}
                alt="Logo"
                className="max-w-full max-h-full object-contain"
              />
            </div>
          ) : (
            <div className="w-[90px] h-[75px] flex-shrink-0 flex items-center justify-center border border-dashed border-slate-300 rounded text-slate-400 text-[11px] text-center p-1 no-print">
              Company Logo
            </div>
          )}

          {/* Centered Seller Details */}
          <div className="flex-1 text-center pr-4">
            <h1 className="text-[20px] font-extrabold tracking-tight text-black leading-tight">
              {seller.name || "Company Name Here"}
            </h1>
            <p className="text-[13px] font-bold text-black mt-1">
              {seller.address || "Company Address Here"}
            </p>
            <p className="text-[13px] font-bold text-black mt-0.5">
              GSTIN/UIN: {seller.gstin || "06AAEAT5833H1ZE"}
            </p>
            <p className="text-[12.5px] text-black mt-0.5">
              <span className="font-semibold">State Name :</span> {seller.state || "Haryana"},{" "}
              <span className="font-semibold">Code :</span> {seller.stateCode || "06"}
            </p>
            {seller.email && (
              <p className="text-[12px] text-black mt-0.5">
                <span className="font-semibold">E-Mail :</span> {seller.email}
              </p>
            )}
          </div>
        </div>

        {/* 3. Buyer & Consignee + Metadata Grid */}
        <div className="grid grid-cols-2 border-b border-black text-[11.5px]">
          
          {/* LEFT HALF: Buyer (Bill to) + Invoice Details */}
          <div className="border-r border-black flex flex-col justify-between">
            {/* Buyer Block */}
            <div className="p-2 min-h-[70px]">
              <div className="text-[11px] text-slate-700 font-semibold">Buyer (Bill to)</div>
              <div className="font-bold text-[13px] text-black uppercase mt-0.5">
                {buyer.name || "Client Name Here"}
              </div>
              <div className="font-semibold text-[12px] text-black whitespace-pre-line leading-snug mt-0.5">
                {buyer.address || "Client Address Here"}
              </div>
              <div className="text-[11.5px] text-black mt-1">
                <span className="font-semibold">State Name :</span> {buyer.state || "State"},{" "}
                <span className="font-semibold">Code :</span> {buyer.stateCode || "00"}
              </div>
              {buyer.gstin && (
                <div className="text-[11.5px] text-black font-semibold mt-0.5">
                  <span>GSTIN/UIN:</span> {buyer.gstin}
                </div>
              )}
            </div>

            {/* Left Metadata Grid */}
            <div className="border-t border-black grid grid-cols-2 text-[11px]">
              {/* Col 1 */}
              <div className="border-r border-black">
                <div className="p-1.5 border-b border-black min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Invoice No.</div>
                  <div className="font-extrabold text-[12.5px]">{meta.invoiceNo || "PI-01"}</div>
                </div>
                <div className="p-1.5 border-b border-black min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Delivery Note</div>
                  <div className="font-semibold">{meta.deliveryNote || "\u00A0"}</div>
                </div>
                <div className="p-1.5 min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Reference No. & Date</div>
                  <div className="font-semibold">{meta.referenceNo || "\u00A0"}</div>
                </div>
              </div>

              {/* Col 2 */}
              <div>
                <div className="p-1.5 border-b border-black min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Dated</div>
                  <div className="font-bold text-[12px]">{meta.date || "DD/MM/YYYY"}</div>
                </div>
                <div className="p-1.5 border-b border-black min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Delivery Note Date</div>
                  <div className="font-semibold">{meta.deliveryNoteDate || "\u00A0"}</div>
                </div>
                <div className="p-1.5 min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Other References</div>
                  <div className="font-semibold">{meta.otherReferences || "\u00A0"}</div>
                </div>
              </div>
            </div>
          </div>

          {/* RIGHT HALF: Consignee (Ship to) + Destination / Dispatch Grid */}
          <div className="flex flex-col justify-between">
            {/* Consignee Block */}
            <div className="p-2 min-h-[70px]">
              <div className="text-[11px] text-slate-700 font-semibold">Consignee (Ship to)</div>
              <div className="font-bold text-[13px] text-black uppercase mt-0.5">
                {consignee.name || buyer.name || "Client / Consignee Name"}
              </div>
              <div className="font-semibold text-[12px] text-black whitespace-pre-line leading-snug mt-0.5">
                {consignee.address || buyer.address || "Delivery Address Here"}
              </div>
              <div className="text-[11.5px] text-black mt-1">
                <span className="font-semibold">State Name :</span> {consignee.state || buyer.state || "State"},{" "}
                <span className="font-semibold">Code :</span> {consignee.stateCode || buyer.stateCode || "00"}
              </div>
              {(consignee.gstin || buyer.gstin) && (
                <div className="text-[11.5px] text-black font-semibold mt-0.5">
                  <span>GSTIN/UIN:</span> {consignee.gstin || buyer.gstin}
                </div>
              )}
            </div>

            {/* Right Metadata Grid */}
            <div className="border-t border-black grid grid-cols-2 text-[11px]">
              {/* Destination Column */}
              <div className="border-r border-black p-1.5 flex flex-col justify-between">
                <div>
                  <div className="text-[10px] text-slate-600">Destination</div>
                  <div className="font-bold">{meta.destination || "\u00A0"}</div>
                </div>
              </div>

              {/* Col 2 */}
              <div>
                <div className="p-1.5 border-b border-black min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Dispatch Doc No.</div>
                  <div className="font-semibold">{meta.dispatchDocNo || "\u00A0"}</div>
                </div>
                <div className="p-1.5 border-b border-black min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Dispatched through</div>
                  <div className="font-semibold">{meta.dispatchedThrough || "\u00A0"}</div>
                </div>
                <div className="p-1.5 border-b border-black min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Mode/Terms of Payment</div>
                  <div className="font-semibold">{meta.paymentTerms || "\u00A0"}</div>
                </div>
                <div className="p-1.5 min-h-[32px]">
                  <div className="text-[10px] text-slate-600">Terms of Delivery</div>
                  <div className="font-semibold">{meta.termsOfDelivery || "\u00A0"}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* 4. Item Details Table */}
        <div className="border-b border-black">
          <table className="w-full border-collapse text-[11.5px]">
            <thead>
              <tr className="border-b border-black text-[11px] font-bold text-black text-center bg-slate-50">
                <th className="py-1.5 px-1.5 border-r border-black w-9 font-bold leading-tight">
                  <div>Sl</div>
                  <div>No.</div>
                </th>
                <th className="py-1.5 px-2.5 border-r border-black font-bold text-center">
                  <div>Description of</div>
                  <div>Goods and Services</div>
                </th>
                <th className="py-1.5 px-1.5 border-r border-black w-20 font-bold">HSN/SAC</th>
                <th className="py-1.5 px-2 border-r border-black w-20 font-bold">Quantity</th>
                <th className="py-1.5 px-2 border-r border-black w-24 font-bold">Rate</th>
                <th className="py-1.5 px-1.5 border-r border-black w-12 font-bold">per</th>
                <th className="py-1.5 px-2.5 w-28 font-bold text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item, idx) => {
                const qty = parseFloat(item.quantity) || 0;
                const rate = parseFloat(item.rate) || 0;
                const lineTotal = qty * rate;

                return (
                  <tr key={idx} className="align-top">
                    <td className="py-1.5 px-1.5 border-r border-black text-center font-semibold">
                      {idx + 1}
                    </td>
                    <td className="py-1.5 px-2.5 border-r border-black">
                      <div className="font-bold text-[12.5px] text-black">{item.description}</div>
                      {item.subtext && (
                        <div className="text-[11px] text-slate-800 italic whitespace-pre-line mt-0.5 leading-snug pl-2">
                          {item.subtext}
                        </div>
                      )}
                    </td>
                    <td className="py-1.5 px-1.5 border-r border-black text-center font-mono font-medium">
                      {item.hsn || "—"}
                    </td>
                    <td className="py-1.5 px-2 border-r border-black text-right font-bold whitespace-nowrap">
                      {qty} {item.unit || "Nos"}
                    </td>
                    <td className="py-1.5 px-2 border-r border-black text-right font-medium whitespace-nowrap">
                      {formatIndianCurrency(rate)}
                    </td>
                    <td className="py-1.5 px-1.5 border-r border-black text-center font-medium">
                      {item.unit || "Nos"}
                    </td>
                    <td className="py-1.5 px-2.5 text-right font-bold whitespace-nowrap text-[12px]">
                      {formatIndianCurrency(lineTotal)}
                    </td>
                  </tr>
                );
              })}

              {/* Spacer row */}
              <tr className="align-top h-6">
                <td className="border-r border-black"></td>
                <td className="border-r border-black"></td>
                <td className="border-r border-black"></td>
                <td className="border-r border-black"></td>
                <td className="border-r border-black"></td>
                <td className="border-r border-black"></td>
                <td className="text-right py-1 px-2.5 font-bold">
                  <div className="border-t border-black pt-0.5">
                    {formatIndianCurrency(totalTaxableValue)}
                  </div>
                </td>
              </tr>

              {/* Tax Breakup rows */}
              {taxBreakupList.map((taxItem, tIdx) => (
                <tr key={tIdx} className="align-top text-[11px]">
                  <td className="border-r border-black"></td>
                  <td className="border-r border-black px-2.5 py-0.5 text-right font-bold italic">
                    {taxItem.label}
                  </td>
                  <td className="border-r border-black"></td>
                  <td className="border-r border-black"></td>
                  <td className="border-r border-black px-2 py-0.5 text-right font-medium">
                    {taxItem.rateStr}
                  </td>
                  <td className="border-r border-black"></td>
                  <td className="px-2.5 py-0.5 text-right font-bold">
                    {formatIndianCurrency(taxItem.amount)}
                  </td>
                </tr>
              ))}

              {/* Total Summary Row */}
              <tr className="border-t border-black font-bold bg-slate-50/50">
                <td className="border-r border-black"></td>
                <td className="border-r border-black py-1.5 px-2.5 text-right font-bold">
                  Total
                </td>
                <td className="border-r border-black"></td>
                <td className="border-r border-black py-1.5 px-2 text-right font-extrabold whitespace-nowrap">
                  {totalQty} {items[0]?.unit || "Nos"}
                </td>
                <td className="border-r border-black"></td>
                <td className="border-r border-black"></td>
                <td className="py-1.5 px-2.5 text-right font-black text-[13px] whitespace-nowrap">
                  ₹ {formatIndianCurrency(grandTotal)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* 5. Amount in Words + E. & O.E */}
        <div className="border-b border-black p-2 flex items-center justify-between text-[11.5px]">
          <div>
            <span className="text-[11px] text-slate-700">Amount Chargeable (in words): </span>
            <span className="font-extrabold text-black uppercase">{amountInWords}</span>
          </div>
          <div className="font-bold italic text-[11px] pr-2 text-slate-700">
            E. & O.E
          </div>
        </div>

        {/* 6. HSN/SAC Tax Summary Table */}
        <div className="border-b border-black">
          <table className="w-full border-collapse text-[11px]">
            <thead>
              <tr className="border-b border-black text-center font-bold bg-slate-50">
                <th rowSpan="2" className="py-1 px-2 border-r border-black font-bold w-36">
                  HSN/SAC
                </th>
                <th rowSpan="2" className="py-1 px-2 border-r border-black font-bold text-right w-28">
                  Taxable<br />Value
                </th>
                {taxMode === "CGST_SGST" ? (
                  <>
                    <th colSpan="2" className="py-1 px-1 border-r border-black font-bold text-center">
                      CGST
                    </th>
                    <th colSpan="2" className="py-1 px-1 border-r border-black font-bold text-center">
                      SGST/UTGST
                    </th>
                  </>
                ) : (
                  <th colSpan="2" className="py-1 px-1 border-r border-black font-bold text-center">
                    Integrated Tax
                  </th>
                )}
                <th rowSpan="2" className="py-1 px-2 font-bold text-right w-28">
                  Total<br />Tax Amount
                </th>
              </tr>
              <tr className="border-b border-black text-center font-bold text-[10px] bg-slate-50">
                {taxMode === "CGST_SGST" ? (
                  <>
                    <th className="py-0.5 px-1 border-r border-black w-14 font-semibold">Rate</th>
                    <th className="py-0.5 px-2 border-r border-black w-24 font-bold text-right">Amount</th>
                    <th className="py-0.5 px-1 border-r border-black w-14 font-semibold">Rate</th>
                    <th className="py-0.5 px-2 border-r border-black w-24 font-bold text-right">Amount</th>
                  </>
                ) : (
                  <>
                    <th className="py-0.5 px-1 border-r border-black w-16 font-semibold">Rate</th>
                    <th className="py-0.5 px-2 border-r border-black font-bold text-right">Amount</th>
                  </>
                )}
              </tr>
            </thead>
            <tbody>
              {Object.values(hsnSummary).map((row, idx) => (
                <tr key={idx} className="border-b border-black text-center">
                  <td className="py-1 px-2 border-r border-black text-left font-mono font-medium">{row.hsn}</td>
                  <td className="py-1 px-2 border-r border-black text-right font-medium">
                    {formatIndianCurrency(row.taxableValue)}
                  </td>
                  {taxMode === "CGST_SGST" ? (
                    <>
                      <td className="py-1 px-1 border-r border-black">{row.cgstRate.toFixed(2)}%</td>
                      <td className="py-1 px-2 border-r border-black text-right font-bold">
                        {formatIndianCurrency(row.cgstAmount)}
                      </td>
                      <td className="py-1 px-1 border-r border-black">{row.sgstRate.toFixed(2)}%</td>
                      <td className="py-1 px-2 border-r border-black text-right font-bold">
                        {formatIndianCurrency(row.sgstAmount)}
                      </td>
                    </>
                  ) : (
                    <>
                      <td className="py-1 px-1 border-r border-black">{row.taxRate}%</td>
                      <td className="py-1 px-2 border-r border-black text-right font-bold">
                        {formatIndianCurrency(row.igstAmount)}
                      </td>
                    </>
                  )}
                  <td className="py-1 px-2 text-right font-bold">
                    {formatIndianCurrency(row.totalTax)}
                  </td>
                </tr>
              ))}

              {/* Total HSN Row */}
              <tr className="font-extrabold text-black bg-slate-50/50">
                <td className="py-1 px-2 border-r border-black text-right font-bold">Total</td>
                <td className="py-1 px-2 border-r border-black text-right font-bold">
                  {formatIndianCurrency(totalTaxableValue)}
                </td>
                {taxMode === "CGST_SGST" ? (
                  <>
                    <td className="border-r border-black"></td>
                    <td className="py-1 px-2 border-r border-black text-right font-extrabold">
                      {formatIndianCurrency(totalCgst)}
                    </td>
                    <td className="border-r border-black"></td>
                    <td className="py-1 px-2 border-r border-black text-right font-extrabold">
                      {formatIndianCurrency(totalSgst)}
                    </td>
                  </>
                ) : (
                  <>
                    <td className="border-r border-black"></td>
                    <td className="py-1 px-2 border-r border-black text-right font-extrabold">
                      {formatIndianCurrency(totalIgst)}
                    </td>
                  </>
                )}
                <td className="py-1 px-2 text-right font-extrabold">
                  {formatIndianCurrency(totalTaxSum)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* 7. Tax Amount in Words */}
        <div className="border-b border-black p-1.5 text-[11px]">
          <span className="text-slate-700">Tax Amount (in words) : </span>
          <span className="font-extrabold text-black uppercase">{taxInWords}</span>
        </div>

        {/* 8. Declaration & Bank Details & Signatory Box */}
        <div className="grid grid-cols-2 text-[11px]">
          
          {/* Left Column: Declaration / Terms */}
          <div className="p-2 border-r border-black flex flex-col justify-between">
            <div>
              <div className="underline text-[11px] text-black font-bold mb-1">
                Declaration
              </div>
              <p className="text-[10.5px] text-black leading-snug">
                {seller.declaration ||
                  "We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct."}
              </p>
            </div>
            {seller.jurisdiction && (
              <div className="text-[10px] text-slate-700 font-medium mt-2">
                Subject to {seller.jurisdiction} Jurisdiction
              </div>
            )}
          </div>

          {/* Right Column: Bank Details + Signatory Box */}
          <div className="flex flex-col justify-between">
            {/* Top: Company's Bank Details */}
            <div className="p-2">
              <div className="font-bold text-black text-[11px] mb-1">
                Company's Bank Details
              </div>
              <div className="space-y-0.5 text-[10.5px] text-black">
                <div className="flex">
                  <span className="w-36 flex-shrink-0 text-slate-700">A/c Holder's Name:</span>
                  <span className="font-bold uppercase">{bank.holderName || seller.name || "—"}</span>
                </div>
                <div className="flex">
                  <span className="w-36 flex-shrink-0 text-slate-700">Bank Name :</span>
                  <span className="font-bold">{bank.bankName || "—"}</span>
                </div>
                <div className="flex">
                  <span className="w-36 flex-shrink-0 text-slate-700">A/c No. :</span>
                  <span className="font-extrabold font-mono">{bank.accountNo || "—"}</span>
                </div>
                <div className="flex">
                  <span className="w-36 flex-shrink-0 text-slate-700">Branch & IFS Code :</span>
                  <span className="font-bold">{bank.branch || "—"} & {bank.ifsc || "—"}</span>
                </div>
                {bank.swiftCode && (
                  <div className="flex">
                    <span className="w-36 flex-shrink-0 text-slate-700">SWIFT Code :</span>
                    <span className="font-bold">{bank.swiftCode}</span>
                  </div>
                )}
              </div>
            </div>

            {/* Bottom: Authorised Signatory Box */}
            <div className="border-t border-black p-2 min-h-[70px] flex flex-col justify-between text-right">
              <div className="text-[11px] text-black">
                for <span className="font-bold">{seller.name || "Company Name"}</span>
              </div>
              <div className="mt-8 text-[11px] font-bold text-black text-right pr-2">
                Authorised Signatory
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
