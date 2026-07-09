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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${shortOrderRef(order.id)}',
                    style: AppTypography.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(_formatDate(order.createdAt), style: AppTypography.bodyMuted),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 56,
              child: Stack(
                children: [
                  for (var i = 0; i < order.items.length && i < 4; i++)
                    Positioned(
                      left: i * 40.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.surface, width: 2),
                            ),
                          ),
                          child: ProductImage(
                            imageFilename: order.items[i].image,
                            imageBase64: order.items[i].imageBase64,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('$itemCount item${itemCount == 1 ? '' : 's'}', style: AppTypography.bodyMuted),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTypography.title),
                PriceText(order.total, style: AppTypography.title.copyWith(color: AppColors.accentDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _generatingInvoice ? null : _downloadInvoice,
              icon: _generatingInvoice
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                    )
                  : const Icon(Icons.download_outlined, size: 18),
              label: Text(_generatingInvoice ? 'PREPARING...' : 'DOWNLOAD INVOICE'),
            ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
