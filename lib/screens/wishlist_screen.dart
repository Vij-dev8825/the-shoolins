import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _loading = true;
  String? _error;
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<WishlistService>().fetchWishlist();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRemove(Product product) async {
    setState(() => _removingIds.add(product.id));
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    await _removeFromWishlist(product);
    if (mounted) setState(() => _removingIds.remove(product.id));
  }

  Future<void> _removeFromWishlist(Product product) async {
    try {
      await context.read<WishlistService>().remove(product.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update wishlist: ${e.message}')),
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      await context.read<CartService>().addToCart(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} ${AppStrings.of(context).t('productAddedToCart')}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add to cart: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = context.watch<WishlistService>().items;

    Widget body;
    if (_loading) {
      body = const ShimmerProductGrid(itemCount: 6);
    } else if (_error != null) {
      body = Center(child: Text('Could not load wishlist: $_error'));
    } else if (items.isEmpty) {
      body = EmptyState(
        icon: Icons.favorite_border,
        title: strings.t('wishlistEmptyTitle'),
        message: strings.t('wishlistEmptyMessage'),
      );
    } else {
      body = GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) {
          final product = items[index];
          final removing = _removingIds.contains(product.id);
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: removing ? 0 : 1,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              scale: removing ? 0.85 : 1,
              child: ProductCard(
                product: product,
                isWishlisted: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(productId: product.id),
                  ),
                ),
                onAddToCart: () => _addToCart(product),
                onToggleWishlist: () => _handleRemove(product),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(strings.t('wishlistTitle').toUpperCase())),
      body: RefreshIndicator(onRefresh: _load, child: body),
    );
  }
}
