import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../models/invoice.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import 'invoice_form_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final DatabaseService _db = DatabaseService();
  final PDFService _pdfService = PDFService();
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    final invoices = await _db.getInvoices();

    setState(() {
      _invoices = invoices;
      _filteredInvoices = invoices;
      _isLoading = false;
    });
  }

  void _filterInvoices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = _invoices;
      } else {
        _filteredInvoices = _invoices
            .where((invoice) =>
                invoice.invoiceNumber.toLowerCase().contains(query.toLowerCase()) ||
                invoice.invoiceTo.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _navigateToInvoiceForm([Invoice? invoice]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceFormScreen(invoice: invoice),
      ),
    );

    if (result == true) {
      _loadInvoices();
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice ${invoice.invoiceNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteInvoice(invoice.id!);
      _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted successfully')),
        );
      }
    }
  }

  Future<void> _exportToPDF(Invoice invoice) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      await _pdfService.generateInvoicePDF(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated and saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: AppTextStyles.heading3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(invoice.invoiceDate)),
                      _buildDetailRow('Invoice To', invoice.invoiceTo),
                      _buildDetailRow('Address', invoice.invoiceToAddress),
                      _buildDetailRow('SAC', invoice.sac),
                      _buildDetailRow('Place of Supply', invoice.placeOfSupply),
                      const SizedBox(height: 16),
                      const Text('Items:', style: AppTextStyles.heading4),
                      const SizedBox(height: 8),
                      Table(
                        border: TableBorder.all(color: AppColors.border),
                        columnWidths: const {
                          0: FixedColumnWidth(40),
                          1: FlexColumnWidth(3),
                          2: FixedColumnWidth(50),
                          3: FixedColumnWidth(80),
                          4: FixedColumnWidth(80),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: AppColors.background),
                            children: [
                              _buildTableCell('S.No', isHeader: true),
                              _buildTableCell('Particulars', isHeader: true),
                              _buildTableCell('QTY', isHeader: true),
                              _buildTableCell('Rate', isHeader: true),
                              _buildTableCell('Amount', isHeader: true),
                            ],
                          ),
                          ...invoice.items.map((item) => TableRow(
                                children: [
                                  _buildTableCell(item.serialNumber.toString()),
                                  _buildTableCell(item.particulars),
                                  _buildTableCell(item.quantity.toString()),
                                  _buildTableCell('₹${item.rate.toStringAsFixed(2)}'),
                                  _buildTableCell('₹${item.amount.toStringAsFixed(2)}'),
                                ],
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTotalRow('Subtotal', invoice.subtotal),
                      _buildTotalRow('CGST (9%)', invoice.cgstAmount),
                      _buildTotalRow('SGST (9%)', invoice.sgstAmount),
                      const Divider(thickness: 2),
                      _buildTotalRow('Grand Total', invoice.grandTotal, isBold: true),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToInvoiceForm(invoice);
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _exportToPDF(invoice);
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Export PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.label,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: isHeader ? AppTextStyles.label : AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? AppTextStyles.heading4 : AppTextStyles.bodyMedium,
          ),
          Text(
            '₹ ${amount.toStringAsFixed(2)}',
            style: isBold ? AppTextStyles.heading4 : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterInvoices,
              decoration: InputDecoration(
                hintText: 'Search invoices...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Invoice list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No invoices found'
                                  : 'No matching invoices',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchController.text.isEmpty)
                              TextButton(
                                onPressed: () => _navigateToInvoiceForm(),
                                child: const Text('Create your first invoice'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInvoices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _showInvoiceDetails(invoice),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            invoice.invoiceNumber,
                                            style: AppTextStyles.heading4,
                                          ),
                                          PopupMenuButton(
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'view',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.visibility, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('View'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'pdf',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.picture_as_pdf, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Export PDF'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete,
                                                        size: 20, color: AppColors.error),
                                                    SizedBox(width: 8),
                                                    Text('Delete',
                                                        style: TextStyle(color: AppColors.error)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              if (value == 'view') {
                                                _showInvoiceDetails(invoice);
                                              } else if (value == 'edit') {
                                                _navigateToInvoiceForm(invoice);
                                              } else if (value == 'pdf') {
                                                _exportToPDF(invoice);
                                              } else if (value == 'delete') {
                                                _deleteInvoice(invoice);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        invoice.invoiceTo,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
                                            style: AppTextStyles.caption,
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            invoice.placeOfSupply,
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Grand Total',
                                            style: AppTextStyles.label,
                                          ),
                                          Text(
                                            '₹ ${invoice.grandTotal.toStringAsFixed(2)}',
                                            style: AppTextStyles.heading4.copyWith(
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToInvoiceForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textLight),
      ),
    );
  }
}
