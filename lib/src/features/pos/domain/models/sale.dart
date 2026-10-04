import 'cart_item.dart';

enum PaymentMethod {
  cash,
}

class Sale {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;
  final String? customerName;
  final String? notes;

  const Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    this.paymentMethod = PaymentMethod.cash,
    required this.amountPaid,
    required this.change,
    this.customerName,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'paymentMethod': paymentMethod.name,
        'amountPaid': amountPaid,
        'change': change,
        'customerName': customerName,
        'notes': notes,
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num).toDouble(),
        paymentMethod: PaymentMethod.cash,
        amountPaid: (json['amountPaid'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        customerName: json['customerName'] as String?,
        notes: json['notes'] as String?,
      );
}
