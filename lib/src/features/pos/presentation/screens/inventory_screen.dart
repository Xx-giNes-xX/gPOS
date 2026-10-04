import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/product.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/product_image_widget.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario y Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nuevo Producto',
            onPressed: () => _showProductForm(context, ref),
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay productos en el inventario',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showProductForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Producto'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = products[index];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showProductForm(context, ref, product: product),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Left: Product image thumbnail
                          ProductImageWidget(
                            imageUrl: product.imageUrl,
                            width: 48,
                            height: 48,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 12),
                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: product.stock <= 0
                                            ? AppColors.error.withValues(alpha: 0.12)
                                            : product.stock <= 5
                                                ? AppColors.warning.withValues(alpha: 0.12)
                                                : AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product.stock <= 0
                                            ? 'Agotado (0)'
                                            : 'Stock: ${product.stock} uds',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: product.stock <= 0
                                              ? AppColors.error
                                              : product.stock <= 5
                                                  ? AppColors.warning
                                                  : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    if (product.cost > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        'Coste: ${Formatters.currency(product.cost)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Price
                          Text(
                            Formatters.currency(product.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Stock controls
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.remove, size: 16),
                                  tooltip: 'Restar 1 unidad',
                                  onPressed: product.stock > 0
                                      ? () => ref.read(productsProvider.notifier).adjustStock(product.id, -1)
                                      : null,
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.add, size: 16),
                                  tooltip: 'Añadir 1 unidad',
                                  onPressed: () => ref.read(productsProvider.notifier).adjustStock(product.id, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  void _showProductForm(
    BuildContext context,
    WidgetRef ref, {
    Product? product,
  }) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toStringAsFixed(2) ?? '0.00');
    final costController = TextEditingController(text: product?.cost.toStringAsFixed(2) ?? '0.00');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '10');
    bool isCustomizable = product?.isCustomizable ?? false;
    String? imageUrl = product?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  product == null ? 'Añadir Nuevo Producto' : 'Editar Producto',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ProductImagePicker(
                  imageUrl: imageUrl,
                  onImageSelected: (path) => setModalState(() => imageUrl = path),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'PVP Venta (€)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Coste (€)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Producto Personalizable'),
                  subtitle: const Text('Permite modificar precio o notas en el momento del cobro'),
                  value: isCustomizable,
                  onChanged: (val) => setModalState(() => isCustomizable = val),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
                    final cost = double.tryParse(costController.text.replaceAll(',', '.')) ?? 0.0;
                    final stock = int.tryParse(stockController.text) ?? 0;

                    if (product == null) {
                      final newProd = Product(
                        id: const Uuid().v4(),
                        name: nameController.text.trim(),
                        price: price,
                        cost: cost,
                        stock: stock,
                        imageUrl: imageUrl,
                        isCustomizable: isCustomizable,
                      );
                      ref.read(productsProvider.notifier).addProduct(newProd);
                    } else {
                      final updated = product.copyWith(
                        name: nameController.text.trim(),
                        price: price,
                        cost: cost,
                        stock: stock,
                        imageUrl: imageUrl,
                        isCustomizable: isCustomizable,
                      );
                      ref.read(productsProvider.notifier).updateProduct(updated);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(product == null ? 'Crear Producto' : 'Guardar Cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
