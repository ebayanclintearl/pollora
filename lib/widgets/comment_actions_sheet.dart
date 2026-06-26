import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import 'pressable.dart';

/// Long-press action sheet for a comment. Shows Report (others' comments)
/// and/or Delete (own comments) — pass only the callbacks that apply.
Future<void> showCommentActions(
  BuildContext context, {
  VoidCallback? onReport,
  VoidCallback? onDelete,
}) {
  if (onReport == null && onDelete == null) return Future.value();
  final bottom = MediaQuery.of(context).padding.bottom;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (onReport != null)
            _CommentAction(
              icon: Icons.flag_outlined,
              label: 'Report comment',
              sheetCtx: sheetCtx,
              onTap: onReport,
            ),
          if (onDelete != null)
            _CommentAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete comment',
              sheetCtx: sheetCtx,
              onTap: onDelete,
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _CommentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final BuildContext sheetCtx;
  final VoidCallback onTap;

  const _CommentAction({
    required this.icon,
    required this.label,
    required this.sheetCtx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.99,
      onTap: () {
        Navigator.pop(sheetCtx);
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textDestructive),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.textDestructive),
            ),
          ],
        ),
      ),
    );
  }
}
