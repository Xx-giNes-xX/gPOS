import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/models/product.dart';

enum ProductStockFilter {
  inStock,    // Solo con stock disponible (> 0)
  outOfStock, // Agotados (<= 0)
  all,        // Todos los productos
}

final searchQueryProvider = StateProvider<String>((ref) => '');
final productStockFilterProvider = StateProvider<ProductStockFilter>((ref) => ProductStockFilter.inStock);

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>((ref) {
  return ProductsNotifier();
});

class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier() : super(LocalStorageService.loadProducts());

  void _persist() {
    LocalStorageService.saveProducts(state);
  }

  void addProduct(Product product) {
    state = [...state, product];
    _persist();
  }

  void updateProduct(Product updated) {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
    _persist();
  }

  void deleteProduct(String productId) {
    state = state.where((item) => item.id != productId).toList();
    _persist();
  }

  void adjustStock(String productId, int quantityChange) {
    state = [
      for (final item in state)
        if (item.id == productId)
          item.copyWith(stock: (item.stock + quantityChange).clamp(0, 99999))
        else
          item,
    ];
    _persist();
  }
}

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final stockFilter = ref.watch(productStockFilterProvider);

  return products.where((product) {
    // Search query filter
    final matchesSearch = searchQuery.isEmpty || product.name.toLowerCase().contains(searchQuery);
    if (!matchesSearch) return false;

    // Stock category filter
    switch (stockFilter) {
      case ProductStockFilter.inStock:
        return product.stock > 0;
      case ProductStockFilter.outOfStock:
        return product.stock <= 0;
      case ProductStockFilter.all:
        return true;
    }
  }).toList();
});

final inStockProductsCountProvider = Provider<int>((ref) {
  final products = ref.watch(productsProvider);
  return products.where((p) => p.stock > 0).length;
});

final outOfStockProductsCountProvider = Provider<int>((ref) {
  final products = ref.watch(productsProvider);
  return products.where((p) => p.stock <= 0).length;
});
