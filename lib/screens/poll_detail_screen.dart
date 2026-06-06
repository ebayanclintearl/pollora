import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../models/poll.dart';
import '../providers/polls_provider.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/share_sheet.dart';

class PollDetailScreen extends ConsumerWidget {
  final String pollId;
  const PollDetailScreen({super.key, required this.pollId});

  Poll? _find(List<Poll> polls) {
    for (final p in polls) {
      if (p.id == pollId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final poll = _find(ref.watch(pollsProvider));

    if (poll == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Poll not found', style: AppTypography.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenH, top + 12, AppSpacing.screenH, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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

          // ── Content ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _PollContent(pollId: pollId),
            ),
          ),

          // ── Actions ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
              child: _PollActions(pollId: pollId),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Poll content ──────────────────────────────
class _PollContent extends ConsumerWidget {
  final String pollId;
  const _PollContent({required this.pollId});

  Poll? _find(List<Poll> polls) {
    for (final p in polls) {
      if (p.id == pollId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poll = _find(ref.watch(pollsProvider));
    if (poll == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author row — tapping navigates to their profile
        GestureDetector(
          onTap: () => Navigator.of(context)
              .pushNamed('/user-profile', arguments: poll.author),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: poll.author.avatarColor,
                child: Text(
                  poll.author.avatarLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.author.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      poll.author.handle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(poll.timeAgo, style: AppTypography.statLabel),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Question
        Text(
          poll.question,
          style: AppTypography.cardTitle
              .copyWith(fontSize: 20, height: 1.35),
        ),

        const SizedBox(height: 20),

        // Options
        ...poll.options.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(
                  bottom: e.key < poll.options.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () {
                  if (poll.isVoted) return;
                  HapticFeedback.selectionClick();
                  ref.read(pollsProvider.notifier).vote(pollId, e.value.id);
                },
                child: _DetailOptionBar(
                  option: e.value,
                  totalVotes: poll.totalVotes,
                  isVoted: poll.votedOptionId == e.value.id,
                  hasVoted: poll.isVoted,
                ),
              ),
            )),

        const SizedBox(height: 18),

        // Vote summary
        Row(
          children: [
            const Icon(Icons.how_to_vote_outlined,
                size: 15, color: AppColors.textTertiary),
            const SizedBox(width: 5),
            Text(
              '${_fmt(poll.totalVotes)} votes',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (poll.isVoted) ...[
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                    color: AppColors.textTertiary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'You voted',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 18),
        Container(height: 0.5, color: const Color(0xFF2A2A2A)),
      ],
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

// ── Option bar ────────────────────────────────
class _DetailOptionBar extends StatelessWidget {
  final PollOption option;
  final int totalVotes;
  final bool isVoted;
  final bool hasVoted;

  const _DetailOptionBar({
    required this.option,
    required this.totalVotes,
    required this.isVoted,
    required this.hasVoted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final fillWidth = constraints.maxWidth * option.percentage(totalVotes);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.pollBarTrack,
          borderRadius: BorderRadius.circular(AppRadius.pollBar),
        ),
        foregroundDecoration: isVoted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pollBar),
                border:
                    Border.all(color: AppColors.accentPrimary, width: 1.5),
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
                width: hasVoted ? fillWidth : 0,
                height: 52,
                color: isVoted
                    ? AppColors.pollBarLeading
                    : AppColors.pollBarOther,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.text,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight:
                            isVoted ? FontWeight.w700 : FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasVoted) ...[
                    if (isVoted)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_circle_rounded,
                            size: AppIconSizes.inline,
                            color: Colors.white),
                      ),
                    Text(
                      '${option.percentageInt(totalVotes)}%',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
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

// ── Actions bar ───────────────────────────────
class _PollActions extends ConsumerStatefulWidget {
  final String pollId;
  const _PollActions({required this.pollId});

  @override
  ConsumerState<_PollActions> createState() => _PollActionsState();
}

class _PollActionsState extends ConsumerState<_PollActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Poll? _find(List<Poll> polls) {
    for (final p in polls) {
      if (p.id == widget.pollId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final poll = _find(ref.watch(pollsProvider));
    if (poll == null) return const SizedBox.shrink();

    return Row(
      children: [
        // Comments
        _ActionBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${poll.commentCount}',
          onTap: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: 0.5),
              builder: (_) => CommentsSheet(
                pollQuestion: poll.question,
                commentCount: poll.commentCount,
              ),
            );
          },
        ),

        const SizedBox(width: 4),

        // Favorite
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(pollsProvider.notifier).toggleFavorite(poll.id);
            _heartCtrl.forward(from: 0);
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: ScaleTransition(
                scale: _heartScale,
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

        const SizedBox(width: 4),

        // Share
        _ActionBtn(
          icon: Icons.ios_share_rounded,
          label: '${poll.shareCount}',
          onTap: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: 0.6),
              builder: (_) => ShareSheet(pollId: poll.id),
            );
          },
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: AppIconSizes.control, color: AppColors.textTertiary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
