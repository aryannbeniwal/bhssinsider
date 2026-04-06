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
    try {
      // Load font that supports rupee symbol
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          // Get theme from context for nested tables
          final theme = pw.Theme.of(context);

          return [
          // Company header
          _buildHeader(),
          // pw.SizedBox(height: 20),

          // Invoice of Supply title
          pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.black, width: 1),
                left: pw.BorderSide(color: PdfColors.black, width: 2),
                right: pw.BorderSide(color: PdfColors.black, width: 2),
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: pw.Text(
              AppConstants.invoiceTitle,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          // pw.SizedBox(height: 20),

          // Invoice details section
          pw.Table(
            border: pw.TableBorder(
              left: pw.BorderSide(color: PdfColors.black, width: 2),
              right: pw.BorderSide(color: PdfColors.black, width: 2),
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              verticalInside: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  // Left column - Invoice To
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
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
                  // Right column - Invoice info
                  pw.Container(
                    child: pw.Table(
                      border: pw.TableBorder(
                        horizontalInside: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                      children: [
                        _buildInfoTableRow('Invoice No.', invoice.invoiceNumber, font: theme.defaultTextStyle.font),
                        _buildInfoTableRow(
                          'Invoice Date',
                          DateFormat('dd/MM/yyyy').format(invoice.invoiceDate),
                          font: theme.defaultTextStyle.font,
                        ),
                        _buildInfoTableRow('SAC', invoice.sac, font: theme.defaultTextStyle.font),
                        _buildInfoTableRow('Place of Supply', invoice.placeOfSupply, font: theme.defaultTextStyle.font),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // pw.SizedBox(height: 8),
          // Items table
          _buildItemsTable(invoice, font: theme.defaultTextStyle.font),
          pw.SizedBox(height: 8),
          // Totals section
          pw.Table(
            border: pw.TableBorder(
              top: pw.BorderSide(color: PdfColors.black, width: 1),
              left: pw.BorderSide(color: PdfColors.black, width: 2),
              right: pw.BorderSide(color: PdfColors.black, width: 2),
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              verticalInside: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  // Amount in words and Terms
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Terms & Conditions / Notes
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Terms & Conditions:',
                              style: pw.TextStyle(
                                font: theme.defaultTextStyle.font,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              '1. Payment due within 05 days of invoice date.',
                              style: pw.TextStyle(font: theme.defaultTextStyle.font, fontSize: 9),
                            ),
                            pw.Text(
                              '2. Please make cheques payable to ${AppConstants.companyName}.',
                              style: pw.TextStyle(font: theme.defaultTextStyle.font, fontSize: 9),
                            ),
                            pw.Text(
                              '3. Late payments may incur additional charges.',
                              style: pw.TextStyle(font: theme.defaultTextStyle.font, fontSize: 9),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 15),
                        // Amount in words
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Amount in Words:',
                              style: pw.TextStyle(
                                font: theme.defaultTextStyle.font,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              _numberToWords(invoice.grandTotal),
                              style: pw.TextStyle(font: theme.defaultTextStyle.font, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Totals
                  pw.Table(
                    border: pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                    children: [
                      _buildTotalTableRow('Total', invoice.subtotal, font: theme.defaultTextStyle.font),
                      _buildTotalTableRow('CGST (${invoice.cgstRate}%)', invoice.cgstAmount, font: theme.defaultTextStyle.font),
                      _buildTotalTableRow('SGST (${invoice.sgstRate}%)', invoice.sgstAmount, font: theme.defaultTextStyle.font),
                      _buildTotalTableRow('Round Off', invoice.roundOff, showSign: true, font: theme.defaultTextStyle.font),
                      _buildTotalTableRow('Grand Total', invoice.grandTotal, isBold: true, decimals: 0, font: theme.defaultTextStyle.font),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // pw.SizedBox(height: 20),

          // Bank details and signature
          pw.Table(
            border: pw.TableBorder(
              left: pw.BorderSide(color: PdfColors.black, width: 2),
              right: pw.BorderSide(color: PdfColors.black, width: 2),
              bottom: pw.BorderSide(color: PdfColors.black, width: 2),
              verticalInside: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  // Bank details
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
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
                          'Bank Name: ${AppConstants.bankName}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
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
                  // Signature
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'For ${AppConstants.companyName}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 60),
                        pw.Text(
                          'Authorized Signatory',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];
        },
      ),
    );

      // Save the PDF
      await _savePDF(pdf, invoice.invoiceNumber);

      // Also allow printing/sharing
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e, stackTrace) {
      print('PDF Generation Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to generate PDF: $e');
    }
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 2),
          left: pw.BorderSide(color: PdfColors.black, width: 2),
          right: pw.BorderSide(color: PdfColors.black, width: 2),
          bottom: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
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

  pw.TableRow _buildInfoTableRow(String label, String value, {pw.Font? font}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice, {pw.Font? font}) {
    return pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfColors.black, width: 2),
        right: pw.BorderSide(color: PdfColors.black, width: 2),
        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
        horizontalInside: pw.BorderSide(color: PdfColors.black, width: 1),
        verticalInside: pw.BorderSide(color: PdfColors.black, width: 1),
      ),
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
            _buildTableHeader('S.No', font: font),
            _buildTableHeader('Particulars', font: font),
            _buildTableHeader('QTY', font: font),
            _buildTableHeader('Rate', font: font),
            _buildTableHeader('Amount', font: font),
          ],
        ),
        // Data rows
        ...invoice.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.serialNumber.toString(), font: font),
                _buildTableCell(item.particulars, align: pw.TextAlign.left, font: font),
                _buildTableCell(item.quantity.toString(), font: font),
                _buildTableCell('₹${item.rate.toStringAsFixed(2)}', font: font),
                _buildTableCell('₹${item.amount.toStringAsFixed(2)}', font: font),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, {pw.Font? font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.center, pw.Font? font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.TableRow _buildTotalTableRow(String label, double amount, {bool isBold = false, int decimals = 2, bool showSign = false, pw.Font? font}) {
    String formattedAmount;
    if (showSign) {
      String sign = amount >= 0 ? '+' : '';
      formattedAmount = '$sign₹${amount.toStringAsFixed(decimals)}';
    } else {
      formattedAmount = '₹${amount.toStringAsFixed(decimals)}';
    }

    return pw.TableRow(
      decoration: isBold ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            formattedAmount,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
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

  String _sanitizeFilename(String filename) {
    // Remove or replace invalid characters for filenames
    // Invalid: / \ : * ? " < > |
    return filename
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll(':', '-')
        .replaceAll('*', '-')
        .replaceAll('?', '-')
        .replaceAll('"', '-')
        .replaceAll('<', '-')
        .replaceAll('>', '-')
        .replaceAll('|', '-');
  }

  Future<String> _savePDF(pw.Document pdf, String invoiceNumber) async {
    try {
      // Generate PDF bytes first
      final bytes = await pdf.save();
      print('PDF bytes generated: ${bytes.length} bytes');

      // Sanitize the invoice number for use in filename
      final safeFilename = _sanitizeFilename(invoiceNumber);
      print('Original invoice number: $invoiceNumber');
      print('Sanitized filename: $safeFilename');

      // Get the app's documents directory (always works, no permission needed)
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = directory.path;
      print('Using directory: $dirPath');

      // Create BHSS_Invoices subfolder
      final invoicesPath = '$dirPath/BHSS_Invoices';
      print('Creating invoices directory: $invoicesPath');

      final invoicesDir = Directory(invoicesPath);

      // Create directory with recursive flag
      await invoicesDir.create(recursive: true);
      print('Directory created/verified');

      // Save PDF file with sanitized filename
      final filePath = '$invoicesPath/$safeFilename.pdf';
      print('Saving PDF to: $filePath');

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Verify file was created
      final exists = await file.exists();
      final size = await file.length();
      print('PDF saved successfully - Exists: $exists, Size: $size bytes');

      return filePath;
    } catch (e, stackTrace) {
      print('Error in _savePDF: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to save PDF: $e');
    }
  }
}
