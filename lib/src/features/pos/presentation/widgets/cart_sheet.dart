import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../controllers/cart_controller.dart';
import 'payment_modal.dart';

class CartSheet extends ConsumerWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar & Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Ticket Actual (${cart.totalItemsCount})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (cart.items.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      label: const Text(
                        'Vaciar',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Items List
            Expanded(
              child: cart.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'El carrito está vacío',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        final totalInCartForProduct = cart.getQuantityForProduct(item.product.id);
                        final isMaxStockReached = totalInCartForProduct >= item.product.stock;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Quantity selector
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(index, item.quantity - 1);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.remove, size: 16),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: isMaxStockReached
                                        ? () {
                                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Stock máximo alcanzado (${item.product.stock} uds disponibles)',
                                                ),
                                                backgroundColor: AppColors.warning,
                                                behavior: SnackBarBehavior.floating,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        : () {
                                            ref
                                                .read(cartProvider.notifier)
                                                .updateQuantity(index, item.quantity + 1);
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: isMaxStockReached
                                            ? Theme.of(context).disabledColor.withValues(alpha: 0.3)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.customNotes != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Nota: ${item.customNotes}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.accent,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  Text(
                                    '${Formatters.currency(item.unitPrice)}/ud',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Total price
                            Text(
                              Formatters.currency(item.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            // Summary and checkout button
            if (cart.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text(Formatters.currency(cart.subtotal)),
                      ],
                    ),
                    if (cart.discountPercentage > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Descuento (${cart.discountPercentage.toInt()}%):'),
                          Text(
                            '-${Formatters.currency(cart.discountAmount)}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.currency(cart.grandTotal),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => const PaymentModal(),
                        );
                      },
                      child: Text('COBRAR ${Formatters.currency(cart.grandTotal)}'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
