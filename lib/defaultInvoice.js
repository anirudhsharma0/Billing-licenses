/**
 * Exact replica data for The Kishan Bharti Coop. M.P. Society Ltd.
 */
export const defaultInvoice = {
  id: null,
  taxMode: "CGST_SGST",
  roundOff: -0.58, // Adjusts 3,20,000.58 down to exactly 3,20,000.00

  seller: {
    name: "The Kishan Bharti Coop. M.P. Society Ltd.",
    address: "Additonal Anaj Mandi ShopNo-1-2 Mandi Adampur",
    gstin: "06AAEAT5833H1ZE",
    state: "Haryana",
    stateCode: "06",
    email: "kishanbharti2248@gmail.com",
    phone: "",
    jurisdiction: "Hisar",
    declaration: "We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.",
    logoUrl: "/coop-logo.png",
    signatureUrl: "",
  },

  metadata: {
    invoiceNo: "1",
    date: "29/09/2026",
    deliveryNote: "",
    deliveryNoteDate: "",
    referenceNo: "",
    otherReferences: "",
    destination: "",
    dispatchDocNo: "",
    dispatchedThrough: "",
    paymentTerms: "",
    termsOfDelivery: "",
  },

  buyer: {
    name: "SATBIR SINGH S/O JAGDISH",
    address: "VPO SISHWAL TEHSIL MANDI ADAMPUR HISAR",
    state: "Haryana",
    stateCode: "06",
    gstin: "",
  },

  consignee: {
    name: "SATBIR SINGH S/O JAGDISH",
    address: "VPO SISHWAL TEHSIL MANDI ADAMPUR HISAR",
    state: "Haryana",
    stateCode: "06",
    gstin: "",
  },

  items: [
    {
      description: "Solar Power Generating System 3+2Kwp",
      subtext: "Waaree 580wp Topcon Dcr\nPv Module 5 Pcs\nPolycab/microtek 5kw Inverter\nWaaree 590wp Ndcr 4 Pv Module",
      hsn: "854140",
      quantity: 1,
      unit: "set",
      rate: 213333.33,
      taxRate: 5,
    },
    {
      description: "Installation and Commissioning 5KW",
      subtext: "Solar Mountaning Structure\nAcdb and Dcdb Boxes\n3 Earthing and 1 La\n4mm Microtek Dc Cable\n6mm Copper Flexible Cable\nMc4 Connector, Cpvc Pipe Fitting and\nOther Solar Bos",
      hsn: "995468",
      quantity: 1,
      unit: "set",
      rate: 81355.93,
      taxRate: 18,
    },
  ],

  bankDetails: {
    holderName: "The Kishan Bharti Coop. M.P. Society Ltd.",
    bankName: "State Bank of India C/A",
    accountNo: "39302189235",
    ifsc: "SBIN00011845",
    branch: "Mandi Adampur",
    swiftCode: "SBININBB",
  },
};
