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
final selectedCategoryProvider = StateProvider<String>((ref) => 'Todos');

class CategoriesNotifier extends StateNotifier<List<String>> {
  final Ref ref;

  CategoriesNotifier(this.ref) : super(LocalStorageService.loadCategories());

  void _persist() {
    LocalStorageService.saveCategories(state);
  }

  void addCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'todos' ||
        trimmed.toLowerCase() == 'general') {
      return;
    }
    if (!state.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      state = [...state, trimmed];
      _persist();
    }
  }

  void deleteCategory(String category) {
    final trimmed = category.trim();
    final lower = trimmed.toLowerCase();
    state = state.where((c) => c.toLowerCase() != lower).toList();
    _persist();

    // Clear category from products that had it
    ref.read(productsProvider.notifier).clearCategoryFromProducts(trimmed);

    // If currently selected category was deleted, switch back to 'Todos'
    if (ref.read(selectedCategoryProvider).toLowerCase() == lower) {
      ref.read(selectedCategoryProvider.notifier).state = 'Todos';
    }
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<String>>((ref) {
  return CategoriesNotifier(ref);
});

final allCategoriesProvider = Provider<List<String>>((ref) {
  final explicit = ref.watch(categoriesProvider);
  final products = ref.watch(productsProvider);
  final set = <String>{...explicit};
  for (final p in products) {
    final cat = p.category.trim();
    if (cat.isNotEmpty &&
        cat.toLowerCase() != 'general' &&
        cat.toLowerCase() != 'todos') {
      set.add(cat);
    }
  }
  return set.toList();
});

final categoryCountProvider = Provider.family<int, String>((ref, category) {
  final products = ref.watch(productsProvider);
  if (category == 'Todos') {
    return products.length;
  }
  return products.where((p) => p.category.toLowerCase() == category.toLowerCase()).length;
});

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

  void clearCategoryFromProducts(String category) {
    final lower = category.trim().toLowerCase();
    state = [
      for (final item in state)
        if (item.category.trim().toLowerCase() == lower)
          item.copyWith(category: '')
        else
          item,
    ];
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
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return products.where((product) {
    // Category filter
    if (selectedCategory != 'Todos' &&
        product.category.toLowerCase() != selectedCategory.toLowerCase()) {
      return false;
    }

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
