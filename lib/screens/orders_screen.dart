import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/invoice.dart';
import '../utils/order_ref.dart';
import '../widgets/empty_state.dart';
import '../widgets/price_text.dart';
import '../widgets/product_image.dart';
import '../widgets/shine_effect.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = context.read<OrderService>().getOrders();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('ordersTitle').toUpperCase())),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load orders: ${snapshot.error}',
                style: AppTypography.bodyMuted,
              ),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: strings.t('ordersEmpty'),
              message: 'Your past orders will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _generatingInvoice = false;

  Future<void> _downloadInvoice() async {
    setState(() => _generatingInvoice = true);
    try {
      final user = context.read<AuthService>().user;
      final bytes = await buildInvoicePdf(order: widget.order, user: user);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'invoice-${shortOrderRef(widget.order.id).toLowerCase()}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _generatingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final itemCount = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final visibleThumbs = order.items.length > 4 ? 3 : order.items.length;
    final overflowCount = order.items.length - visibleThumbs;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppTypography.headline.copyWith(fontSize: 18),
                          children: [
                            const TextSpan(text: 'Order '),
                            TextSpan(
                              text: '#${shortOrderRef(order.id)}',
                              style: const TextStyle(color: AppColors.accentDark),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ShineEffect(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'CONFIRMED',
                              style: AppTypography.label.copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(order.createdAt)} · $itemCount item${itemCount == 1 ? '' : 's'}',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 60,
                  child: Stack(
                    children: [
                      for (var i = 0; i < visibleThumbs; i++)
                        Positioned(
                          left: i * 42.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                border: Border.all(color: AppColors.surface, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ink.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ProductImage(
                                imageFilename: order.items[i].image,
                                imageBase64: order.items[i].imageBase64,
                              ),
                            ),
                          ),
                        ),
                      if (overflowCount > 0)
                        Positioned(
                          left: visibleThumbs * 42.0,
                          child: Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accentSurface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                            child: Text(
                              '+$overflowCount',
                              style: AppTypography.title.copyWith(color: AppColors.accentDark),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: AppColors.accentSurface),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TOTAL', style: AppTypography.label),
                    PriceText(
                      order.total,
                      style: AppTypography.headline.copyWith(color: AppColors.accentDark, fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ShineEffect(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentDark,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    onPressed: _generatingInvoice ? null : _downloadInvoice,
                    icon: _generatingInvoice
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentDark),
                          )
                        : const Icon(Icons.download_outlined, size: 18),
                    label: Text(_generatingInvoice ? 'PREPARING...' : 'DOWNLOAD INVOICE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
