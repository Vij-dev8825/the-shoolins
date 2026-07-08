import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const TrustBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.accentDark),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
