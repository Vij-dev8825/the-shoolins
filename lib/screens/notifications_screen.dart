import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final service = context.watch<NotificationService>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('notificationsTitle').toUpperCase())),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator())
          : service.notifications.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: strings.t('notificationsEmpty'),
                  message: 'Order updates and offers will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: service.notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _NotificationCard(
                    notification: service.notifications[index],
                  ),
                ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.welcome:
        return Icons.celebration_outlined;
      case NotificationType.order:
        return Icons.local_shipping_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.wishlist:
        return Icons.favorite_border;
    }
  }

  String _relativeTime() {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${notification.createdAt.day.toString().padLeft(2, '0')}/'
        '${notification.createdAt.month.toString().padLeft(2, '0')}/'
        '${notification.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: notification.read ? AppColors.surface : AppColors.accentSurface.withValues(alpha: 0.4),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.accentSurface, shape: BoxShape.circle),
            child: Icon(_icon, size: 20, color: AppColors.accentDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTypography.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!notification.read) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(notification.message, style: AppTypography.bodyMuted),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _relativeTime(),
                  style: AppTypography.label.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
