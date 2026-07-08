import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'price_text.dart';

// Shared product tile used on Home, Collections, Search and Wishlist.
// Wishlist heart and add-to-cart button are both optional so each screen
// only shows the actions relevant to it.
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool isWishlisted;
  final VoidCallback? onToggleWishlist;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.isWishlisted = false,
    this.onToggleWishlist,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  double _heartScale = 1.0;
  double _cartScale = 1.0;
  bool _justAdded = false;

  // No review system exists yet, so ratings are derived deterministically
  // from the product id (stable across rebuilds) purely for visual polish.
  double get _rating {
    final hash = widget.product.id.hashCode.abs();
    return 4.0 + (hash % 10) / 10;
  }

  int get _reviewCount {
    final hash = widget.product.id.hashCode.abs();
    return 40 + (hash % 260);
  }

  void _handleToggleWishlist() {
    setState(() => _heartScale = 1.35);
    widget.onToggleWishlist!();
  }

  void _handleAddToCart() {
    setState(() {
      _cartScale = 1.35;
      _justAdded = true;
    });
    widget.onAddToCart!();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.surfaceMuted,
                    child: Image.asset(
                      productAssetPath(product.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onToggleWishlist != null || widget.onAddToCart != null)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onToggleWishlist != null)
                            AnimatedScale(
                              scale: _heartScale,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              onEnd: () {
                                if (_heartScale != 1.0) setState(() => _heartScale = 1.0);
                              },
                              child: _RoundIconButton(
                                icon: widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
                                iconColor: widget.isWishlisted ? AppColors.surface : AppColors.ink,
                                backgroundColor: widget.isWishlisted ? AppColors.accent : null,
                                onTap: _handleToggleWishlist,
                              ),
                            ),
                          if (widget.onToggleWishlist != null && widget.onAddToCart != null)
                            const SizedBox(width: AppSpacing.xs),
                          if (widget.onAddToCart != null)
                            AnimatedScale(
                              scale: _cartScale,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              onEnd: () {
                                if (_cartScale != 1.0) setState(() => _cartScale = 1.0);
                              },
                              child: _RoundIconButton(
                                icon: _justAdded ? Icons.check : Icons.add_shopping_cart,
                                iconColor: _justAdded ? AppColors.surface : AppColors.ink,
                                backgroundColor: _justAdded ? AppColors.success : null,
                                onTap: _handleAddToCart,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: AppTypography.label.copyWith(
                          color: AppColors.ink,
                          letterSpacing: 0,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($_reviewCount)',
                        style: AppTypography.label.copyWith(letterSpacing: 0, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  PriceText(product.price),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final filled = backgroundColor != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppColors.surface,
          border: filled ? null : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(icon, size: 17, color: iconColor, key: ValueKey(icon)),
          ),
        ),
      ),
    );
  }
}
