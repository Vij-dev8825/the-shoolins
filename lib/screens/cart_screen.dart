import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency.dart';
import '../utils/order_ref.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/price_text.dart';
import '../widgets/shine_effect.dart';
import 'collections_screen.dart';
import 'orders_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;
  final Set<String> _removingIds = {};

  Future<void> _handleRemove(String productId) async {
    setState(() => _removingIds.add(productId));
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    await _removeItem(productId);
    if (mounted) setState(() => _removingIds.remove(productId));
  }

  Future<void> _removeItem(String productId) async {
    try {
      await context.read<CartService>().removeFromCart(productId);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove item: ${e.message}')),
      );
    }
  }

  Future<void> _changeQuantity(String productId, int quantity) async {
    try {
      await context.read<CartService>().updateQuantity(productId, quantity);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update quantity: ${e.message}')),
      );
    }
  }

  Future<void> _checkout() async {
    setState(() => _isCheckingOut = true);
    try {
      final order = await context.read<OrderService>().checkout();
      if (!mounted) return;
      context.read<CartService>().clear();
      await context.read<NotificationService>().add(
            type: NotificationType.order,
            title: 'Order confirmed',
            message: 'Your order #${shortOrderRef(order.id)} for ${formatInr(order.total)} has been placed.',
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order placed'),
          content: const Text('Your order has been placed successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(strings.t('cartTitle').toUpperCase())),
      body: Consumer<CartService>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: strings.t('cartEmptyTitle'),
              message: strings.t('cartEmptyMessage'),
              actionLabel: strings.t('continueShopping'),
              onAction: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CollectionsScreen()),
                );
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final removing = _removingIds.contains(item.productId);
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: removing ? 0 : 1,
                        child: removing
                            ? const SizedBox(width: double.infinity)
                            : _CartItemTile(
                                item: item,
                                onRemove: () => _handleRemove(item.productId),
                                onQuantityChanged: (quantity) =>
                                    _changeQuantity(item.productId, quantity),
                              ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(strings.t('subtotal'), style: AppTypography.bodyMuted),
                          PriceText(cart.total),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(strings.t('shipping'), style: AppTypography.bodyMuted),
                          Text(strings.t('free'), style: AppTypography.bodyMuted),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(strings.t('total'), style: AppTypography.title),
                          PriceText(cart.total, style: AppTypography.title.copyWith(color: AppColors.accentDark)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ShineEffect(
                        child: ElevatedButton(
                          onPressed: _isCheckingOut ? null : _checkout,
                          child: _isCheckingOut
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                                )
                              : Text(strings.t('checkout')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 72,
              height: 90,
              child: Container(
                color: AppColors.surfaceMuted,
                child: Image.asset(productAssetPath(item.image), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.body),
                const SizedBox(height: AppSpacing.xs),
                Text('${formatInr(item.price)} × ${item.quantity}', style: AppTypography.bodyMuted),
                const SizedBox(height: AppSpacing.sm),
                _QuantityStepper(
                  quantity: item.quantity,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceText(item.lineTotal),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 18, color: AppColors.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          onTap: quantity < 10 ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, size: 14, color: enabled ? AppColors.ink : AppColors.inkFaint),
      ),
    );
  }
}
