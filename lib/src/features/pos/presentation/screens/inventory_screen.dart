import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/product.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/manage_categories_dialog.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/product_image_widget.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Eliminar Producto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Text(
            '¿Estás seguro de que deseas eliminar "${product.name}" del inventario? Esta acción no se puede deshacer.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(product.id);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Producto "${product.name}" eliminado correctamente'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

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
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
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
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showProductForm(context, ref, product: product),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header: Image + Name/Badges + Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductImageWidget(
                                imageUrl: product.imageUrl,
                                width: 58,
                                height: 58,
                                borderRadius: 10,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (product.category.trim().isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              product.category,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: product.stock <= 0
                                                ? AppColors.error.withValues(alpha: 0.12)
                                                : product.stock <= 5
                                                    ? AppColors.warning.withValues(alpha: 0.12)
                                                    : AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            product.stock <= 0
                                                ? 'Agotado (0)'
                                                : 'Stock: ${product.stock} uds',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: product.stock <= 0
                                                  ? AppColors.error
                                                  : product.stock <= 5
                                                      ? AppColors.warning
                                                      : AppColors.success,
                                            ),
                                          ),
                                        ),
                                        if (product.isCustomizable)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Personalizable',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.purple,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.currency(product.price),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (product.cost > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Coste: ${Formatters.currency(product.cost)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 8),
                          // Bottom row: Stock adjustments & actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Stock:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            '${product.stock}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Editar'),
                                    onPressed: () => _showProductForm(context, ref, product: product),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                    tooltip: 'Eliminar producto',
                                    onPressed: () => _confirmDeleteProduct(context, ref, product),
                                  ),
                                ],
                              ),
                            ],
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
    String selectedCategory = product?.category ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableCategories = ref.watch(allCategoriesProvider);
          final currentCat = availableCategories.contains(selectedCategory)
              ? selectedCategory
              : '';

          return Padding(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product == null ? 'Añadir Nuevo Producto' : 'Editar Producto',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (product != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          tooltip: 'Eliminar producto',
                          onPressed: () {
                            Navigator.pop(modalContext);
                            _confirmDeleteProduct(context, ref, product);
                          },
                        ),
                    ],
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
                  // Category selector with on-the-fly creation
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(currentCat),
                          initialValue: currentCat,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text(
                                'Sin categoría',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...availableCategories.map((c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(
                                  c,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Crear nueva categoría',
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () async {
                          final catCtrl = TextEditingController();
                          final created = await showDialog<String>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Row(
                                children: [
                                  Icon(Icons.category_rounded, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Nueva Categoría',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              content: TextField(
                                controller: catCtrl,
                                autofocus: true,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre de la categoría',
                                  hintText: 'Ej. Pegatinas, Chapas...',
                                ),
                                onSubmitted: (v) {
                                  final tr = v.trim();
                                  if (tr.isNotEmpty) Navigator.pop(dCtx, tr);
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    final tr = catCtrl.text.trim();
                                    if (tr.isNotEmpty) Navigator.pop(dCtx, tr);
                                  },
                                  child: const Text('Crear Categoría'),
                                ),
                              ],
                            ),
                          );

                          if (created != null && created.isNotEmpty) {
                            ref.read(categoriesProvider.notifier).addCategory(created);
                            setModalState(() => selectedCategory = created);
                          }
                        },
                      ),
                      if (availableCategories.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        IconButton.filledTonal(
                          tooltip: 'Gestionar categorías',
                          icon: const Icon(Icons.tune_rounded),
                          onPressed: () => ManageCategoriesDialog.show(context),
                        ),
                      ],
                    ],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () {
                      final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
                      final cost = double.tryParse(costController.text.replaceAll(',', '.')) ?? 0.0;
                      final stock = int.tryParse(stockController.text) ?? 0;

                      if (selectedCategory.isNotEmpty) {
                        ref.read(categoriesProvider.notifier).addCategory(selectedCategory);
                      }

                      if (product == null) {
                        final newProd = Product(
                          id: const Uuid().v4(),
                          name: nameController.text.trim(),
                          price: price,
                          cost: cost,
                          stock: stock,
                          imageUrl: imageUrl,
                          isCustomizable: isCustomizable,
                          category: selectedCategory,
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
                          category: selectedCategory,
                        );
                        ref.read(productsProvider.notifier).updateProduct(updated);
                      }
                      Navigator.pop(modalContext);
                    },
                    child: Text(product == null ? 'Crear Producto' : 'Guardar Cambios'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
