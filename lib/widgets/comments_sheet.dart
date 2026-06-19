import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../core/avatar_helper.dart';
import '../core/supabase_client.dart';
import '../providers/auth_provider.dart' as auth_prov;
import '../providers/users_provider.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String pollId;
  final String pollQuestion;
  final int commentCount;
  const CommentsSheet({
    super.key,
    required this.pollId,
    required this.pollQuestion,
    required this.commentCount,
  });

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _replyingToUsername;
  int? _replyingToIndex;
  bool _hasText = false;
  bool _loading = true;
  bool _submitting = false;

  final List<_Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (widget.pollId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await supabase
          .from('comments')
          .select('id, text, created_at, likes, reply_to_id, author:profiles!author_id(id, name, handle)')
          .eq('poll_id', widget.pollId)
          .order('created_at', ascending: true);

      if (!mounted) return;
      final uid = supabase.auth.currentUser?.id;
      setState(() {
        _loading = false;
        _comments.clear();
        _comments.addAll((data as List).map((row) {
          final author = row['author'] as Map<String, dynamic>;
          return _Comment(
            id: row['id'] as String,
            userId: author['id'] as String,
            username: author['name'] as String? ?? '',
            text: row['text'] as String,
            timestamp: _timeAgo(DateTime.parse(row['created_at'] as String)),
            likes: row['likes'] as int? ?? 0,
            isOwn: author['id'] == uid,
            isReply: row['reply_to_id'] != null,
          );
        }));
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    if (text.length > 1000) return; // hard cap matches DB constraint
    _submitting = true;
    HapticFeedback.lightImpact();

    final uid = supabase.auth.currentUser?.id;
    final me = ref.read(currentUserProvider);

    final body = _replyingToUsername != null ? '@$_replyingToUsername $text' : text;

    // Optimistic insert
    final optimistic = _Comment(
      id: '',
      userId: uid ?? '',
      username: me?.name ?? '',
      text: body,
      timestamp: 'now',
      likes: 0,
      isOwn: true,
      isReply: _replyingToUsername != null,
    );

    final insertAt = _replyingToIndex != null ? _replyingToIndex! + 1 : 0;
    setState(() {
      _comments.insert(insertAt, optimistic);
      _controller.clear();
      _replyingToUsername = null;
      _replyingToIndex = null;
    });
    _focusNode.unfocus();

    if (uid == null || widget.pollId.isEmpty) return;
    try {
      await supabase.from('comments').insert({
        'poll_id': widget.pollId,
        'author_id': uid,
        'text': body,
      });
    } catch (_) {
    } finally {
      _submitting = false;
    }
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

  Future<void> _deleteComment(int index) async {
    final comment = _comments[index];
    setState(() => _comments.removeAt(index));
    if (comment.id.isNotEmpty) {
      try {
        await supabase.from('comments').delete().eq('id', comment.id);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final me = ref.watch(currentUserProvider);
    final authUser = ref.watch(auth_prov.currentUserProvider);
    final myAvatarColor = AvatarHelper.colorFor(authUser?.id ?? me?.id ?? '');
    final myInitial = AvatarHelper.initialFor(displayName: me?.name ?? '');

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

          Container(height: 0.5, color: const Color(0xFF303030)),

          // ── Comments list ─────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.textTertiary),
                      ),
                    ),
                  )
                : _comments.isEmpty
                    ? _EmptyComments()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) => _CommentRow(
                          comment: _comments[i],
                          onReply: () => _startReply(_comments[i].username, i),
                          onDelete: _comments[i].isOwn
                              ? () => _deleteComment(i)
                              : null,
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
                  const Icon(Icons.reply_rounded,
                      size: 16, color: AppColors.textSecondary),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: myAvatarColor,
                    child: Text(
                      myInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  return 'now';
}

// ─────────────────────────────────────────────
class _EmptyComments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.textTertiary, size: 40),
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
class _Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final String timestamp;
  final int likes;
  final bool isOwn;
  final bool isReply;

  const _Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
    required this.likes,
    this.isOwn = false,
    this.isReply = false,
  });
}

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
          CircleAvatar(
            radius: 15,
            backgroundColor: AvatarHelper.colorFor(widget.comment.userId),
            child: Text(
              AvatarHelper.initialFor(displayName: widget.comment.username),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
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
