import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../screens/language_select_screen.dart';
import '../screens/main_shell.dart';
import '../screens/notifications_screen.dart';
import '../screens/orders_screen.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

const List<({IconData icon, String labelKey})> _tabDestinations = [
  (icon: Icons.home_outlined, labelKey: 'navHome'),
  (icon: Icons.search_outlined, labelKey: 'navSearch'),
  (icon: Icons.favorite_border, labelKey: 'navWishlist'),
  (icon: Icons.shopping_bag_outlined, labelKey: 'navCart'),
  (icon: Icons.person_outline, labelKey: 'navProfile'),
];

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final unreadCount = context.watch<NotificationService>().unreadCount;
    final strings = AppStrings.of(context);
    final displayName = (user?.name.isNotEmpty ?? false) ? user!.name : strings.t('guestUser');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(productAssetPath('shirt3.png'), fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accentDark.withValues(alpha: 0.55),
                        AppColors.accentDark.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.accent,
                          child: Text(
                            initial,
                            style: AppTypography.headline.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          displayName,
                          style: AppTypography.title.copyWith(color: AppColors.surface),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '+91 ${user.mobile}',
                            style: AppTypography.bodyMuted.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                for (var i = 0; i < _tabDestinations.length; i++)
                  ListTile(
                    leading: Icon(_tabDestinations[i].icon, color: AppColors.accentDark),
                    title: Text(strings.t(_tabDestinations[i].labelKey)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<MainTabIndex>().value = i;
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications_none_outlined, color: AppColors.accentDark),
                  title: Text(strings.t('notificationsTitle')),
                  trailing: unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined, color: AppColors.accentDark),
                  title: Text(strings.t('ordersTitle')),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined, color: AppColors.accentDark),
                  title: Text(strings.t('changeLanguage')),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanguageSelectScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_outlined, color: AppColors.error),
                  title: Text(
                    strings.t('profileLogout'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<AuthService>().logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
