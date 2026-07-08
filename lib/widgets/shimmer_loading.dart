import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerBox({super.key, this.width, this.height, this.borderRadius});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 3, 0),
                end: Alignment(0 + t * 3, 0),
                colors: const [
                  AppColors.surfaceMuted,
                  AppColors.divider,
                  AppColors.surfaceMuted,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerProductGrid extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ShimmerProductGrid({
    super.key,
    this.itemCount = 4,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerBox(
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(width: 100, height: 12),
          const SizedBox(height: 6),
          const ShimmerBox(width: 60, height: 12),
        ],
      ),
    );
  }
}
