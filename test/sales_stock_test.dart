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

  test('Deleting a sale ticket removes it and restores product stock when restoreStock is true', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const testProduct = Product(
      id: 'del-p1',
      name: 'Croissant',
      price: 2.0,
      stock: 10,
    );

    container.read(productsProvider.notifier).addProduct(testProduct);
    container.read(cartProvider.notifier).addItem(testProduct, quantity: 4);

    final sale = container.read(salesProvider.notifier).completeSale(
      paymentMethod: PaymentMethod.cash,
      amountPaid: 8.0,
    );
    expect(sale, isNotNull);
    expect(container.read(productsProvider).firstWhere((p) => p.id == 'del-p1').stock, 6);
    expect(container.read(salesProvider).length, 1);

    // Delete the sale with restoreStock: true
    final deleted = container.read(salesProvider.notifier).deleteSale(sale!.id, restoreStock: true);
    expect(deleted, isTrue);
    expect(container.read(salesProvider), isEmpty);

    // Stock should be restored to 10
    expect(container.read(productsProvider).firstWhere((p) => p.id == 'del-p1').stock, 10);
  });

  test('Deleting a sale ticket with restoreStock = false removes sale without restoring stock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const testProduct = Product(
      id: 'del-p2',
      name: 'Té Matcha',
      price: 3.5,
      stock: 8,
    );

    container.read(productsProvider.notifier).addProduct(testProduct);
    container.read(cartProvider.notifier).addItem(testProduct, quantity: 2);

    final sale = container.read(salesProvider.notifier).completeSale(
      paymentMethod: PaymentMethod.cash,
      amountPaid: 7.0,
    );
    expect(sale, isNotNull);
    expect(container.read(productsProvider).firstWhere((p) => p.id == 'del-p2').stock, 6);

    // Delete without restoring stock
    final deleted = container.read(salesProvider.notifier).deleteSale(sale!.id, restoreStock: false);
    expect(deleted, isTrue);
    expect(container.read(salesProvider), isEmpty);

    // Stock remains at 6
    expect(container.read(productsProvider).firstWhere((p) => p.id == 'del-p2').stock, 6);
  });

  test('clearAllSales clears all sales from state and storage', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const testProduct = Product(
      id: 'clear-p1',
      name: 'Zumo Naranja',
      price: 3.0,
      stock: 15,
    );

    container.read(productsProvider.notifier).addProduct(testProduct);

    // Sale 1
    container.read(cartProvider.notifier).addItem(testProduct, quantity: 2);
    container.read(salesProvider.notifier).completeSale(paymentMethod: PaymentMethod.cash, amountPaid: 6.0);

    // Sale 2
    container.read(cartProvider.notifier).addItem(testProduct, quantity: 3);
    container.read(salesProvider.notifier).completeSale(paymentMethod: PaymentMethod.cash, amountPaid: 9.0);

    expect(container.read(salesProvider).length, 2);
    expect(container.read(productsProvider).firstWhere((p) => p.id == 'clear-p1').stock, 10);

    // Clear all with restore stock
    container.read(salesProvider.notifier).clearAllSales(restoreStock: true);
    expect(container.read(salesProvider), isEmpty);
    expect(container.read(productsProvider).firstWhere((p) => p.id == 'clear-p1').stock, 15);
  });

  test('Categories can be created dynamically and persist', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial categories start empty (no placeholders)
    final initialCats = container.read(categoriesProvider);
    expect(initialCats, isEmpty);

    // Add new category
    container.read(categoriesProvider.notifier).addCategory('Snacks');
    expect(container.read(categoriesProvider), contains('Snacks'));

    // Adding existing category does not duplicate
    container.read(categoriesProvider.notifier).addCategory('snacks');
    expect(container.read(categoriesProvider).where((c) => c.toLowerCase() == 'snacks').length, 1);
  });

  test('Filtered products correctly filters by category and stock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const drink = Product(
      id: 'cat-p1',
      name: 'Agua con gas',
      price: 1.5,
      stock: 5,
      category: 'Bebidas',
    );
    const dessert = Product(
      id: 'cat-p2',
      name: 'Tarta de Queso',
      price: 4.5,
      stock: 0,
      category: 'Postres',
    );

    container.read(productsProvider.notifier).addProduct(drink);
    container.read(productsProvider.notifier).addProduct(dessert);

    // Default: 'Todos' category and inStock filter
    container.read(productStockFilterProvider.notifier).state = ProductStockFilter.all;
    container.read(selectedCategoryProvider.notifier).state = 'Todos';
    expect(container.read(filteredProductsProvider).length, 2);

    // Filter by 'Bebidas'
    container.read(selectedCategoryProvider.notifier).state = 'Bebidas';
    var filtered = container.read(filteredProductsProvider);
    expect(filtered.length, 1);
    expect(filtered.first.id, 'cat-p1');

    // Filter by 'Postres'
    container.read(selectedCategoryProvider.notifier).state = 'Postres';
    filtered = container.read(filteredProductsProvider);
    expect(filtered.length, 1);
    expect(filtered.first.id, 'cat-p2');

    // Filter by 'Postres' with inStock filter -> should be empty since stock is 0
    container.read(productStockFilterProvider.notifier).state = ProductStockFilter.inStock;
    expect(container.read(filteredProductsProvider), isEmpty);
  });

  test('Deleting a category removes it, unlinks products, and resets selected category if selected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 1. Add categories and products
    container.read(categoriesProvider.notifier).addCategory('Camisetas');
    container.read(categoriesProvider.notifier).addCategory('Tazas');

    const p1 = Product(
      id: 'p1',
      name: 'Camiseta Negra',
      price: 15.0,
      stock: 10,
      category: 'Camisetas',
    );
    const p2 = Product(
      id: 'p2',
      name: 'Taza Blanca',
      price: 8.0,
      stock: 5,
      category: 'Tazas',
    );
    container.read(productsProvider.notifier).addProduct(p1);
    container.read(productsProvider.notifier).addProduct(p2);

    expect(container.read(allCategoriesProvider), containsAll(['Camisetas', 'Tazas']));

    // Set selected category to 'Camisetas'
    container.read(selectedCategoryProvider.notifier).state = 'Camisetas';
    expect(container.read(selectedCategoryProvider), 'Camisetas');

    // Delete 'Camisetas'
    container.read(categoriesProvider.notifier).deleteCategory('Camisetas');

    // 2. Verify 'Camisetas' is no longer in categoriesProvider or allCategoriesProvider
    expect(container.read(categoriesProvider), isNot(contains('Camisetas')));
    expect(container.read(allCategoriesProvider), isNot(contains('Camisetas')));

    // 3. Verify p1's category was reset to empty string
    final updatedProducts = container.read(productsProvider);
    final updatedP1 = updatedProducts.firstWhere((p) => p.id == 'p1');
    expect(updatedP1.category, isEmpty);

    // 4. Verify p2's category is still 'Tazas'
    final updatedP2 = updatedProducts.firstWhere((p) => p.id == 'p2');
    expect(updatedP2.category, 'Tazas');

    // 5. Verify selectedCategory was reset to 'Todos'
    expect(container.read(selectedCategoryProvider), 'Todos');
  });
}

