import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';

class CommentsSheet extends StatefulWidget {
  final String pollQuestion;
  final int commentCount;
  const CommentsSheet({super.key, required this.pollQuestion, required this.commentCount});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _replyingToUsername;
  int? _replyingToIndex;
  bool _hasText = false;

  final List<_Comment> _comments = [
    _Comment(avatarLabel: 'RZ', avatarColor: Color(0xFF1A6B3C), username: 'RoronoaZoro',
        text: 'Escanor is clearly the strongest, no debate!', timestamp: '2h ago', likes: 14),
    _Comment(avatarLabel: 'MD', avatarColor: Color(0xFF8B4513), username: 'MonkeyDLuffy',
        text: "I'd put Zoro higher honestly 🔥", timestamp: '3h ago', likes: 8),
    _Comment(avatarLabel: 'IC', avatarColor: Color(0xFF2B4D8B), username: 'Ichigo',
        text: 'The gap between Escanor and Ban is way too big', timestamp: '5h ago', likes: 5),
    _Comment(avatarLabel: 'GK', avatarColor: Color(0xFF6B2B8B), username: 'GokuSon',
        text: 'Ban with full power is seriously underrated though', timestamp: '8h ago', likes: 3),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    final newComment = _Comment(
      avatarLabel: 'C',
      avatarColor: const Color(0xFF8B6914),
      username: 'Clint',
      text: _replyingToUsername != null ? '@$_replyingToUsername $text' : text,
      timestamp: 'now',
      likes: 0,
      isOwn: true,
      isReply: _replyingToUsername != null,
    );
    setState(() {
      // Replies go right after the parent; new top-level comments go at the top
      final insertAt = _replyingToIndex != null ? _replyingToIndex! + 1 : 0;
      _comments.insert(insertAt, newComment);
      _controller.clear();
      _replyingToUsername = null;
      _replyingToIndex = null;
    });
    _focusNode.unfocus();
  }

  void _startReply(String username, int index) {
    setState(() {
      _replyingToUsername = username;
      _replyingToIndex = index;
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 50), () => _focusNode.requestFocus());
  }

  void _cancelReply() {
    setState(() {
      _replyingToUsername = null;
      _replyingToIndex = null;
    });
    _controller.clear();
    _focusNode.unfocus();
  }

  void _deleteComment(int index) {
    setState(() => _comments.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Text('Comments', style: AppTypography.titleMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimaryMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_comments.length}',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textAccent),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderDefault),

          // Comments list
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textTertiary, size: 48),
                        SizedBox(height: 12),
                        Text('No comments yet', style: AppTypography.titleSmall),
                        SizedBox(height: 4),
                        Text('Be the first to comment', style: AppTypography.labelMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) => _CommentRow(
                      comment: _comments[i],
                      onReply: () => _startReply(_comments[i].username, i),
                      onDelete: _comments[i].isOwn ? () => _deleteComment(i) : null,
                    ),
                  ),
          ),

          // Replying-to banner
          if (_replyingToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceElevated,
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to @$_replyingToUsername',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderDefault)),
              color: AppColors.surfaceModal,
            ),
            padding: EdgeInsets.fromLTRB(16, 10, 16, keyboardHeight > 0 ? keyboardHeight + 10 : bottom + 10),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF8B6914),
                  child: Text('C', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLength: 280,
                      maxLines: null,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      cursorColor: AppColors.accentPrimary,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _hasText ? _submitComment : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _hasText ? AppColors.accentPrimary : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: _hasText ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Comment model
// ─────────────────────────────────────────────
class _Comment {
  final String avatarLabel;
  final Color avatarColor;
  final String username;
  final String text;
  final String timestamp;
  final int likes;
  final bool isOwn;
  final bool isReply;

  const _Comment({
    required this.avatarLabel,
    required this.avatarColor,
    required this.username,
    required this.text,
    required this.timestamp,
    required this.likes,
    this.isOwn = false,
    this.isReply = false,
  });
}

// ─────────────────────────────────────────────
// Comment row
// ─────────────────────────────────────────────
class _CommentRow extends StatefulWidget {
  final _Comment comment;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _CommentRow({
    super.key,
    required this.comment,
    required this.onReply,
    this.onDelete,
  });

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final likes = widget.comment.likes + (_liked ? 1 : 0);

    return Padding(
      padding: EdgeInsets.only(bottom: 18, left: widget.comment.isReply ? 28 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.comment.avatarColor,
            child: Text(
              widget.comment.avatarLabel,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + timestamp — de-emphasised meta row
                Row(
                  children: [
                    Text(
                      widget.comment.username,
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.comment.timestamp,
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Comment text — primary, readable
                Text(
                  widget.comment.text,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 8),

                // Actions row — 44dp min height for thumb target
                SizedBox(
                  height: 44,
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Like
                    GestureDetector(
                      onTap: () => setState(() => _liked = !_liked),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: _liked ? const Color(0xFFFF5C7A) : AppColors.textTertiary,
                          ),
                          if (likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$likes',
                              style: AppTypography.labelMedium.copyWith(
                                color: _liked ? const Color(0xFFFF5C7A) : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Reply
                    GestureDetector(
                      onTap: widget.onReply,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Reply',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary),
                      ),
                    ),

                    // Delete (own comments only)
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: widget.onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'Delete',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.textDestructive),
                        ),
                      ),
                    ],
                  ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
