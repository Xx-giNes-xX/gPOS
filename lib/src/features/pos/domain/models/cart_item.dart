import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double customPrice;
  final String? customNotes;
  final Map<String, dynamic>? customOptions;

  CartItem({
    required this.product,
    this.quantity = 1,
    double? customPrice,
    this.customNotes,
    this.customOptions,
  }) : customPrice = customPrice ?? product.price;

  double get unitPrice => customPrice;
  double get total => unitPrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? customPrice,
    String? customNotes,
    Map<String, dynamic>? customOptions,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      customPrice: customPrice ?? this.customPrice,
      customNotes: customNotes ?? this.customNotes,
      customOptions: customOptions ?? this.customOptions,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
        'customPrice': customPrice,
        'customNotes': customNotes,
        'customOptions': customOptions,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int? ?? 1,
        customPrice: (json['customPrice'] as num?)?.toDouble(),
        customNotes: json['customNotes'] as String?,
        customOptions: json['customOptions'] as Map<String, dynamic>?,
      );
}
