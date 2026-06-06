import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_radius.dart';

class CommentsSheet extends StatefulWidget {
  final String pollQuestion;
  final int commentCount;
  const CommentsSheet(
      {super.key, required this.pollQuestion, required this.commentCount});

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
    const _Comment(
        avatarLabel: 'RZ',
        avatarColor: Color(0xFF1A5C36),
        username: 'RoronoaZoro',
        text: 'Escanor is clearly the strongest, no debate!',
        timestamp: '2h',
        likes: 14),
    const _Comment(
        avatarLabel: 'MD',
        avatarColor: Color(0xFF7A3800),
        username: 'MonkeyDLuffy',
        text: "I'd put Zoro higher honestly 🔥",
        timestamp: '3h',
        likes: 8),
    const _Comment(
        avatarLabel: 'IC',
        avatarColor: Color(0xFF1A3A70),
        username: 'Ichigo',
        text: 'The gap between Escanor and Ban is way too big',
        timestamp: '5h',
        likes: 5),
    const _Comment(
        avatarLabel: 'GK',
        avatarColor: Color(0xFF5B1A7A),
        username: 'GokuSon',
        text: 'Ban with full power is seriously underrated though',
        timestamp: '8h',
        likes: 3),
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
      avatarColor: const Color(0xFF7B6914),
      username: 'Clint',
      text: _replyingToUsername != null ? '@$_replyingToUsername $text' : text,
      timestamp: 'now',
      likes: 0,
      isOwn: true,
      isReply: _replyingToUsername != null,
    );
    setState(() {
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
    Future.delayed(
        const Duration(milliseconds: 50), () => _focusNode.requestFocus());
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
      height: MediaQuery.of(context).size.height * 0.76,
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag handle ───────────────────────────
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A4A),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),

          // ── Header ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_comments.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thin separator
          Container(height: 0.5, color: const Color(0xFF303030)),

          // ── Comments list ─────────────────────────
          Expanded(
            child: _comments.isEmpty
                ? _EmptyComments()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) => _CommentRow(
                      comment: _comments[i],
                      onReply: () => _startReply(_comments[i].username, i),
                      onDelete:
                          _comments[i].isOwn ? () => _deleteComment(i) : null,
                    ),
                  ),
          ),

          // ── Replying-to banner ────────────────────
          if (_replyingToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(
                  top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to @$_replyingToUsername',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 40,
                      height: 36,
                      child: Center(
                        child: Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Input bar ────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceModal,
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              keyboardHeight > 0 ? keyboardHeight + 10 : bottom + 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Own avatar
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF7B6914),
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Text input
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceInput,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLength: 280,
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPlaceholder,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                        ),
                        cursorColor: AppColors.accentPrimary,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: GestureDetector(
                    onTap: _hasText ? _submitComment : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _hasText
                            ? AppColors.accentPrimary
                            : AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: _hasText
                            ? Colors.white
                            : AppColors.textTertiary,
                      ),
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
// Empty state
// ─────────────────────────────────────────────
class _EmptyComments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.textTertiary,
            size: 40,
          ),
          SizedBox(height: 14),
          Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Be the first to share your thoughts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
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
    required this.comment,
    required this.onReply,
    this.onDelete,
  });

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow>
    with SingleTickerProviderStateMixin {
  bool _liked = false;
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() => _liked = !_liked);
    _likeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final likes = widget.comment.likes + (_liked ? 1 : 0);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 20,
        left: widget.comment.isReply ? 32 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 15,
            backgroundColor: widget.comment.avatarColor,
            child: Text(
              widget.comment.avatarLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Content block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username · timestamp on one line
                Row(
                  children: [
                    Text(
                      widget.comment.username,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${widget.comment.timestamp}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Comment body
                Text(
                  widget.comment.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),

                // Action row — compact
                Row(
                  children: [
                    // Like
                    GestureDetector(
                      onTap: _toggleLike,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _likeScale,
                              child: Icon(
                                _liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 17,
                                color: _liked
                                    ? const Color(0xFFFF5C7A)
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (likes > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '$likes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _liked
                                      ? const Color(0xFFFF5C7A)
                                      : AppColors.textSecondary,
                                  height: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Reply
                    GestureDetector(
                      onTap: widget.onReply,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1,
                          ),
                        ),
                      ),
                    ),

                    // Delete (own comments)
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 18),
                      GestureDetector(
                        onTap: widget.onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDestructive,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
