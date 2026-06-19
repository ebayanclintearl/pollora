import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Renders a poll image from a Storage URL, a local file path, or nothing.
/// The [fit] and [aspectRatio] are applied by the caller — this widget fills
/// whatever size the parent assigns.
class PollImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;

  const PollImage({super.key, required this.path, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) return const SizedBox.shrink();

    if (path!.startsWith('http://') || path!.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path!,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => Container(color: AppColors.surfaceElevated),
        errorWidget: (_, __, ___) => _broken(),
      );
    }

    return Image.file(
      File(path!),
      fit: fit,
      errorBuilder: (_, __, ___) => _broken(),
    );
  }

  Widget _broken() => Container(
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppColors.textTertiary, size: 28),
        ),
      );
}
