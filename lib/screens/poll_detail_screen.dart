import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../core/supabase_client.dart';
import '../widgets/profile_avatar.dart';
import '../models/poll.dart';
import '../providers/follow_provider.dart';
import '../providers/moderation_provider.dart';
import '../providers/polls_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/comment_actions_sheet.dart';
import '../widgets/poll_image.dart';
import '../widgets/pressable.dart';
import '../widgets/report_sheet.dart';

// ─────────────────────────────────────────────
// Poll Detail — unified poll + comments page
// ─────────────────────────────────────────────
class PollDetailScreen extends ConsumerStatefulWidget {
  final String pollId;
  const PollDetailScreen({super.key, required this.pollId});

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen>
    with SingleTickerProviderStateMixin {
  // ── Comment state ──────────────────────────
  final List<_Comment> _comments = [];
  bool _commentsLoading = true;
  bool _submitting = false;
  String? _replyingToUsername;
  String? _replyingToId;
  int? _replyingToIndex;
  bool _hasText = false;

  // ── UI controllers ─────────────────────────
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  // ── Favorite animation ─────────────────────
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));

    _inputCtrl.addListener(() {
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });

    _loadComments();
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    _inputCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Comment loading ────────────────────────

  Future<void> _loadComments() async {
    try {
      final data = await supabase
          .from('comments')
          .select('id, text, created_at, likes, reply_to_id, '
              'author:profiles!author_id(id, name, handle, avatar_url)')
          .eq('poll_id', widget.pollId)
          .order('created_at', ascending: true);

      if (!mounted) return;
      final uid = supabase.auth.currentUser?.id;

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
          handle: author['handle'] as String? ?? '',
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
        _commentsLoading = false;
        _comments
          ..clear()
          ..addAll(_threadComments(visible));
      });
    } catch (_) {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    if (text.length > 1000) return;
    _submitting = true;
    HapticFeedback.lightImpact();

    final uid = supabase.auth.currentUser?.id;
    final me = ref.read(currentUserProvider);
    final body =
        _replyingToUsername != null ? '@$_replyingToUsername $text' : text;

    final replyToId =
        (_replyingToId?.isNotEmpty == true) ? _replyingToId : null;
    final optimistic = _Comment(
      id: '',
      userId: uid ?? '',
      username: me?.name ?? '',
      handle: me?.handle ?? '',
      avatarUrl: me?.avatarUrl,
      replyToId: replyToId,
      text: body,
      timestamp: 'now',
      likes: 0,
      isOwn: true,
      isReply: _replyingToUsername != null,
    );

    // Replies slot in after their parent thread; new top-level comments go
    // to the top (newest-first).
    final insertAt = _replyingToIndex != null ? _replyingToIndex! + 1 : 0;
    setState(() {
      _comments.insert(insertAt, optimistic);
      _inputCtrl.clear();
      _replyingToUsername = null;
      _replyingToId = null;
      _replyingToIndex = null;
    });
    _focusNode.unfocus();

    if (uid == null) return;
    try {
      await supabase.from('comments').insert({
        'poll_id': widget.pollId,
        'author_id': uid,
        'text': body,
        'reply_to_id': replyToId,
      });
      // Keep the poll card's comment count in sync.
      ref.read(pollsProvider.notifier).bumpCommentCount(widget.pollId, 1);
      // Reload so the optimistic entry is replaced with the real DB row.
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

    // Insert directly under the parent so the newest reply sits at the top
    // of the thread (matches the newest-first top-level ordering).
    int parentIdx = index;
    for (int i = 0; i < _comments.length; i++) {
      if (_comments[i].id == effectiveParentId) {
        parentIdx = i;
        break;
      }
    }

    setState(() {
      _replyingToUsername = username;
      _replyingToId = effectiveParentId;
      _replyingToIndex = parentIdx;
    });
    _inputCtrl.clear();
    Future.delayed(
        const Duration(milliseconds: 50), () => _focusNode.requestFocus());
  }

  void _cancelReply() {
    setState(() {
      _replyingToUsername = null;
      _replyingToId = null;
      _replyingToIndex = null;
    });
    _focusNode.unfocus();
  }

  Future<void> _deleteComment(int index) async {
    final c = _comments[index];
    setState(() => _comments.removeAt(index));
    if (c.id.isNotEmpty) {
      try {
        await supabase.from('comments').delete().eq('id', c.id);
        ref.read(pollsProvider.notifier).bumpCommentCount(widget.pollId, -1);
      } catch (_) {}
    }
  }

  void _reportComment(String commentId) {
    if (commentId.isEmpty) return;
    showReportSheet(context,
        targetType: 'comment', targetLabel: 'comment', targetId: commentId);
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final poll = ref
        .watch(pollsProvider)
        .valueOrNull
        ?.where((p) => p.id == widget.pollId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Scrollable area ─────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pollsProvider);
                await ref.read(pollsProvider.future);
                await _loadComments();
              },
              color: AppColors.accentPrimary,
              backgroundColor: AppColors.surfaceCard,
              strokeWidth: 2.5,
              displacement: top + 56,
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenH, top + 12, AppSpacing.screenH, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.textSecondary, size: 20),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Poll', style: AppTypography.screenTitle),
                        ],
                      ),
                    ),
                  ),

                  if (poll == null)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                          child: Text('Poll not found',
                              style: AppTypography.bodyMedium)),
                    )
                  else ...[
                    // ── Poll card ───────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _PollCard(
                          poll: poll,
                          heartCtrl: _heartCtrl,
                          heartScale: _heartScale,
                          onFavorite: () {
                            ref
                                .read(pollsProvider.notifier)
                                .toggleFavorite(poll.id);
                            _heartCtrl.forward(from: 0);
                          },
                          onVote: (optId) => ref
                              .read(pollsProvider.notifier)
                              .vote(poll.id, optId),
                          onDelete: () => _confirmDelete(context, ref, poll.id),
                        ),
                      ),
                    ),

                    // ── Comments header ──────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'Comments',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '${_commentsLoading ? poll.commentCount : _comments.length}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Comment list / loading ───────
                    if (_commentsLoading)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => const _CommentSkeleton(),
                            childCount: 4,
                          ),
                        ),
                      )
                    else if (_comments.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  size: 36, color: AppColors.textTertiary),
                              const SizedBox(height: 10),
                              Text(
                                'No comments yet\nBe the first to comment!',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _CommentRow(
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
                            childCount: _comments.length,
                          ),
                        ),
                      ),

                    // Bottom spacing above input
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              ),
            ),
          ),

          // ── Sticky comment input ────────────
          _CommentInput(
            controller: _inputCtrl,
            focusNode: _focusNode,
            hasText: _hasText,
            replyingTo: _replyingToUsername,
            onCancelReply: _cancelReply,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String pollId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeletePollSheet(
        onConfirm: () async {
          Navigator.pop(context); // close detail screen
          try {
            await ref.read(pollsProvider.notifier).deletePoll(pollId);
          } catch (_) {}
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Poll card — author + cover + question + options + actions
// ─────────────────────────────────────────────
class _PollCard extends ConsumerWidget {
  final Poll poll;
  final AnimationController heartCtrl;
  final Animation<double> heartScale;
  final VoidCallback onFavorite;
  final void Function(String optionId) onVote;
  final VoidCallback onDelete;

  const _PollCard({
    required this.poll,
    required this.heartCtrl,
    required this.heartScale,
    required this.onFavorite,
    required this.onVote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = poll.author.isCurrentUser
        ? false
        : ref.watch(isFollowingProvider(poll.author.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Author row ──────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed('/user-profile', arguments: poll.author),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  ProfileAvatar(
                    userId: poll.author.id,
                    displayName: poll.author.name,
                    avatarUrl: poll.author.avatarUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(poll.author.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          )),
                      Text(poll.author.handle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            height: 1.2,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(poll.timeAgo, style: AppTypography.statLabel),
            const SizedBox(width: 8),
            // Inline follow for others
            if (!poll.author.isCurrentUser)
              _FollowChip(userId: poll.author.id, isFollowing: isFollowing),
            // ⋯ menu
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showMenu(context, ref),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Icon(Icons.more_horiz_rounded,
                      size: 18, color: AppColors.textTertiary),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Question ─────────────────────────
        Text(
          poll.question,
          style: AppTypography.cardTitle.copyWith(fontSize: 20, height: 1.35),
        ),

        // ── Cover image ─────────────────────
        if (poll.coverImagePath != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: PollImage(path: poll.coverImagePath),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── Options ──────────────────────────
        ...poll.options.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(
                  bottom: e.key < poll.options.length - 1 ? 10 : 0),
              child: Pressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onVote(e.value.id);
                },
                pressedScale: 0.975,
                child: _OptionBar(
                  option: e.value,
                  totalVotes: poll.totalVotes,
                  isVoted: poll.votedOptionId == e.value.id,
                  hasVoted: poll.isVoted,
                ),
              ),
            )),

        if (poll.isVoted) ...[
          const SizedBox(height: 8),
          const Row(children: [
            Icon(Icons.touch_app_outlined,
                size: 12, color: AppColors.textTertiary),
            SizedBox(width: 4),
            Text('Tap any option to change your vote',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textTertiary, height: 1)),
          ]),
        ],

        const SizedBox(height: 16),
        Container(height: 0.5, color: const Color(0xFF2A2A2A)),
        const SizedBox(height: 4),

        // ── Footer: votes · heart · share ────
        Row(children: [
          const Icon(Icons.how_to_vote_outlined,
              size: AppIconSizes.inline, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Text('${_fmt(poll.totalVotes)} votes',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              )),
          if (poll.isVoted) ...[
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                  color: AppColors.textTertiary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('You voted',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textAccent,
                  fontWeight: FontWeight.w500,
                )),
          ],
          const Spacer(),

          // Favorite
          GestureDetector(
            onTap: onFavorite,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: ScaleTransition(
                  scale: heartScale,
                  child: Icon(
                    poll.isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: AppIconSizes.control,
                    color: poll.isFavorited
                        ? const Color(0xFFFF5C7A)
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ]),

        Container(height: 0.5, color: const Color(0xFF2A2A2A)),
      ],
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
            if (poll.author.isCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textDestructive),
                title: const Text('Delete poll',
                    style: TextStyle(color: AppColors.textDestructive)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined,
                    color: AppColors.textDestructive),
                title: const Text('Report poll',
                    style: TextStyle(color: AppColors.textDestructive)),
                onTap: () {
                  Navigator.pop(context);
                  showReportSheet(context,
                      targetType: 'poll',
                      targetLabel: 'poll',
                      targetId: poll.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded,
                    color: AppColors.textDestructive),
                title: Text('Block ${poll.author.name}',
                    style: const TextStyle(color: AppColors.textDestructive)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(blockProvider.notifier).block(poll.author.id);
                  AppToast.show(context,
                      'Blocked — you won\'t see their content anymore');
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Follow chip (inline in author row)
// ─────────────────────────────────────────────
class _FollowChip extends ConsumerWidget {
  final String userId;
  final bool isFollowing;
  const _FollowChip({required this.userId, required this.isFollowing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(followProvider.notifier).toggle(userId);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : AppColors.accentPrimary,
          border: Border.all(
            color:
                isFollowing ? AppColors.borderSubtle : AppColors.accentPrimary,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isFollowing ? AppColors.textSecondary : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Option bar
// ─────────────────────────────────────────────
class _OptionBar extends StatelessWidget {
  final PollOption option;
  final int totalVotes;
  final bool isVoted;
  final bool hasVoted;

  const _OptionBar({
    required this.option,
    required this.totalVotes,
    required this.isVoted,
    required this.hasVoted,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = option.imagePath != null;
    final barH = hasImage ? 72.0 : 52.0;

    return LayoutBuilder(builder: (_, constraints) {
      final fillW = constraints.maxWidth * option.percentage(totalVotes);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: barH,
        decoration: BoxDecoration(
          color: AppColors.pollBarTrack,
          borderRadius: BorderRadius.circular(AppRadius.pollBar),
        ),
        foregroundDecoration: isVoted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pollBar),
                border: Border.all(color: AppColors.accentPrimary, width: 1.5),
              )
            : null,
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: hasVoted ? fillW : 0,
                height: barH,
                color:
                    isVoted ? AppColors.pollBarLeading : AppColors.pollBarOther,
              ),
            ),
            if (hasImage)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: PollImage(path: option.imagePath),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                left: hasImage ? barH + 12.0 : 14.0,
                right: 14.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(option.text,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight:
                              isVoted ? FontWeight.w700 : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  if (hasVoted) ...[
                    if (isVoted)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_circle_rounded,
                            size: AppIconSizes.inline, color: Colors.white),
                      ),
                    Text('${option.percentageInt(totalVotes)}%',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0,
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Comment row
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
        duration: const Duration(milliseconds: 350), vsync: this);
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
      } else {
        await supabase
            .from('comment_likes')
            .delete()
            .eq('comment_id', widget.comment.id)
            .eq('user_id', uid);
      }
      await supabase
          .from('comments')
          .update({'likes': _localLikes}).eq('id', widget.comment.id);
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
        left: widget.comment.isReply ? 36 : 0,
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
              radius: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + timestamp
                  Row(children: [
                    Text(widget.comment.username,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1,
                        )),
                    const SizedBox(width: 6),
                    Text('· ${widget.comment.timestamp}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          height: 1,
                        )),
                  ]),
                  const SizedBox(height: 5),
                  // Text
                  Text(widget.comment.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      )),
                  const SizedBox(height: 8),
                  // Like / Reply / Delete
                  Row(children: [
                    Pressable(
                      onTap: _toggleLike,
                      pressedScale: 0.88,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _likeScale,
                              child: Icon(
                                _liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: _liked
                                    ? const Color(0xFFFF5C7A)
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (likes > 0) ...[
                              const SizedBox(width: 4),
                              Text('$likes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _liked
                                        ? const Color(0xFFFF5C7A)
                                        : AppColors.textSecondary,
                                    height: 1,
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Pressable(
                      onTap: widget.onReply,
                      pressedScale: 0.9,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Text('Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1,
                            )),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Comment skeleton loader
// ─────────────────────────────────────────────
class _CommentSkeleton extends StatelessWidget {
  const _CommentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 11,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 11,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
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
// Sticky comment input
// ─────────────────────────────────────────────
class _CommentInput extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final String? replyingTo;
  final VoidCallback onCancelReply;
  final Future<void> Function() onSubmit;

  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final me = ref.watch(currentUserProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply banner
          if (replyingTo != null)
            Container(
              color: AppColors.surfaceElevated,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replying to @$replyingTo',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: onCancelReply,
                    pressedScale: 0.85,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),

          // Input row
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottom > 0 ? bottom : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ProfileAvatar(
                  userId: me?.id ?? '',
                  displayName: me?.name,
                  avatarUrl: me?.avatarUrl,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write a comment…',
                        hintStyle: TextStyle(
                            color: AppColors.textTertiary, fontSize: 14),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: hasText ? onSubmit : null,
                  pressedScale: 0.86,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasText
                          ? AppColors.accentPrimary
                          : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: hasText ? Colors.white : AppColors.textTertiary,
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
  final String id;
  final String userId;
  final String username;
  final String handle;
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
    required this.handle,
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
    // Newest reply first, directly under the parent.
    for (final child in (childrenOf[p.id] ?? const []).reversed) {
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
// Helpers
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// Delete poll confirmation — bottom sheet
// ─────────────────────────────────────────────
class _DeletePollSheet extends StatelessWidget {
  final Future<void> Function() onConfirm;
  const _DeletePollSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.delete_outline_rounded,
              size: 36, color: AppColors.textDestructive),
          const SizedBox(height: 14),
          const Text(
            'Delete poll?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This can\'t be undone. All votes and\ncomments will be removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textDestructive,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
              child: const Text('Delete',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
              child: const Text('Cancel',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = (n % 1000).toString().padLeft(3, '0');
    return '$k,$r';
  }
  return n.toString();
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  return 'now';
}
