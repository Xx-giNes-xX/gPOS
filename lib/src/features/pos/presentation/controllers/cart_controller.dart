import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product.dart';

class CartState {
  final List<CartItem> items;
  final double discountPercentage;
  final String? customerName;
  final String? orderNotes;

  const CartState({
    this.items = const [],
    this.discountPercentage = 0.0,
    this.customerName,
    this.orderNotes,
  });

  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get discountAmount => subtotal * (discountPercentage / 100);

  double get grandTotal => subtotal - discountAmount;

  int getQuantityForProduct(String productId) {
    return items
        .where((item) => item.product.id == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  int getRemainingStockForProduct(Product product) {
    final inCart = getQuantityForProduct(product.id);
    return (product.stock - inCart).clamp(0, product.stock);
  }

  CartState copyWith({
    List<CartItem>? items,
    double? discountPercentage,
    String? customerName,
    String? orderNotes,
  }) {
    return CartState(
      items: items ?? this.items,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      customerName: customerName ?? this.customerName,
      orderNotes: orderNotes ?? this.orderNotes,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  bool addItem(Product product, {int quantity = 1, double? customPrice, String? customNotes}) {
    final currentQtyInCart = state.getQuantityForProduct(product.id);
    final maxCanAdd = product.stock - currentQtyInCart;

    if (maxCanAdd <= 0 || quantity <= 0) {
      return false;
    }

    final qtyToAdd = quantity > maxCanAdd ? maxCanAdd : quantity;

    final existingIndex = state.items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.customPrice == (customPrice ?? product.price) &&
          item.customNotes == customNotes,
    );

    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      final currentItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + qtyToAdd,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = CartItem(
        product: product,
        quantity: qtyToAdd,
        customPrice: customPrice,
        customNotes: customNotes,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
    return true;
  }

  bool updateQuantity(int index, int newQuantity) {
    if (index < 0 || index >= state.items.length) return false;

    if (newQuantity <= 0) {
      removeItem(index);
      return true;
    }

    final targetItem = state.items[index];
    final otherQtyInCart = state.items
        .asMap()
        .entries
        .where((e) => e.key != index && e.value.product.id == targetItem.product.id)
        .fold(0, (sum, e) => sum + e.value.quantity);

    final maxAllowed = targetItem.product.stock - otherQtyInCart;

    if (newQuantity > maxAllowed) {
      if (maxAllowed > 0 && targetItem.quantity != maxAllowed) {
        final updatedItems = [...state.items];
        updatedItems[index] = targetItem.copyWith(quantity: maxAllowed);
        state = state.copyWith(items: updatedItems);
      }
      return false;
    }

    final updatedItems = [...state.items];
    updatedItems[index] = targetItem.copyWith(quantity: newQuantity);
    state = state.copyWith(items: updatedItems);
    return true;
  }

  void updateCustomItem(int index, {double? customPrice, String? customNotes}) {
    if (index < 0 || index >= state.items.length) return;

    final updatedItems = [...state.items];
    updatedItems[index] = updatedItems[index].copyWith(
      customPrice: customPrice,
      customNotes: customNotes,
    );
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updatedItems = [...state.items]..removeAt(index);
    state = state.copyWith(items: updatedItems);
  }

  void setDiscount(double percentage) {
    state = state.copyWith(discountPercentage: percentage.clamp(0.0, 100.0));
  }

  void setCustomerName(String? name) {
    state = state.copyWith(customerName: name);
  }

  void setOrderNotes(String? notes) {
    state = state.copyWith(orderNotes: notes);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
