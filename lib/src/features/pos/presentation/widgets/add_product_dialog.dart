import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';
import '../controllers/catalog_controller.dart';
import 'product_image_picker.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AddProductDialog(),
    );
  }

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');

  String? _imageUrl;
  bool _isCustomizable = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.replaceAll(',', '.').trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    final newProduct = Product(
      id: const Uuid().v4(),
      name: name,
      price: price,
      cost: 0.0,
      stock: stock,
      imageUrl: _imageUrl,
      isCustomizable: _isCustomizable,
    );

    ref.read(productsProvider.notifier).addProduct(newProduct);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Producto "$name" añadido correctamente'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_box_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text(
            'Añadir Producto',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image (Camera / Gallery)
                ProductImagePicker(
                  imageUrl: _imageUrl,
                  onImageSelected: (path) => setState(() => _imageUrl = path),
                ),
                const SizedBox(height: 16),

                // Product Name
                TextFormField(
                  controller: _nameController,
                  autofocus: false,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Producto *',
                    hintText: 'Ej. Café con Leche, Camiseta...',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa el nombre del producto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price and Stock row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Precio (€) *',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.euro_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Obligatorio';
                          }
                          final parsed = double.tryParse(val.replaceAll(',', '.').trim());
                          if (parsed == null || parsed < 0) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Stock
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock *',
                          hintText: '10',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Obligatorio';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customizable switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Producto Personalizable',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Permite modificar precio o notas en la venta',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isCustomizable,
                  onChanged: (val) => setState(() => _isCustomizable = val),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _saveProduct,
          icon: const Icon(Icons.check),
          label: const Text('Guardar Producto'),
        ),
      ],
    );
  }
}
