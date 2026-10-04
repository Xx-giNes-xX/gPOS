import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpos/src/core/storage/local_storage_service.dart';
import 'package:gpos/src/features/pos/domain/models/product.dart';
import 'package:gpos/src/features/pos/domain/models/sale.dart';
import 'package:gpos/src/features/pos/presentation/controllers/cart_controller.dart';
import 'package:gpos/src/features/pos/presentation/controllers/catalog_controller.dart';
import 'package:gpos/src/features/pos/presentation/controllers/sales_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test('Completing a sale decrements the product stock correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const testProduct = Product(
      id: 'test-1',
      name: 'Test Coffee',
      price: 2.50,
      stock: 10,
    );

    // Add product to catalog
    container.read(productsProvider.notifier).addProduct(testProduct);

    // Verify initial stock
    var products = container.read(productsProvider);
    expect(products.firstWhere((p) => p.id == 'test-1').stock, 10);

    // Add 3 units of product to cart
    container.read(cartProvider.notifier).addItem(testProduct, quantity: 3);
    expect(container.read(cartProvider).totalItemsCount, 3);

    // Complete sale (pasar por caja)
    final sale = container.read(salesProvider.notifier).completeSale(
      paymentMethod: PaymentMethod.cash,
      amountPaid: 10.0,
    );

    expect(sale, isNotNull);
    expect(sale!.items.length, 1);
    expect(sale.items.first.quantity, 3);

    // Verify stock is now 10 - 3 = 7
    products = container.read(productsProvider);
    final updatedProduct = products.firstWhere((p) => p.id == 'test-1');
    expect(updatedProduct.stock, 7);

    // Cart is cleared
    expect(container.read(cartProvider).items, isEmpty);
  });

  test('Cart enforces stock limits: cannot exceed available product stock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const limitedProduct = Product(
      id: 'limited-1',
      name: 'Limited Shoes',
      price: 50.0,
      stock: 3,
    );

    // 1. Try to add 5 units when only 3 are in stock -> should add at most 3
    final added = container.read(cartProvider.notifier).addItem(limitedProduct, quantity: 5);
    expect(added, isTrue);
    expect(container.read(cartProvider).totalItemsCount, 3);

    // 2. Try to add more -> should return false and not increase
    final addedMore = container.read(cartProvider.notifier).addItem(limitedProduct, quantity: 1);
    expect(addedMore, isFalse);
    expect(container.read(cartProvider).totalItemsCount, 3);

    // 3. Try to update quantity to 10 -> should be clamped or rejected
    final updated = container.read(cartProvider.notifier).updateQuantity(0, 10);
    expect(updated, isFalse);
    expect(container.read(cartProvider).totalItemsCount, 3);

    // 4. Update to 2 (valid)
    final updatedValid = container.read(cartProvider.notifier).updateQuantity(0, 2);
    expect(updatedValid, isTrue);
    expect(container.read(cartProvider).totalItemsCount, 2);

    // 5. Update from 2 to 3 (valid, reached limit)
    expect(container.read(cartProvider.notifier).updateQuantity(0, 3), isTrue);
    expect(container.read(cartProvider).totalItemsCount, 3);

    // 6. Cannot update from 3 to 4
    expect(container.read(cartProvider.notifier).updateQuantity(0, 4), isFalse);
    expect(container.read(cartProvider).totalItemsCount, 3);
  });

  test('Products persist across restarts / new notifier instances', () {
    // 1. Initial app session: Add a product and update stock
    final session1 = ProviderContainer();
    const product = Product(
      id: 'persist-p1',
      name: 'Taza de Cerámica',
      price: 15.0,
      stock: 25,
    );
    session1.read(productsProvider.notifier).addProduct(product);
    session1.read(productsProvider.notifier).adjustStock('persist-p1', -5);
    session1.dispose();

    // 2. Simulated app restart: New session loads from storage
    final session2 = ProviderContainer();
    addTearDown(session2.dispose);

    final reloadedProducts = session2.read(productsProvider);
    expect(reloadedProducts.length, 1);
    expect(reloadedProducts.first.id, 'persist-p1');
    expect(reloadedProducts.first.name, 'Taza de Cerámica');
    expect(reloadedProducts.first.price, 15.0);
    expect(reloadedProducts.first.stock, 20); // 25 - 5
  });
}
