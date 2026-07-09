import 'package:flutter/material.dart';

// Full-screen pinch-zoom/pan viewer for a product image, entered via a Hero
// flight from the thumbnail that triggered it. Kept generic (image provider +
// tag in, no product/service imports) so it can be reused for any image later.
class ZoomableImageViewer extends StatefulWidget {
  final ImageProvider image;
  final Object heroTag;

  const ZoomableImageViewer({super.key, required this.image, required this.heroTag});

  static void show(BuildContext context, {required ImageProvider image, required Object heroTag}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, _, _) => ZoomableImageViewer(image: image, heroTag: heroTag),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<ZoomableImageViewer> createState() => _ZoomableImageViewerState();
}

class _ZoomableImageViewerState extends State<ZoomableImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late final AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _lastDoubleTapDetails;

  static const double _zoomedScale = 2.6;

  @override
  void initState() {
    super.initState();
    _zoomAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() {
        if (_zoomAnimation != null) {
          _transformController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _zoomAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final isZoomedIn = _transformController.value.getMaxScaleOnAxis() > 1.05;
    final Matrix4 endMatrix;
    if (isZoomedIn) {
      endMatrix = Matrix4.identity();
    } else {
      final position = _lastDoubleTapDetails!.localPosition;
      endMatrix = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (_zoomedScale - 1),
          -position.dy * (_zoomedScale - 1),
          0,
          1,
        )
        ..scaleByDouble(_zoomedScale, _zoomedScale, _zoomedScale, 1);
    }
    _zoomAnimation = Matrix4Tween(begin: _transformController.value, end: endMatrix).animate(
      CurvedAnimation(parent: _zoomAnimController, curve: Curves.easeOutCubic),
    );
    _zoomAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (details) => _lastDoubleTapDetails = details,
              onDoubleTap: _handleDoubleTap,
              child: Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 1,
                    maxScale: 4,
                    child: Image(image: widget.image, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _CloseButton(onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        child: const Icon(Icons.close, color: Colors.white, size: 22),
      ),
    );
  }
}
