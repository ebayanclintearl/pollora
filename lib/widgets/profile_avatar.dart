import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/avatar_helper.dart';

/// Renders a circular avatar: real photo when available, initials otherwise.
/// Pass [localFile] to show a locally-picked image before it's uploaded.
class ProfileAvatar extends StatelessWidget {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final File? localFile;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.localFile,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final color = AvatarHelper.colorFor(userId);
    final initial = AvatarHelper.initialFor(displayName: displayName);
    final size = radius * 2;

    Widget fallback = _Initials(size: size, color: color, initial: initial);

    if (localFile != null) {
      return ClipOval(
        child: Image.file(
          localFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      );
    }

    return fallback;
  }
}

class _Initials extends StatelessWidget {
  final double size;
  final Color color;
  final String initial;

  const _Initials(
      {required this.size, required this.color, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
