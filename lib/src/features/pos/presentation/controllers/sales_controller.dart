import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/models/sale.dart';
import 'cart_controller.dart';
import 'catalog_controller.dart';

class SalesNotifier extends StateNotifier<List<Sale>> {
  final Ref ref;
  static const _uuid = Uuid();

  SalesNotifier(this.ref) : super(LocalStorageService.loadSales());

  Sale? completeSale({
    required PaymentMethod paymentMethod,
    required double amountPaid,
  }) {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return null;

    final grandTotal = cartState.grandTotal;
    final change = (amountPaid - grandTotal).clamp(0.0, double.infinity);

    final newSale = Sale(
      id: 'SALE-${_uuid.v4().substring(0, 8).toUpperCase()}',
      date: DateTime.now(),
      items: List.from(cartState.items),
      subtotal: cartState.subtotal,
      discount: cartState.discountAmount,
      total: grandTotal,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      change: change,
      customerName: cartState.customerName,
      notes: cartState.orderNotes,
    );

    // Deduct stock for each item
    final productsNotifier = ref.read(productsProvider.notifier);
    for (final item in cartState.items) {
      productsNotifier.adjustStock(item.product.id, -item.quantity);
    }

    // Add sale to history and persist
    state = [newSale, ...state];
    LocalStorageService.saveSales(state);

    // Clear shopping cart
    ref.read(cartProvider.notifier).clearCart();

    return newSale;
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  return SalesNotifier(ref);
});

final todaySalesTotalProvider = Provider<double>((ref) {
  final sales = ref.watch(salesProvider);
  final now = DateTime.now();

  return sales.where((s) {
    return s.date.year == now.year &&
        s.date.month == now.month &&
        s.date.day == now.day;
  }).fold(0.0, (sum, s) => sum + s.total);
});

final todaySalesCountProvider = Provider<int>((ref) {
  final sales = ref.watch(salesProvider);
  final now = DateTime.now();

  return sales.where((s) {
    return s.date.year == now.year &&
        s.date.month == now.month &&
        s.date.day == now.day;
  }).length;
});
