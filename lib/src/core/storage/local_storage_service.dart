import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/pos/domain/models/product.dart';
import '../../features/pos/domain/models/sale.dart';

class LocalStorageService {
  static const String _productsKey = 'gpos_saved_products_v1';
  static const String _salesKey = 'gpos_saved_sales_v1';
  static const String _darkModeKey = 'gpos_dark_mode_v1';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- PRODUCTS ---
  static List<Product> loadProducts() {
    try {
      final jsonString = _prefs?.getString(_productsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProducts(List<Product> products) async {
    try {
      final jsonString = jsonEncode(products.map((p) => p.toJson()).toList());
      await _prefs?.setString(_productsKey, jsonString);
    } catch (_) {}
  }

  // --- SALES ---
  static List<Sale> loadSales() {
    try {
      final jsonString = _prefs?.getString(_salesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSales(List<Sale> sales) async {
    try {
      final jsonString = jsonEncode(sales.map((s) => s.toJson()).toList());
      await _prefs?.setString(_salesKey, jsonString);
    } catch (_) {}
  }

  // --- CATEGORIES ---
  static const String _categoriesKey = 'gpos_saved_categories_v2';
  static const List<String> defaultCategories = [];

  static List<String> loadCategories() {
    try {
      final list = _prefs?.getStringList(_categoriesKey);
      if (list == null) {
        return [];
      }
      return list.where((c) {
        final lower = c.trim().toLowerCase();
        return lower.isNotEmpty &&
            lower != 'general' &&
            lower != 'todos' &&
            lower != 'bebidas' &&
            lower != 'comida' &&
            lower != 'postres';
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCategories(List<String> categories) async {
    try {
      await _prefs?.setStringList(_categoriesKey, categories);
    } catch (_) {}
  }

  // --- SETTINGS ---
  static bool loadDarkMode() {
    return _prefs?.getBool(_darkModeKey) ?? false;
  }

  static Future<void> saveDarkMode(bool isDark) async {
    await _prefs?.setBool(_darkModeKey, isDark);
  }
}
