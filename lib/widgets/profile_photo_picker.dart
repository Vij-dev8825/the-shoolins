import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// Encoding as base64 into the user record (rather than uploading to file
// storage) keeps this self-contained — there's no S3/CDN in this project.
// Resizing at pick-time keeps that payload reasonable.
class ProfilePhotoPicker extends StatefulWidget {
  final String? photoBase64;
  final String fallbackInitial;
  final ValueChanged<String> onChanged;

  const ProfilePhotoPicker({
    super.key,
    required this.photoBase64,
    required this.fallbackInitial,
    required this.onChanged,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  bool _picking = false;

  Future<void> _pickPhoto() async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      widget.onChanged(base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _picking ? null : _pickPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: AppColors.accent, width: 2)),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.accentSurface,
              backgroundImage: widget.photoBase64 != null
                  ? MemoryImage(base64Decode(widget.photoBase64!))
                  : null,
              child: widget.photoBase64 == null
                  ? Text(
                      widget.fallbackInitial,
                      style: AppTypography.headline.copyWith(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ink,
                border: Border.fromBorderSide(BorderSide(color: AppColors.surface, width: 2)),
              ),
              child: _picking
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                    )
                  : const Icon(Icons.camera_alt, size: 14, color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }
}
