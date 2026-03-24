import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';
import '../utils/constants.dart';

class PDFService {
  Future<void> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Company header
          _buildHeader(),
          pw.SizedBox(height: 20),

          // Invoice of Supply title
          pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Text(
              AppConstants.invoiceTitle,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Invoice details section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left column - Invoice To
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Invoice To:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        invoice.invoiceTo,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        invoice.invoiceToAddress,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Right column - Invoice info
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _buildInfoRow('Invoice No.', invoice.invoiceNumber),
                    _buildInfoRow(
                      'Invoice Date',
                      DateFormat('dd/MM/yyyy').format(invoice.invoiceDate),
                    ),
                    _buildInfoRow('SAC', invoice.sac),
                    _buildInfoRow('Place of Supply', invoice.placeOfSupply),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Items table
          _buildItemsTable(invoice),
          pw.SizedBox(height: 20),

          // Totals section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Amount in words
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Amount in Words:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _numberToWords(invoice.grandTotal),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Totals
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    children: [
                      _buildTotalRow('Total', invoice.subtotal),
                      pw.Divider(),
                      _buildTotalRow('CGST (${invoice.cgstRate}%)', invoice.cgstAmount),
                      _buildTotalRow('SGST (${invoice.sgstRate}%)', invoice.sgstAmount),
                      pw.Divider(thickness: 2),
                      _buildTotalRow('Grand Total', invoice.grandTotal, isBold: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Bank details and signature
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Bank details
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bank Details:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Account Name: ${AppConstants.bankAccountName}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Account Number: ${AppConstants.bankAccountNumber}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'IFSC Code: ${AppConstants.bankIFSC}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Signature
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Text(
                        'Authorized Signature',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Save the PDF
    await _savePDF(pdf, invoice.invoiceNumber);

    // Also allow printing/sharing
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        color: PdfColors.grey300,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            AppConstants.companyName,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            AppConstants.companyAddress,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Contact: ${AppConstants.companyPhone1}, ${AppConstants.companyPhone2}',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'Email: ${AppConstants.companyEmail}',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'GSTIN: ${AppConstants.companyGSTIN}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      margin: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(90),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('S.No'),
            _buildTableHeader('Particulars'),
            _buildTableHeader('QTY'),
            _buildTableHeader('Rate'),
            _buildTableHeader('Amount'),
          ],
        ),
        // Data rows
        ...invoice.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.serialNumber.toString()),
                _buildTableCell(item.particulars, align: pw.TextAlign.left),
                _buildTableCell(item.quantity.toString()),
                _buildTableCell('₹${item.rate.toStringAsFixed(2)}'),
                _buildTableCell('₹${item.amount.toStringAsFixed(2)}'),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '₹ ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _numberToWords(double number) {
    final int amount = number.toInt();
    if (amount == 0) return 'Zero Rupees Only';

    final List<String> ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    final List<String> tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String result = '';

    if (amount >= 10000000) {
      // Crores
      int crores = amount ~/ 10000000;
      result += '${_convertHundreds(crores)} Crore ';
      int remainder = amount % 10000000;
      if (remainder > 0) {
        result += _numberToWords(remainder.toDouble()).replaceAll(' Rupees Only', ' ');
      }
    } else if (amount >= 100000) {
      // Lakhs
      int lakhs = amount ~/ 100000;
      result += '${_convertHundreds(lakhs)} Lakh ';
      int remainder = amount % 100000;
      if (remainder > 0) {
        result += _numberToWords(remainder.toDouble()).replaceAll(' Rupees Only', ' ');
      }
    } else if (amount >= 1000) {
      // Thousands
      int thousands = amount ~/ 1000;
      result += '${_convertHundreds(thousands)} Thousand ';
      int remainder = amount % 1000;
      if (remainder > 0) {
        result += _numberToWords(remainder.toDouble()).replaceAll(' Rupees Only', ' ');
      }
    } else if (amount >= 100) {
      // Hundreds
      result += _convertHundreds(amount);
    } else if (amount >= 20) {
      // Tens
      result += tens[amount ~/ 10];
      if (amount % 10 > 0) {
        result += ' ${ones[amount % 10]}';
      }
    } else {
      // Ones
      result += ones[amount];
    }

    return '${result.trim()} Rupees Only';
  }

  String _convertHundreds(int number) {
    final List<String> ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    final List<String> tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String result = '';

    if (number >= 100) {
      result += '${ones[number ~/ 100]} Hundred ';
      number %= 100;
    }

    if (number >= 20) {
      result += tens[number ~/ 10];
      if (number % 10 > 0) {
        result += ' ${ones[number % 10]}';
      }
    } else if (number > 0) {
      result += ones[number];
    }

    return result.trim();
  }

  Future<void> _savePDF(pw.Document pdf, String invoiceNumber) async {
    try {
      final Directory? directory = await getExternalStorageDirectory();
      if (directory != null) {
        final String dirPath = '${directory.path}/BHSS_Invoices';
        await Directory(dirPath).create(recursive: true);

        final String filePath = '$dirPath/$invoiceNumber.pdf';
        final File file = File(filePath);
        await file.writeAsBytes(await pdf.save());
      }
    } catch (e) {
      // Fallback to app documents directory
      final Directory directory = await getApplicationDocumentsDirectory();
      final String dirPath = '${directory.path}/BHSS_Invoices';
      await Directory(dirPath).create(recursive: true);

      final String filePath = '$dirPath/$invoiceNumber.pdf';
      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());
    }
  }
}
