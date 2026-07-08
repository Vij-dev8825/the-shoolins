import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Wraps a child (a CTA button, badge, hero, etc.) with a periodic diagonal
// light sweep — a subtle "premium" cue rather than a constant animation.
class ShineEffect extends StatefulWidget {
  final Widget child;
  final Duration sweepDuration;
  final Duration pauseBetweenSweeps;

  const ShineEffect({
    super.key,
    required this.child,
    this.sweepDuration = const Duration(milliseconds: 1300),
    this.pauseBetweenSweeps = const Duration(seconds: 3),
  });

  @override
  State<ShineEffect> createState() => _ShineEffectState();
}

class _ShineEffectState extends State<ShineEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.sweepDuration);
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await _controller.forward(from: 0);
      if (!mounted) return;
      await Future.delayed(widget.pauseBetweenSweeps);
    }
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
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.6 + 3.2 * t, -1),
              end: Alignment(-0.6 + 3.2 * t, 1),
              colors: [
                Colors.transparent,
                AppColors.secondary.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0.85),
                AppColors.secondary.withValues(alpha: 0.45),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
