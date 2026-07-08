import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import '../utils/currency.dart';

class PriceText extends StatelessWidget {
  final double price;
  final TextStyle? style;

  const PriceText(this.price, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(formatInr(price), style: style ?? AppTypography.price);
  }
}
