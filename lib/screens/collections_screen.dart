import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';
import 'product_detail_screen.dart';

const _sortOptions = [
  (label: 'Price: Low to High', value: 'price_asc'),
  (label: 'Price: High to Low', value: 'price_desc'),
];

class CollectionsScreen extends StatefulWidget {
  final String? initialCategory;

  const CollectionsScreen({super.key, this.initialCategory});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  static const _filterKeys = [
    (labelKey: 'all', category: null),
    (labelKey: 'women', category: 'women'),
    (labelKey: 'men', category: 'men'),
  ];

  late int _selectedIndex;
  String? _sort;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _filterKeys.indexWhere((f) => f.category == widget.initialCategory);
    if (_selectedIndex == -1) _selectedIndex = 0;
    _productsFuture = _loadProducts();
  }

  Future<List<Product>> _loadProducts() {
    return context.read<ProductService>().getProducts(
          category: _filterKeys[_selectedIndex].category,
          sort: _sort,
        );
  }

  void _selectFilter(int index) {
    setState(() {
      _selectedIndex = index;
      _productsFuture = _loadProducts();
    });
  }

  void _selectSort(String? sort) {
    setState(() {
      _sort = sort;
      _productsFuture = _loadProducts();
    });
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
      appBar: AppBar(title: Text(strings.t('collectionsTitle').toUpperCase())),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _filterKeys.length; i++) ...[
                          ChoiceChip(
                            label: Text(strings.t(_filterKeys[i].labelKey)),
                            selected: _selectedIndex == i,
                            onSelected: (_) => _selectFilter(i),
                          ),
                          if (i != _filterKeys.length - 1) const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PopupMenuButton<String?>(
                  icon: Icon(_sort == null ? Icons.sort : Icons.sort_rounded, color: AppColors.accentDark),
                  onSelected: _selectSort,
                  itemBuilder: (context) => [
                    for (final option in _sortOptions)
                      PopupMenuItem<String?>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerProductGrid(itemCount: 6);
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load products: ${snapshot.error}',
                      style: AppTypography.bodyMuted,
                    ),
                  );
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return Center(
                    child: Text('No products found.', style: AppTypography.bodyMuted),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        0,
                      ),
                      child: Text(
                        '${products.length} product${products.length == 1 ? '' : 's'}',
                        style: AppTypography.bodyMuted,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
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
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
