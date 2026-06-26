import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../core/supabase_client.dart';
import '../providers/moderation_provider.dart';
import '../providers/polls_provider.dart';
import '../providers/users_provider.dart';
import 'comment_actions_sheet.dart';
import 'pressable.dart';
import 'profile_avatar.dart';
import 'report_sheet.dart';

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
  String? _replyingToId;
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
          .select(
              'id, text, created_at, likes, reply_to_id, author:profiles!author_id(id, name, handle, avatar_url)')
          .eq('poll_id', widget.pollId)
          .order('created_at', ascending: true);

      if (!mounted) return;
      final uid = supabase.auth.currentUser?.id;

      // Load which comments the current user has already liked.
      Set<String> likedIds = {};
      if (uid != null && (data as List).isNotEmpty) {
        final ids = data.map((r) => r['id'] as String).toList();
        final liked = await supabase
            .from('comment_likes')
            .select('comment_id')
            .eq('user_id', uid)
            .inFilter('comment_id', ids);
        likedIds =
            (liked as List).map((r) => r['comment_id'] as String).toSet();
      }

      if (!mounted) return;
      final flat = (data as List).map((row) {
        final author = row['author'] as Map<String, dynamic>;
        return _Comment(
          id: row['id'] as String,
          userId: author['id'] as String,
          username: author['name'] as String? ?? '',
          avatarUrl: author['avatar_url'] as String?,
          replyToId: row['reply_to_id'] as String?,
          text: row['text'] as String,
          timestamp: _timeAgo(DateTime.parse(row['created_at'] as String)),
          likes: row['likes'] as int? ?? 0,
          isOwn: author['id'] == uid,
          isReply: row['reply_to_id'] != null,
          isLikedByMe: likedIds.contains(row['id'] as String),
        );
      }).toList();
      // Hide comments from users the current user has blocked.
      final blocked = ref.read(blockProvider);
      final visible = flat.where((c) => !blocked.contains(c.userId)).toList();
      setState(() {
        _loading = false;
        _comments
          ..clear()
          ..addAll(_threadComments(visible));
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

    final body =
        _replyingToUsername != null ? '@$_replyingToUsername $text' : text;

    // Optimistic insert
    final optimistic = _Comment(
      id: '',
      userId: uid ?? '',
      username: me?.name ?? '',
      avatarUrl: me?.avatarUrl,
      text: body,
      timestamp: 'now',
      likes: 0,
      isOwn: true,
      isReply: _replyingToUsername != null,
    );

    final replyToId =
        (_replyingToId?.isNotEmpty == true) ? _replyingToId : null;
    // Replies slot in after their parent thread; new top-level comments go
    // to the top (newest-first).
    final insertAt = _replyingToIndex != null ? _replyingToIndex! + 1 : 0;
    setState(() {
      _comments.insert(insertAt, optimistic);
      _controller.clear();
      _replyingToUsername = null;
      _replyingToId = null;
      _replyingToIndex = null;
    });
    _focusNode.unfocus();

    if (uid == null || widget.pollId.isEmpty) return;
    try {
      await supabase.from('comments').insert({
        'poll_id': widget.pollId,
        'author_id': uid,
        'text': body,
        'reply_to_id': replyToId,
      });
      // Keep the poll card's comment count in sync.
      ref.read(pollsProvider.notifier).bumpCommentCount(widget.pollId, 1);
      // Reload so the optimistic entry is replaced with the real DB row
      // (which has the correct reply_to_id and a real id).
      if (mounted) await _loadComments();
    } catch (_) {
    } finally {
      _submitting = false;
    }
  }

  void _startReply(String username, String commentId, int index) {
    final comment = _comments[index];
    // Cap at 2 levels: if replying to a reply, attach to its parent thread instead
    final effectiveParentId = comment.replyToId ?? commentId;

    // Insert after the last existing reply so the thread reads chronologically
    // and the new reply sits below the comment it answers (not jumping to top).
    int insertIdx = index;
    for (int i = 0; i < _comments.length; i++) {
      if (_comments[i].replyToId == effectiveParentId) insertIdx = i;
    }

    setState(() {
      _replyingToUsername = username;
      _replyingToId = effectiveParentId;
      _replyingToIndex = insertIdx;
    });
    _controller.clear();
    Future.delayed(
        const Duration(milliseconds: 50), () => _focusNode.requestFocus());
  }

  void _cancelReply() {
    setState(() {
      _replyingToUsername = null;
      _replyingToId = null;
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
        ref.read(pollsProvider.notifier).bumpCommentCount(widget.pollId, -1);
      } catch (_) {}
    }
  }

  void _reportComment(String commentId) {
    if (commentId.isEmpty) return;
    showReportSheet(context,
        targetType: 'comment', targetLabel: 'comment', targetId: commentId);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final me = ref.watch(currentUserProvider);

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          onReply: () => _startReply(
                              _comments[i].username, _comments[i].id, i),
                          onDelete: _comments[i].isOwn
                              ? () => _deleteComment(i)
                              : null,
                          onReport: _comments[i].isOwn
                              ? null
                              : () => _reportComment(_comments[i].id),
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
                  Pressable(
                    onTap: _cancelReply,
                    pressedScale: 0.85,
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
                  child: ProfileAvatar(
                    userId: me?.id ?? '',
                    displayName: me?.name,
                    avatarUrl: me?.avatarUrl,
                    radius: 16,
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
                  child: Pressable(
                    onTap: _hasText ? _submitComment : null,
                    pressedScale: 0.86,
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
                        color: _hasText ? Colors.white : AppColors.textTertiary,
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
  final String? avatarUrl;
  final String? replyToId;
  final String text;
  final String timestamp;
  final int likes;
  final bool isOwn;
  final bool isReply;
  final bool isLikedByMe;

  const _Comment({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.replyToId,
    required this.text,
    required this.timestamp,
    required this.likes,
    this.isOwn = false,
    this.isReply = false,
    this.isLikedByMe = false,
  });
}

// Groups replies under their top-level parent (capped at 2 levels).
// Any deeper nesting in existing data is flattened to level 2.
List<_Comment> _threadComments(List<_Comment> flat) {
  final byId = <String, _Comment>{for (final c in flat) c.id: c};

  String rootId(_Comment c) {
    var cur = c;
    while (cur.replyToId != null) {
      final parent = byId[cur.replyToId!];
      if (parent == null) break;
      cur = parent;
    }
    return cur.id;
  }

  // Newest top-level comments first; replies stay chronological under each.
  final topLevel =
      flat.where((c) => c.replyToId == null).toList().reversed.toList();
  final childrenOf = <String, List<_Comment>>{};
  for (final c in flat) {
    if (c.replyToId != null) {
      childrenOf.putIfAbsent(rootId(c), () => []).add(c);
    }
  }

  final result = <_Comment>[];
  final placed = <String>{};
  for (final p in topLevel) {
    result.add(p);
    placed.add(p.id);
    // Replies stay chronological under the parent (conversation flow).
    for (final child in childrenOf[p.id] ?? const []) {
      result.add(child);
      placed.add(child.id);
    }
  }
  for (final c in flat) {
    if (!placed.contains(c.id)) result.add(c);
  }
  return result;
}

// ─────────────────────────────────────────────
class _CommentRow extends StatefulWidget {
  final _Comment comment;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const _CommentRow({
    required this.comment,
    required this.onReply,
    this.onDelete,
    this.onReport,
  });

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _localLikes;
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _liked = widget.comment.isLikedByMe;
    _localLikes = widget.comment.likes;
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

  Future<void> _toggleLike() async {
    if (widget.comment.id.isEmpty) return;
    HapticFeedback.lightImpact();
    final willLike = !_liked;
    setState(() {
      _liked = willLike;
      _localLikes =
          willLike ? _localLikes + 1 : (_localLikes - 1).clamp(0, 999999);
    });
    _likeCtrl.forward(from: 0);

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (willLike) {
        await supabase.from('comment_likes').insert({
          'comment_id': widget.comment.id,
          'user_id': uid,
        });
        await supabase
            .from('comments')
            .update({'likes': _localLikes}).eq('id', widget.comment.id);
      } else {
        await supabase
            .from('comment_likes')
            .delete()
            .eq('comment_id', widget.comment.id)
            .eq('user_id', uid);
        await supabase
            .from('comments')
            .update({'likes': _localLikes}).eq('id', widget.comment.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !willLike;
          _localLikes =
              willLike ? (_localLikes - 1).clamp(0, 999999) : _localLikes + 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final likes = _localLikes;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 20,
        left: widget.comment.isReply ? 32 : 0,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: (widget.onReport == null && widget.onDelete == null)
            ? null
            : () {
                HapticFeedback.mediumImpact();
                showCommentActions(
                  context,
                  onReport: widget.onReport,
                  onDelete: widget.onDelete,
                );
              },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileAvatar(
              userId: widget.comment.userId,
              displayName: widget.comment.username,
              avatarUrl: widget.comment.avatarUrl,
              radius: 15,
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
                      Pressable(
                        onTap: _toggleLike,
                        pressedScale: 0.88,
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
                      Pressable(
                        onTap: widget.onReply,
                        pressedScale: 0.9,
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
