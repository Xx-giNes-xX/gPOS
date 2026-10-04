import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';

class CustomProductDialog extends StatefulWidget {
  final Product product;
  final int maxAvailable;
  final Function(int quantity, double price, String? notes) onConfirm;

  const CustomProductDialog({
    super.key,
    required this.product,
    this.maxAvailable = 1,
    required this.onConfirm,
  });

  @override
  State<CustomProductDialog> createState() => _CustomProductDialogState();
}

class _CustomProductDialogState extends State<CustomProductDialog> {
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _notesController = TextEditingController();
    _quantity = widget.maxAvailable > 0 ? 1 : 0;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canIncrease = _quantity < widget.maxAvailable;

    return AlertDialog(
      title: Text('Personalizar: ${widget.product.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precio unitario personalizado (€)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.euro),
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cantidad',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Stock disp.: ${widget.maxAvailable}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.maxAvailable <= 2 ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: canIncrease
                      ? () => setState(() => _quantity++)
                      : () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Máximo stock disponible: ${widget.maxAvailable} uds'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: Icon(
                    Icons.add,
                    color: canIncrease ? null : Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Notas o especificaciones de personalización',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: Nombre bordado en color dorado, logo en la parte trasera...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 44),
            backgroundColor: AppColors.primary,
          ),
          onPressed: widget.maxAvailable <= 0
              ? null
              : () {
                  final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ??
                      widget.product.price;
                  final notes = _notesController.text.trim();
                  widget.onConfirm(_quantity, price, notes.isEmpty ? null : notes);
                  Navigator.pop(context);
                },
          child: const Text('Añadir al Carrito'),
        ),
      ],
    );
  }
}
