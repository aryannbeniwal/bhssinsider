import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../utils/constants.dart';
import '../../models/invoice.dart';
import '../../services/database_service.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;

  const InvoiceFormScreen({super.key, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();

  late TextEditingController _invoiceNumberController;
  late TextEditingController _invoiceToController;
  late TextEditingController _invoiceToAddressController;
  late TextEditingController _sacController;
  late TextEditingController _placeOfSupplyController;

  DateTime _invoiceDate = DateTime.now();
  List<InvoiceItemWidget> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeItems();
  }

  void _initializeControllers() {
    _invoiceNumberController = TextEditingController(
      text: widget.invoice?.invoiceNumber ?? '',
    );
    _invoiceToController = TextEditingController(
      text: widget.invoice?.invoiceTo ?? '',
    );
    _invoiceToAddressController = TextEditingController(
      text: widget.invoice?.invoiceToAddress ?? '',
    );
    _sacController = TextEditingController(
      text: widget.invoice?.sac ?? '',
    );
    _placeOfSupplyController = TextEditingController(
      text: widget.invoice?.placeOfSupply ?? '',
    );

    if (widget.invoice != null) {
      _invoiceDate = widget.invoice!.invoiceDate;
    } else {
      _generateInvoiceNumber();
    }
  }

  void _initializeItems() {
    if (widget.invoice != null && widget.invoice!.items.isNotEmpty) {
      _items = widget.invoice!.items
          .map((item) => InvoiceItemWidget(
                key: UniqueKey(),
                serialNumber: item.serialNumber,
                particulars: item.particulars,
                quantity: item.quantity,
                rate: item.rate,
                particularsController: TextEditingController(text: item.particulars),
                quantityController: TextEditingController(text: item.quantity.toString()),
                rateController: TextEditingController(text: item.rate.toString()),
              ))
          .toList();
    } else {
      _addItem();
    }
  }

  Future<void> _generateInvoiceNumber() async {
    final invoiceNumber = await _db.getNextInvoiceNumber();
    _invoiceNumberController.text = invoiceNumber;
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _invoiceToController.dispose();
    _invoiceToAddressController.dispose();
    _sacController.dispose();
    _placeOfSupplyController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItemWidget(
        key: UniqueKey(),
        serialNumber: _items.length + 1,
        particulars: '',
        quantity: 0,
        rate: 0.0,
        particularsController: TextEditingController(),
        quantityController: TextEditingController(),
        rateController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _copyItem(int index) {
    final itemToCopy = _items[index];
    setState(() {
      // Insert the copied item right below the current item
      _items.insert(
        index + 1,
        InvoiceItemWidget(
          key: UniqueKey(),
          serialNumber: index + 2,
          particulars: itemToCopy.particularsController.text,
          quantity: int.tryParse(itemToCopy.quantityController.text) ?? 0,
          rate: double.tryParse(itemToCopy.rateController.text) ?? 0.0,
          particularsController: TextEditingController(text: itemToCopy.particularsController.text),
          quantityController: TextEditingController(text: itemToCopy.quantityController.text),
          rateController: TextEditingController(text: itemToCopy.rateController.text),
        ),
      );
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _invoiceDate) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.getAmount());
  }

  double _calculateCGST() {
    return _calculateSubtotal() * AppConstants.cgstRate / 100;
  }

  double _calculateSGST() {
    return _calculateSubtotal() * AppConstants.sgstRate / 100;
  }

  double _calculateTotalBeforeRounding() {
    return _calculateSubtotal() + _calculateCGST() + _calculateSGST();
  }

  double _calculateGrandTotal() {
    return _calculateTotalBeforeRounding().round().toDouble();
  }

  double _calculateRoundOff() {
    return _calculateGrandTotal() - _calculateTotalBeforeRounding();
  }

  String _numberToWords(double number) {
    // Simple implementation for converting numbers to words
    // This is a basic version - you can enhance it
    final int amount = number.toInt();
    if (amount == 0) return 'ZERO RUPEES ONLY';

    final List<String> ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    final List<String> tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    if (amount < 20) {
      return '${ones[amount]} RUPEES ONLY'.toUpperCase();
    } else if (amount < 100) {
      return '${tens[amount ~/ 10]} ${ones[amount % 10]} RUPEES ONLY'.toUpperCase();
    } else if (amount < 1000) {
      return '${ones[amount ~/ 100]} Hundred ${_numberToWords(amount % 100).replaceAll(' RUPEES ONLY', '')} RUPEES ONLY'.toUpperCase();
    } else if (amount < 100000) {
      return '${_numberToWords(amount / 1000).replaceAll(' RUPEES ONLY', '')} Thousand ${_numberToWords(amount % 1000).replaceAll(' RUPEES ONLY', '')} RUPEES ONLY'.toUpperCase();
    } else {
      return '${_numberToWords(amount / 100000).replaceAll(' RUPEES ONLY', '')} Lakh ${_numberToWords(amount % 100000).replaceAll(' RUPEES ONLY', '')} RUPEES ONLY'.toUpperCase();
    }
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      // Validate items
      bool allItemsValid = true;
      for (var item in _items) {
        if (!item.validate()) {
          allItemsValid = false;
          break;
        }
      }

      if (!allItemsValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all item details'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final invoiceItems = _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return InvoiceItem(
            serialNumber: index + 1,
            particulars: item.particularsController.text.trim(),
            quantity: int.parse(item.quantityController.text.trim()),
            rate: double.parse(item.rateController.text.trim()),
          );
        }).toList();

        final invoice = Invoice(
          id: widget.invoice?.id,
          invoiceNumber: _invoiceNumberController.text.trim(),
          invoiceDate: _invoiceDate,
          invoiceTo: _invoiceToController.text.trim(),
          invoiceToAddress: _invoiceToAddressController.text.trim(),
          sac: _sacController.text.trim(),
          placeOfSupply: _placeOfSupplyController.text.trim(),
          items: invoiceItems,
        );

        if (widget.invoice == null) {
          await _db.insertInvoice(invoice);
        } else {
          await _db.updateInvoice(invoice);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.invoice == null
                    ? 'Invoice created successfully'
                    : 'Invoice updated successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'New Invoice' : 'Edit Invoice'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Company details header
              Card(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left column - Company details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.companyName,
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppConstants.companyAddress,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact: ${AppConstants.companyPhone1}, ${AppConstants.companyPhone2}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              'Email: ${AppConstants.companyEmail}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'GSTIN: ${AppConstants.companyGSTIN}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right column - Logo only
                      SizedBox(
                        width: 80,
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo_without_bg.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice of Supply
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppConstants.invoiceTitle,
                    style: AppTextStyles.heading3,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Invoice To:',
                                  style: AppTextStyles.label,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _invoiceToController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? 'Required' : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _invoiceToAddressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Address',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _invoiceNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Invoice No.',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? 'Required' : null,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('dd/MM/yyyy').format(_invoiceDate)),
                                        const Icon(Icons.calendar_today, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _sacController,
                                  decoration: const InputDecoration(
                                    labelText: 'SAC',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? 'Required' : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _placeOfSupplyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Place of Supply',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items table
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items',
                            style: AppTextStyles.heading4,
                          ),
                          ElevatedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InvoiceItemWidget(
                              key: _items[index].key,
                              serialNumber: index + 1,
                              particulars: _items[index].particulars,
                              quantity: _items[index].quantity,
                              rate: _items[index].rate,
                              onChanged: () => setState(() {}),
                              onCopy: () => _copyItem(index),
                              onDelete: _items.length > 1 ? () => _removeItem(index) : null,
                              particularsController: _items[index].particularsController,
                              quantityController: _items[index].quantityController,
                              rateController: _items[index].rateController,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Totals
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Summary',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: 12),
                      _buildTotalRow('Subtotal', _calculateSubtotal()),
                      const Divider(),
                      _buildTotalRow('CGST (${AppConstants.cgstRate}%)', _calculateCGST()),
                      _buildTotalRow('SGST (${AppConstants.sgstRate}%)', _calculateSGST()),
                      const Divider(),
                      _buildTotalRow(
                        'Total Before Rounding',
                        _calculateTotalBeforeRounding(),
                        isSubtle: true,
                      ),
                      _buildTotalRow(
                        'Round Off',
                        _calculateRoundOff(),
                        showSign: true,
                        color: _calculateRoundOff() >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const Divider(thickness: 2),
                      _buildTotalRow(
                        'Grand Total',
                        _calculateGrandTotal(),
                        isBold: true,
                        decimals: 0,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Amount in Words:',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _numberToWords(_calculateGrandTotal()),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bank details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bank Details',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: 8),
                      Text('Bank Name: ${AppConstants.bankName}'),
                      Text('Account Name: ${AppConstants.bankAccountName}'),
                      Text('Account Number: ${AppConstants.bankAccountNumber}'),
                      Text('IFSC Code: ${AppConstants.bankIFSC}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textLight,
                          ),
                        ),
                      )
                    : Text(
                        widget.invoice == null ? 'Create Invoice' : 'Update Invoice',
                        style: AppTextStyles.button,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    int decimals = 2,
    bool showSign = false,
    bool isSubtle = false,
    Color? color,
  }) {
    String formattedAmount;
    if (showSign) {
      String sign = amount >= 0 ? '+' : '-';
      formattedAmount = '$sign₹ ${amount.abs().toStringAsFixed(decimals)}';
    } else {
      formattedAmount = '₹ ${amount.toStringAsFixed(decimals)}';
    }

    final textStyle = isBold
        ? AppTextStyles.heading4
        : isSubtle
            ? AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)
            : AppTextStyles.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textStyle,
          ),
          Text(
            formattedAmount,
            style: textStyle.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceItemWidget extends StatefulWidget {
  final int serialNumber;
  final String particulars;
  final int quantity;
  final double rate;
  final VoidCallback? onChanged;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  final TextEditingController particularsController;
  final TextEditingController quantityController;
  final TextEditingController rateController;

  InvoiceItemWidget({
    super.key,
    required this.serialNumber,
    this.particulars = '',
    this.quantity = 0,
    this.rate = 0.0,
    this.onChanged,
    this.onCopy,
    this.onDelete,
    TextEditingController? particularsController,
    TextEditingController? quantityController,
    TextEditingController? rateController,
  }) : particularsController = particularsController ?? TextEditingController(text: particulars),
       quantityController = quantityController ?? TextEditingController(
         text: quantity > 0 ? quantity.toString() : '',
       ),
       rateController = rateController ?? TextEditingController(
         text: rate > 0 ? rate.toString() : '',
       );

  bool validate() {
    if (particularsController.text.trim().isEmpty) return false;

    final qtyText = quantityController.text.trim();
    if (qtyText.isEmpty) return false;
    final qty = int.tryParse(qtyText);
    if (qty == null || qty <= 0) return false;

    final rateText = rateController.text.trim();
    if (rateText.isEmpty) return false;
    final rt = double.tryParse(rateText);
    if (rt == null || rt <= 0) return false;

    return true;
  }

  double getAmount() {
    final qty = int.tryParse(quantityController.text) ?? 0;
    final rt = double.tryParse(rateController.text) ?? 0.0;
    return qty * rt;
  }

  @override
  State<InvoiceItemWidget> createState() => _InvoiceItemWidgetState();
}

class _InvoiceItemWidgetState extends State<InvoiceItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with item number and action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Item ${widget.serialNumber}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Copy button
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: widget.onCopy,
                      color: AppColors.success,
                      tooltip: 'Copy item',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: widget.onDelete,
                        color: AppColors.error,
                        tooltip: 'Delete item',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Particulars field (full width)
            TextField(
              controller: widget.particularsController,
              decoration: const InputDecoration(
                labelText: 'Particulars / Description',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 2,
              onChanged: (_) => widget.onChanged?.call(),
            ),
            const SizedBox(height: 12),

            // Bottom row with QTY, Rate, and Amount
            Row(
              children: [
                // Quantity
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: widget.quantityController,
                    decoration: const InputDecoration(
                      labelText: 'QTY',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(12),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      setState(() {});
                      widget.onChanged?.call();
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Rate
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: widget.rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(12),
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged?.call();
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Amount (read-only display)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹ ${widget.getAmount().toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
