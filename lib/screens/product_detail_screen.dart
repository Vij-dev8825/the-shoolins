import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/app_notification.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency.dart';
import '../utils/order_ref.dart';
import '../widgets/payment_sheet.dart';
import '../widgets/price_text.dart';
import '../widgets/product_image.dart';
import '../widgets/shine_effect.dart';
import '../widgets/trust_badge.dart';
import '../widgets/zoomable_image_viewer.dart';
import 'orders_screen.dart';

const List<String> _sizes = ['S', 'M', 'L', 'XL'];

// Products don't carry a description from the API, so we generate one
// per category to keep the detail screen from feeling empty.
const Map<String, String> _categoryCopy = {
  'women': 'Cut from breathable, lightweight fabric with a relaxed silhouette '
      'that moves with you. Designed to layer effortlessly, season to season.',
  'men': 'Tailored from durable, breathable cotton with a clean, considered '
      'fit. Built for everyday wear that holds its shape.',
};

const String _defaultCopy = 'Crafted from breathable cotton with a relaxed '
    'fit. A quiet, versatile piece designed to last.';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _productFuture;
  bool _addingToCart = false;
  bool _justAdded = false;
  bool _buyingNow = false;
  double _addButtonScale = 1.0;
  double _heartScale = 1.0;
  int _quantity = 1;
  String _selectedSize = _sizes[1];

  @override
  void initState() {
    super.initState();
    _productFuture = context.read<ProductService>().getProduct(widget.productId);
  }

  Future<void> _addToCart(Product product) async {
    setState(() {
      _addingToCart = true;
      _addButtonScale = 1.08;
    });
    try {
      await context.read<CartService>().addToCart(product.id, quantity: _quantity);
      if (!mounted) return;
      setState(() {
        _addingToCart = false;
        _justAdded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} ${AppStrings.of(context).t('productAddedToCart')}')),
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _justAdded = false);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _addingToCart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add to cart: ${e.message}')),
      );
    }
  }

  Future<void> _buyNow(Product product) async {
    setState(() => _buyingNow = true);
    try {
      await context.read<CartService>().addToCart(product.id, quantity: _quantity);
      if (!mounted) return;
      final amount = context.read<CartService>().total;
      final paid = await showPaymentSheet(context, amount: amount);
      if (!mounted || paid != true) return;

      final order = await context.read<OrderService>().checkout();
      if (!mounted) return;
      context.read<CartService>().clear();
      await context.read<NotificationService>().add(
            type: NotificationType.order,
            title: 'Order confirmed',
            message: 'Your order #${shortOrderRef(order.id)} for ${formatInr(order.total)} has been placed.',
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not proceed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _buyingNow = false);
    }
  }

  void _changeQuantity(int delta) {
    setState(() => _quantity = (_quantity + delta).clamp(1, 10));
  }

  Future<void> _toggleWishlist(Product product) async {
    setState(() => _heartScale = 1.35);
    try {
      await context.read<WishlistService>().toggle(product.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update wishlist: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRODUCT')),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load product: ${snapshot.error}',
                style: AppTypography.bodyMuted,
              ),
            );
          }
          final product = snapshot.data;
          if (product == null) {
            return const SizedBox.shrink();
          }
          final wishlisted = context.watch<WishlistService>().isWishlisted(product.id);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => ZoomableImageViewer.show(
                        context,
                        image: productImageProvider(
                          imageFilename: product.image,
                          imageBase64: product.imageBase64,
                        ),
                        heroTag: 'product-image-${product.id}',
                      ),
                      child: Hero(
                        tag: 'product-image-${product.id}',
                        child: AspectRatio(
                          aspectRatio: 0.85,
                          child: Container(
                            color: AppColors.surfaceMuted,
                            child: ProductImage(
                              imageFilename: product.image,
                              imageBase64: product.imageBase64,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: GestureDetector(
                        onTap: () => _toggleWishlist(product),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: wishlisted ? AppColors.accent : AppColors.surface,
                            border: wishlisted ? null : Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedScale(
                              scale: _heartScale,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              onEnd: () {
                                if (_heartScale != 1.0) setState(() => _heartScale = 1.0);
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(scale: animation, child: child),
                                child: Icon(
                                  wishlisted ? Icons.favorite : Icons.favorite_border,
                                  key: ValueKey(wishlisted),
                                  color: wishlisted ? AppColors.surface : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category.toUpperCase(),
                        style: AppTypography.label,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(product.name, style: AppTypography.headline),
                      const SizedBox(height: AppSpacing.sm),
                      PriceText(product.price),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _categoryCopy[product.category] ?? _defaultCopy,
                        style: AppTypography.bodyMuted,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('SIZE', style: AppTypography.label),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final size in _sizes)
                            ChoiceChip(
                              label: Text(size),
                              selected: _selectedSize == size,
                              onSelected: (_) => setState(() => _selectedSize = size),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('QUANTITY', style: AppTypography.label),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _QuantityButton(
                            icon: Icons.remove,
                            onTap: _quantity > 1 ? () => _changeQuantity(-1) : null,
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$_quantity',
                              textAlign: TextAlign.center,
                              style: AppTypography.title,
                            ),
                          ),
                          _QuantityButton(
                            icon: Icons.add,
                            onTap: _quantity < 10 ? () => _changeQuantity(1) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedScale(
                        scale: _addButtonScale,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        onEnd: () {
                          if (_addButtonScale != 1.0) setState(() => _addButtonScale = 1.0);
                        },
                        child: ShineEffect(
                          child: ElevatedButton(
                            onPressed: (_addingToCart || _buyingNow) ? null : () => _addToCart(product),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _addingToCart
                                  ? const SizedBox(
                                      key: ValueKey('adding'),
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                                    )
                                  : _justAdded
                                      ? Row(
                                          key: const ValueKey('added'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check, size: 18, color: AppColors.surface),
                                            const SizedBox(width: AppSpacing.xs),
                                            Text(AppStrings.of(context).t('productAddedToCart').toUpperCase()),
                                          ],
                                        )
                                      : Text(
                                          AppStrings.of(context).t('addToCart'),
                                          key: const ValueKey('add'),
                                        ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: (_addingToCart || _buyingNow) ? null : () => _buyNow(product),
                        child: _buyingNow
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                              )
                            : const Text('BUY NOW'),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.surfaceMuted,
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                  child: const Row(
                    children: [
                      Expanded(
                        child: TrustBadge(icon: Icons.local_shipping_outlined, label: 'Free shipping'),
                      ),
                      Expanded(
                        child: TrustBadge(icon: Icons.replay_outlined, label: 'Easy returns'),
                      ),
                      Expanded(
                        child: TrustBadge(icon: Icons.verified_user_outlined, label: 'Secure payment'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.ink : AppColors.inkFaint),
      ),
    );
  }
}
