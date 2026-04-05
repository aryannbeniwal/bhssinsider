class Invoice {
  int? id;
  String invoiceNumber;
  DateTime invoiceDate;
  String invoiceTo;
  String invoiceToAddress;
  String sac;
  String placeOfSupply;
  List<InvoiceItem> items;
  double cgstRate;
  double sgstRate;
  DateTime createdAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.invoiceTo,
    required this.invoiceToAddress,
    required this.sac,
    required this.placeOfSupply,
    required this.items,
    this.cgstRate = 9.0,
    this.sgstRate = 9.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal {
    return items.fold(0, (sum, item) => sum + item.amount);
  }

  double get cgstAmount {
    return subtotal * cgstRate / 100;
  }

  double get sgstAmount {
    return subtotal * sgstRate / 100;
  }

  double get totalBeforeRounding {
    return subtotal + cgstAmount + sgstAmount;
  }

  double get roundOff {
    return grandTotal - totalBeforeRounding;
  }

  double get grandTotal {
    return totalBeforeRounding.round().toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'invoiceTo': invoiceTo,
      'invoiceToAddress': invoiceToAddress,
      'sac': sac,
      'placeOfSupply': placeOfSupply,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      invoiceTo: map['invoiceTo'],
      invoiceToAddress: map['invoiceToAddress'],
      sac: map['sac'],
      placeOfSupply: map['placeOfSupply'],
      items: [], // Items will be loaded separately
      cgstRate: map['cgstRate'],
      sgstRate: map['sgstRate'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class InvoiceItem {
  int? id;
  int? invoiceId;
  int serialNumber;
  String particulars;
  int quantity;
  double rate;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.serialNumber,
    required this.particulars,
    required this.quantity,
    required this.rate,
  });

  double get amount {
    return quantity * rate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'serialNumber': serialNumber,
      'particulars': particulars,
      'quantity': quantity,
      'rate': rate,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoiceId'],
      serialNumber: map['serialNumber'],
      particulars: map['particulars'],
      quantity: map['quantity'],
      rate: map['rate'],
    );
  }
}
