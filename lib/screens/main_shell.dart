import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/cart_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'wishlist_screen.dart';

// Lets the side drawer (opened from any tab) switch the bottom-nav tab it's
// nested inside, without the tab screens needing direct references to each other.
class MainTabIndex extends ValueNotifier<int> {
  MainTabIndex() : super(0);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final MainTabIndex _tabIndex = MainTabIndex();

  static const _tabs = [
    HomeScreen(),
    SearchScreen(),
    WishlistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  static const _navIcons = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, labelKey: 'navHome'),
    (icon: Icons.search_outlined, activeIcon: Icons.search, labelKey: 'navSearch'),
    (icon: Icons.favorite_border, activeIcon: Icons.favorite, labelKey: 'navWishlist'),
    (icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, labelKey: 'navCart'),
    (icon: Icons.person_outline, activeIcon: Icons.person, labelKey: 'navProfile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartService>().fetchCart();
    });
  }

  @override
  void dispose() {
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartService>().itemCount;
    final strings = AppStrings.of(context);
    final items = [
      for (final item in _navIcons)
        (icon: item.icon, activeIcon: item.activeIcon, label: strings.t(item.labelKey)),
    ];

    return ChangeNotifierProvider<MainTabIndex>.value(
      value: _tabIndex,
      child: ValueListenableBuilder<int>(
        valueListenable: _tabIndex,
        builder: (context, index, _) {
          return Scaffold(
            body: IndexedStack(index: index, children: _tabs),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accentDark,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentDark.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _NavButton(
                        icon: items[i].icon,
                        activeIcon: items[i].activeIcon,
                        label: items[i].label,
                        selected: index == i,
                        badgeCount: i == 3 ? cartCount : 0,
                        onTap: () => _tabIndex.value = i,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    selected ? activeIcon : icon,
                    color: selected ? AppColors.surface : AppColors.surface.withValues(alpha: 0.55),
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(color: AppColors.ink, fontSize: 9, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (selected) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.surface, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
