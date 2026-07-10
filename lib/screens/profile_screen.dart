import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_drawer.dart';
import '../widgets/shine_effect.dart';
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
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(strings.t('profileTitle').toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileHeaderCard(
            user: user,
            locationLine: locationLine,
            guestLabel: strings.t('guestUser'),
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
              const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
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
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: () => context.read<AuthService>().logout(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(strings.t('profileLogout')),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final User? user;
  final String locationLine;
  final String guestLabel;

  const _ProfileHeaderCard({required this.user, required this.locationLine, required this.guestLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentDark.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 76,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentDark],
              ),
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -38),
                  child: ShineEffect(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
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
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Column(
                    children: [
                      Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name : guestLabel,
                        style: AppTypography.headline,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text('+91 ${user?.mobile ?? ''}', style: AppTypography.bodyMuted),
                      if (locationLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_outlined, size: 14, color: AppColors.inkMuted),
                            const SizedBox(width: 2),
                            Text(locationLine, style: AppTypography.bodyMuted),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      leading: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentSurface,
        ),
        child: Icon(icon, color: AppColors.accentDark, size: 20),
      ),
      title: Text(label, style: AppTypography.title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
      onTap: onTap,
    );
  }
}
