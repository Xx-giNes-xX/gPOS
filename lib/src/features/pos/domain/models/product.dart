class Product {
  final String id;
  final String name;
  final double price;
  final double cost;
  final int stock;
  final String? imageUrl;
  final String? description;
  final bool isCustomizable;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.cost = 0.0,
    this.stock = 0,
    this.imageUrl,
    this.description,
    this.isCustomizable = false,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? cost,
    int? stock,
    String? imageUrl,
    String? description,
    bool? isCustomizable,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isCustomizable: isCustomizable ?? this.isCustomizable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'cost': cost,
        'stock': stock,
        'imageUrl': imageUrl,
        'description': description,
        'isCustomizable': isCustomizable,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
        stock: json['stock'] as int? ?? 0,
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
        isCustomizable: json['isCustomizable'] as bool? ?? false,
      );
}
