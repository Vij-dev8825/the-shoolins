import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';

class HeroVideo extends StatefulWidget {
  const HeroVideo({super.key});

  @override
  State<HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<HeroVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/branding/hero_video.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _controller.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Image.asset(productAssetPath('shirt3.png'), fit: BoxFit.cover),
          Positioned(
            right: 12,
            top: 12,
            child: _MuteButton(muted: _muted, onTap: _toggleMute, visible: _ready),
          ),
        ],
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  final bool muted;
  final bool visible;
  final VoidCallback onTap;

  const _MuteButton({required this.muted, required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: visible ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface.withValues(alpha: 0.6), width: 1),
          ),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: AppColors.surface,
            size: 18,
          ),
        ),
      ),
    );
  }
}
