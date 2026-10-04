import '../models/invoice_model.dart';

class SampleData {
  static Invoice get sampleInvoice => const Invoice(
        id: null,
        invoiceTitle: 'PROFORMA INVOICE',
        taxMode: TaxMode.cgstSgst,
        roundOff: 0.02,
        seller: SellerDetails(
          name: 'The Kishan Bharti Coop. M.P. Society Ltd.',
          address: 'Additonal Anaj Mandi ShopNo-1-2 Mandi Adampur',
          gstin: '06AAEAT5833H1ZE',
          state: 'Haryana',
          stateCode: '06',
          email: 'kishanbharti2248@gmail.com',
          phone: '',
          jurisdiction: 'Hisar',
          declaration:
              'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
          logoUrl: 'assets/images/coop-logo.png',
          signatureUrl: '',
        ),
        metadata: InvoiceMetadata(
          invoiceNo: '1',
          date: '29/09/2026',
          deliveryNote: '',
          deliveryNoteDate: '',
          referenceNo: '',
          otherReferences: '',
          destination: '',
          dispatchDocNo: '',
          dispatchedThrough: '',
          paymentTerms: '',
          termsOfDelivery: '',
        ),
        buyer: BuyerDetails(
          name: 'SATBIR SINGH S/O JAGDISH',
          address: 'VPO SISHWAL TEHSIL MANDI ADAMPUR HISAR',
          state: 'Haryana',
          stateCode: '06',
          gstin: '',
        ),
        consignee: ConsigneeDetails(
          name: 'SATBIR SINGH S/O JAGDISH',
          address: 'VPO SISHWAL TEHSIL MANDI ADAMPUR HISAR',
          state: 'Haryana',
          stateCode: '06',
          gstin: '',
        ),
        items: [
          InvoiceItem(
            description: 'Solar Power Generating System 3+2Kwp',
            subtext:
                'Waaree 580wp Topcon Dcr\nPv Module 5 Pcs\nPolycab/microtek 5kw Inverter\nWaaree 590wp Ndcr 4 Pv Module',
            hsn: '854140',
            quantity: 1,
            unit: 'set',
            rate: 213333.33,
            taxRate: 5,
          ),
          InvoiceItem(
            description: 'Installation and Commissioning 5KW',
            subtext:
                'Solar Mountaning Structure\nAcdb and Dcdb Boxes\n3 Earthing and 1 La\n4mm Microtek Dc Cable\n6mm Copper Flexible Cable\nMc4 Connector, Cpvc Pipe Fitting and\nOther Solar Bos',
            hsn: '995468',
            quantity: 1,
            unit: 'set',
            rate: 81355.93,
            taxRate: 18,
          ),
        ],
        bankDetails: BankDetails(
          holderName: 'The Kishan Bharti Coop. M.P. Society Ltd.',
          bankName: 'State Bank of India C/A',
          accountNo: '39302189235',
          ifsc: 'SBIN00011845',
          branch: 'Mandi Adampur',
          swiftCode: 'SBININBB',
        ),
      );

  static Invoice get newEmptyInvoice => Invoice(
        id: null,
        invoiceTitle: 'PROFORMA INVOICE',
        taxMode: TaxMode.cgstSgst,
        roundOff: 0.02,
        seller: const SellerDetails(
          name: 'The Kishan Bharti Coop. M.P. Society Ltd.',
          address: 'Additonal Anaj Mandi ShopNo-1-2 Mandi Adampur',
          gstin: '06AAEAT5833H1ZE',
          state: 'Haryana',
          stateCode: '06',
          email: 'kishanbharti2248@gmail.com',
          phone: '',
          jurisdiction: 'Hisar',
          declaration:
              'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
          logoUrl: 'assets/images/coop-logo.png',
          signatureUrl: '',
        ),
        metadata: InvoiceMetadata(
          invoiceNo: '',
          date: '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
        ),
        buyer: const BuyerDetails(
          name: '',
          address: '',
          state: 'Haryana',
          stateCode: '06',
          gstin: '',
        ),
        consignee: const ConsigneeDetails(
          name: '',
          address: '',
          state: 'Haryana',
          stateCode: '06',
          gstin: '',
        ),
        items: const [
          InvoiceItem(
            description: 'Solar Power Generating System 3+2Kwp',
            subtext:
                'Waaree 580wp Topcon Dcr\nPv Module 5 Pcs\nPolycab/microtek 5kw Inverter\nWaaree 590wp Ndcr 4 Pv Module',
            hsn: '854140',
            quantity: 1,
            unit: 'set',
            rate: 213333.33,
            taxRate: 5,
          ),
          InvoiceItem(
            description: 'Installation and Commissioning 5KW',
            subtext:
                'Solar Mountaning Structure\nAcdb and Dcdb Boxes\n3 Earthing and 1 La\n4mm Microtek Dc Cable\n6mm Copper Flexible Cable\nMc4 Connector, Cpvc Pipe Fitting and\nOther Solar Bos',
            hsn: '995468',
            quantity: 1,
            unit: 'set',
            rate: 81355.93,
            taxRate: 18,
          ),
        ],
        bankDetails: const BankDetails(
          holderName: 'The Kishan Bharti Coop. M.P. Society Ltd.',
          bankName: 'State Bank of India C/A',
          accountNo: '39302189235',
          ifsc: 'SBIN00011845',
          branch: 'Mandi Adampur',
          swiftCode: 'SBININBB',
        ),
      );
}
