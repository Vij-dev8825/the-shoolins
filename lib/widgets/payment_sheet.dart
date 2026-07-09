import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency.dart';
import 'shine_effect.dart';

enum _PaymentStep { method, processing, success }

enum _PaymentMethod { upi, card, netBanking, wallet }

const Map<_PaymentMethod, ({IconData icon, String label})> _methods = {
  _PaymentMethod.upi: (icon: Icons.qr_code_rounded, label: 'UPI'),
  _PaymentMethod.card: (icon: Icons.credit_card_rounded, label: 'Credit / Debit Card'),
  _PaymentMethod.netBanking: (icon: Icons.account_balance_rounded, label: 'Net Banking'),
  _PaymentMethod.wallet: (icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
};

/// Shows a simulated payment checkout sheet — a mock effect (method select,
/// processing spinner, success animation) since no real payment gateway
/// credentials are wired up. Returns true once the mock payment "succeeds",
/// or null/false if the user dismisses it before paying.
Future<bool?> showPaymentSheet(BuildContext context, {required double amount}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => _PaymentSheetContent(amount: amount),
  );
}

class _PaymentSheetContent extends StatefulWidget {
  final double amount;

  const _PaymentSheetContent({required this.amount});

  @override
  State<_PaymentSheetContent> createState() => _PaymentSheetContentState();
}

class _PaymentSheetContentState extends State<_PaymentSheetContent> {
  _PaymentStep _step = _PaymentStep.method;
  _PaymentMethod _selected = _PaymentMethod.upi;

  Future<void> _pay() async {
    setState(() => _step = _PaymentStep.processing);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _step = _PaymentStep.success);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _PaymentStep.method,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: switch (_step) {
              _PaymentStep.method => _MethodStep(
                  amount: widget.amount,
                  selected: _selected,
                  onSelect: (m) => setState(() => _selected = m),
                  onPay: _pay,
                ),
              _PaymentStep.processing => const _ProcessingStep(),
              _PaymentStep.success => _SuccessStep(amount: widget.amount),
            },
          ),
        ),
      ),
    );
  }
}

class _MethodStep extends StatelessWidget {
  final double amount;
  final _PaymentMethod selected;
  final ValueChanged<_PaymentMethod> onSelect;
  final VoidCallback onPay;

  const _MethodStep({
    required this.amount,
    required this.selected,
    required this.onSelect,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.accentDark),
            const SizedBox(width: AppSpacing.xs),
            Text('Secure Checkout', style: AppTypography.title),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Amount payable', style: AppTypography.bodyMuted),
        Text(
          formatInr(amount),
          style: AppTypography.display.copyWith(fontSize: 30, color: AppColors.accentDark),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final entry in _methods.entries) ...[
          _MethodTile(
            icon: entry.value.icon,
            label: entry.value.label,
            selected: selected == entry.key,
            onTap: () => onSelect(entry.key),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        ShineEffect(
          child: ElevatedButton(
            onPressed: onPay,
            child: Text('Pay ${formatInr(amount)}'),
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSurface : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: selected ? AppColors.accent : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.accentDark : AppColors.ink, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.title.copyWith(
                  fontSize: 14,
                  color: selected ? AppColors.accentDark : AppColors.ink,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.accent : AppColors.divider,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Processing your payment…', style: AppTypography.title.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.xs),
          Text('Please don\'t close this screen', style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final double amount;

  const _SuccessStep({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Payment Successful', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(formatInr(amount), style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}
