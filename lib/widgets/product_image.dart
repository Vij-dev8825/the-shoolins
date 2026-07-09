import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';

/// Admin-uploaded products carry their photo as base64 in [imageBase64];
/// the original seeded catalog instead ships as a bundled asset named by
/// [imageFilename]. Prefer the uploaded photo when present.
ImageProvider productImageProvider({required String imageFilename, String? imageBase64}) {
  if (imageBase64 != null && imageBase64.isNotEmpty) {
    return MemoryImage(base64Decode(imageBase64));
  }
  return AssetImage(productAssetPath(imageFilename));
}

class ProductImage extends StatelessWidget {
  final String imageFilename;
  final String? imageBase64;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imageFilename,
    this.imageBase64,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image(
      image: productImageProvider(imageFilename: imageFilename, imageBase64: imageBase64),
      fit: fit,
    );
  }
}
