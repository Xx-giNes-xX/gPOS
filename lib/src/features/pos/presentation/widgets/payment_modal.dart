import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/sale.dart';
import '../controllers/cart_controller.dart';
import '../controllers/sales_controller.dart';

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  late TextEditingController _amountPaidController;
  Sale? _completedSale;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _amountPaidController = TextEditingController(
      text: cart.grandTotal.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  void _onQuickCashSelected(double amount) {
    setState(() {
      _amountPaidController.text = amount.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.grandTotal;

    if (_completedSale != null) {
      return _buildSuccessReceipt(_completedSale!);
    }

    final amountPaid =
        double.tryParse(_amountPaidController.text.replaceAll(',', '.')) ?? total;
    final change = (amountPaid - total).clamp(0.0, double.infinity);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Cobro de Venta',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL A COBRAR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  Formatters.currency(total),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Amount Paid & Change
          TextField(
            controller: _amountPaidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Monto Recibido',
              prefixIcon: Icon(Icons.euro),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Quick cash bill helpers (Exacto, 5€, 10€, 20€, 50€, 100€)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickCashChip(total, 'Exacto'),
                _quickCashChip(5.0, '5 €'),
                _quickCashChip(10.0, '10 €'),
                _quickCashChip(20.0, '20 €'),
                _quickCashChip(50.0, '50 €'),
                _quickCashChip(100.0, '100 €'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: change > 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: change > 0
                    ? AppColors.success.withValues(alpha: 0.3)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cambio a devolver:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  Formatters.currency(change),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: change > 0 ? AppColors.success : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final sale = ref.read(salesProvider.notifier).completeSale(
                    paymentMethod: PaymentMethod.cash,
                    amountPaid: amountPaid,
                  );
              if (sale != null) {
                setState(() {
                  _completedSale = sale;
                });
              }
            },
            child: Text(
              'COMPLETAR COBRO (${Formatters.currency(total)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    )));
  }

  Widget _quickCashChip(double value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _onQuickCashSelected(value),
      ),
    );
  }

  Widget _buildSuccessReceipt(Sale sale) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 64,
          ),
          const SizedBox(height: 12),
          const Text(
            '¡Venta Completada!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            'ID: ${sale.id}',
            style: const TextStyle(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pagado:'),
                    Text(
                      Formatters.currency(sale.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (sale.change > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cambio Entregado:'),
                      Text(
                        Formatters.currency(sale.change),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('NUEVA VENTA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ));
  }
}
