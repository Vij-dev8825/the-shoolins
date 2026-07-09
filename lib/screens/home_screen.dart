import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_drawer.dart';
import '../widgets/hero_video.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/shine_effect.dart';
import '../widgets/trust_badge.dart';
import 'cart_screen.dart';
import 'collections_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _featuredProductsFuture;

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture = _loadFeatured();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartService>().fetchCart();
    });
  }

  Future<List<Product>> _loadFeatured() async {
    final products = await context.read<ProductService>().getProducts();
    return products.take(4).toList();
  }

  void _goToCollections({String? category}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CollectionsScreen(initialCategory: category)),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistService>();
    final strings = AppStrings.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/branding/icon.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(
              child: Text('THE SHOOLINS', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
          Consumer<CartService>(
            builder: (context, cart, _) => Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Cart',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Consumer<NotificationService>(
            builder: (context, notifications, _) => Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                if (notifications.unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${notifications.unreadCount}',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _featuredProductsFuture = _loadFeatured();
          });
          await _featuredProductsFuture;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 480,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const HeroVideo(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.xl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShineEffect(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                strings.t('homeNewSeason'),
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            strings.t('homeHeroTitle'),
                            style: AppTypography.display.copyWith(
                              color: AppColors.surface,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            strings.t('homeHeroSubtitle'),
                            style: AppTypography.bodyMuted.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ShineEffect(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.ink,
                              ),
                              onPressed: _goToCollections,
                              child: Text(strings.t('homeShopNow')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: AppColors.surfaceMuted,
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
              SectionHeader(title: strings.t('searchShopByCategory')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: _CategoryTile(
                        label: strings.t('women'),
                        image: 'shirt1.png',
                        onTap: () => _goToCollections(category: 'women'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _CategoryTile(
                        label: strings.t('men'),
                        image: 'shirt2.png',
                        onTap: () => _goToCollections(category: 'men'),
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(
                title: strings.t('homeFeatured'),
                actionLabel: strings.t('viewAll'),
                onAction: _goToCollections,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: FutureBuilder<List<Product>>(
                  future: _featuredProductsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ShimmerProductGrid(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(
                          child: Text(
                            'Could not load products: ${snapshot.error}',
                            style: AppTypography.bodyMuted,
                          ),
                        ),
                      );
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(
                          child: Text('No products available.', style: AppTypography.bodyMuted),
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.lg,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => _openProduct(product),
                          isWishlisted: wishlist.isWishlisted(product.id),
                          onToggleWishlist: () => wishlist.toggle(product.id),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final String image;
  final VoidCallback onTap;

  const _CategoryTile({required this.label, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Image.asset(productAssetPath(image), fit: BoxFit.cover),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
