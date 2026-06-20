import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../widgets/profile_avatar.dart';
import '../app_typography.dart';
import '../models/poll.dart';
import '../models/user.dart';
import '../providers/follow_provider.dart';
import '../providers/polls_provider.dart';
import '../providers/users_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  final AppUser user;
  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final isFollowing = ref.watch(isFollowingProvider(user.id));
    final userPolls = ref.watch(pollsByUserProvider(user.id));
    // Use full profile for bio + fresh counts; fall back to passed user while loading.
    final fullUser = ref.watch(fullProfileProvider(user.id)).valueOrNull ?? user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Top bar ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenH, top + 8, AppSpacing.screenH, 2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: AppIconSizes.touchTarget,
                      height: AppIconSizes.touchTarget,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary,
                          size: AppIconSizes.control),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(
                    width: AppIconSizes.touchTarget,
                    height: AppIconSizes.touchTarget,
                    child: Icon(Icons.more_horiz_rounded,
                        color: AppColors.textSecondary,
                        size: AppIconSizes.control),
                  ),
                ],
              ),
            ),
          ),

          // ── Profile header ───────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ProfileAvatar(
                        userId: fullUser.id,
                        displayName: fullUser.name,
                        avatarUrl: fullUser.avatarUrl,
                        radius: 40,
                      ),
                      const Spacer(),
                      _FollowButton(
                        isFollowing: isFollowing,
                        followsCurrentUser: fullUser.followsCurrentUser,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(followProvider.notifier).toggle(user.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(fullUser.name, style: AppTypography.profileName),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(fullUser.handle, style: AppTypography.bodySmall),
                      if (fullUser.followsCurrentUser && !isFollowing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text(
                            'Follows you',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (fullUser.bio != null && fullUser.bio!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(fullUser.bio!, style: AppTypography.bodyMedium),
                  ],
                ],
              ),
            ),
          ),

          // ── Stats row ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _StatCell(value: fullUser.pollsCount, label: 'Polls'),
                    _DivLine(),
                    _StatCell(value: fullUser.votesReceived, label: 'Votes'),
                    _DivLine(),
                    _StatCell(value: fullUser.followersCount, label: 'Followers'),
                    _DivLine(),
                    _StatCell(value: fullUser.followingCount, label: 'Following'),
                  ],
                ),
              ),
            ),
          ),

          // ── Separator + polls header ─────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(top: 22),
                  color: const Color(0xFF242424),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Text('Polls', style: AppTypography.sectionTitle),
                ),
              ],
            ),
          ),

          // ── Polls list ───────────────────────
          if (userPolls.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyPolls(
                  name: user.name.split(' ').first),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Container(
                      color: AppColors.surfaceCard,
                      child: Column(
                        children: userPolls.asMap().entries.map((e) {
                          return _UserPollRow(
                            poll: e.value,
                            showDivider: e.key < userPolls.length - 1,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/poll-detail',
                              arguments: e.value.id,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Follow Button ─────────────────────────────
class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool followsCurrentUser;
  final VoidCallback onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.followsCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    late final Border? border;

    if (isFollowing) {
      label = 'Following';
      bg = Colors.transparent;
      fg = AppColors.textPrimary;
      border = Border.all(color: const Color(0xFF3A3A3A), width: 1);
    } else if (followsCurrentUser) {
      label = 'Follow Back';
      bg = AppColors.accentPrimary;
      fg = Colors.white;
      border = null;
    } else {
      label = 'Follow';
      bg = AppColors.accentPrimary;
      fg = Colors.white;
      border = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: border,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: fg,
            height: 1,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ── Stat cell ─────────────────────────────────
String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  }
  return n.toString();
}

class _StatCell extends StatelessWidget {
  final int value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_fmt(value), style: AppTypography.statValue),
          const SizedBox(height: 3),
          Text(label, style: AppTypography.statLabel),
        ],
      ),
    );
  }
}

class _DivLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 0.5,
          height: 28,
          color: const Color(0xFF2E2E2E),
        ),
      );
}

// ── Poll row ──────────────────────────────────
class _UserPollRow extends StatelessWidget {
  final Poll poll;
  final bool showDivider;
  final VoidCallback onTap;

  const _UserPollRow({
    required this.poll,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poll.question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_fmt(poll.totalVotes)} votes · ${poll.timeAgo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 14),
            color: const Color(0xFF252525),
          ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────
class _EmptyPolls extends StatelessWidget {
  final String name;
  const _EmptyPolls({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bar_chart_rounded,
            color: AppColors.textTertiary, size: 40),
        const SizedBox(height: 14),
        Text(
          '$name hasn\'t posted yet',
          style: AppTypography.titleSmall
              .copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Polls they create will appear here',
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}
