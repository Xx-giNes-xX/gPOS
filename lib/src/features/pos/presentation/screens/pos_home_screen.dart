import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/custom_product_dialog.dart';
import '../widgets/product_card.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final cart = ref.watch(cartProvider);
    final isTabletOrDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'gPOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Terminal de Ventas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Escanear Código de Barras',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando lector de código de barras...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left side: Catalog & Search
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val;
                    },
                  ),
                ),
                // Product Grid
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No se encontraron productos',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Añadir Producto'),
                                onPressed: () => AddProductDialog.show(context),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTabletOrDesktop ? 4 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                final inCart = ref.read(cartProvider).getQuantityForProduct(product.id);
                                final remaining = product.stock - inCart;

                                if (remaining <= 0) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No hay más stock disponible de "${product.name}" (Stock: ${product.stock})',
                                      ),
                                      backgroundColor: AppColors.warning,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (product.isCustomizable) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomProductDialog(
                                      product: product,
                                      maxAvailable: remaining,
                                      onConfirm: (qty, price, notes) {
                                        ref.read(cartProvider.notifier).addItem(
                                              product,
                                              quantity: qty,
                                              customPrice: price,
                                              customNotes: notes,
                                            );
                                      },
                                    ),
                                  );
                                } else {
                                  ref.read(cartProvider.notifier).addItem(product);
                                }
                              },
                              onLongPress: () {
                                final inCart = ref.read(cartProvider).getQuantityForProduct(product.id);
                                final remaining = product.stock - inCart;

                                if (remaining <= 0) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No hay más stock disponible de "${product.name}" (Stock: ${product.stock})',
                                      ),
                                      backgroundColor: AppColors.warning,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  builder: (context) => CustomProductDialog(
                                    product: product,
                                    maxAvailable: remaining,
                                    onConfirm: (qty, price, notes) {
                                      ref.read(cartProvider.notifier).addItem(
                                            product,
                                            quantity: qty,
                                            customPrice: price,
                                            customNotes: notes,
                                          );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Right side (Tablet / Desktop): Fixed Cart Sidebar
          if (isTabletOrDesktop)
            const SizedBox(
              width: 380,
              child: CartSheet(),
            ),
        ],
      ),
      // Mobile Floating Bottom Cart Bar
      bottomNavigationBar: !isTabletOrDesktop && cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Badge(
                      label: Text('${cart.totalItemsCount}'),
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) => const SizedBox(
                              height: 600,
                              child: CartSheet(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          Text(
                            Formatters.currency(cart.grandTotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(130, 46),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => const SizedBox(
                            height: 600,
                            child: CartSheet(),
                          ),
                        );
                      },
                      child: const Text('Ver Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
