import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_drawer.dart';
import 'edit_profile_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final strings = AppStrings.of(context);
    final locationLine = [
      user?.city,
      user?.state,
    ].where((part) => part != null && part.isNotEmpty).join(', ');

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(strings.t('profileTitle').toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.accent, width: 2)),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.accentSurface,
                    backgroundImage: (user?.photoBase64 != null)
                        ? MemoryImage(base64Decode(user!.photoBase64!))
                        : null,
                    child: user?.photoBase64 == null
                        ? Text(
                            (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                            style: AppTypography.headline.copyWith(color: AppColors.accentDark),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  (user?.name.isNotEmpty ?? false) ? user!.name : strings.t('guestUser'),
                  style: AppTypography.headline,
                ),
                const SizedBox(height: 2),
                Text('+91 ${user?.mobile ?? ''}', style: AppTypography.bodyMuted),
                if (locationLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(locationLine, style: AppTypography.bodyMuted),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileMenuCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.person_outline,
                label: strings.t('editProfile'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              const Divider(height: 1),
              _ProfileMenuTile(
                icon: Icons.receipt_long_outlined,
                label: strings.t('profileOrders'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: () => context.read<AuthService>().logout(),
            child: Text(strings.t('profileLogout')),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileMenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentDark),
      title: Text(label, style: AppTypography.title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
      onTap: onTap,
    );
  }
}
