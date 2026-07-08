import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';
import 'product_detail_screen.dart';

const _categoryFilters = [
  (labelKey: 'all', value: null),
  (labelKey: 'women', value: 'women'),
  (labelKey: 'men', value: 'men'),
];

const _sortOptions = [
  (label: 'Price: Low to High', value: 'price_asc'),
  (label: 'Price: High to Low', value: 'price_desc'),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  String _query = '';
  String? _category;
  String? _sort;
  Future<List<Product>>? _resultsFuture;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasActiveSearch => _query.isNotEmpty || _category != null || _sort != null;

  void _runSearch() {
    if (!_hasActiveSearch) {
      setState(() => _resultsFuture = null);
      return;
    }
    setState(() {
      _resultsFuture = context.read<ProductService>().getProducts(
            query: _query,
            category: _category,
            sort: _sort,
          );
    });
  }

  void _pickCategory(String category) {
    setState(() {
      _category = category;
      _resultsFuture = context.read<ProductService>().getProducts(category: category);
    });
  }

  void _searchFor(String term) {
    _controller.text = term;
    _query = term;
    _runSearch();
  }

  Future<void> _toggleWishlist(Product product) async {
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
    final wishlist = context.watch<WishlistService>();
    final strings = AppStrings.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(strings.t('searchTitle').toUpperCase())),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.t('searchHint'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                _query = value;
                _runSearch();
              },
              onSubmitted: (value) {
                _query = value;
                _runSearch();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in _categoryFilters)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: ChoiceChip(
                              label: Text(strings.t(filter.labelKey)),
                              selected: _category == filter.value,
                              onSelected: (_) {
                                _category = filter.value;
                                _runSearch();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    _sort = value;
                    _runSearch();
                  },
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
          Expanded(
            child: _resultsFuture == null
                ? _SearchLanding(onPickCategory: _pickCategory, onPickTrending: _searchFor)
                : FutureBuilder<List<Product>>(
                    future: _resultsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerProductGrid(itemCount: 6);
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Could not search: ${snapshot.error}'));
                      }
                      final results = snapshot.data ?? [];
                      if (results.isEmpty) {
                        return EmptyState(
                          icon: Icons.search_off,
                          title: strings.t('searchNoResults'),
                          message: 'Try a different search term or filter.',
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: results.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, index) {
                          final product = results[index];
                          return ProductCard(
                            product: product,
                            isWishlisted: wishlist.isWishlisted(product.id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: product.id),
                              ),
                            ),
                            onToggleWishlist: () => _toggleWishlist(product),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchLanding extends StatelessWidget {
  final ValueChanged<String> onPickCategory;
  final ValueChanged<String> onPickTrending;

  const _SearchLanding({required this.onPickCategory, required this.onPickTrending});

  static const _categories = [
    (labelKey: 'women', category: 'women', image: 'shirt1.png'),
    (labelKey: 'men', category: 'men', image: 'shirt2.png'),
  ];

  static const _trending = ['Summer Dress', 'Denim Jacket', 'Formal Trousers', 'Floral Blouse'];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.t('searchShopByCategory'), style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final category in _categories) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onPickCategory(category.category),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: Image.asset(productAssetPath(category.image), fit: BoxFit.cover),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: Text(
                              strings.t(category.labelKey),
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (category != _categories.last) const SizedBox(width: AppSpacing.md),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(strings.t('searchTrending'), style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final term in _trending)
                ActionChip(
                  label: Text(term),
                  avatar: const Icon(Icons.trending_up, size: 16),
                  onPressed: () => onPickTrending(term),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
