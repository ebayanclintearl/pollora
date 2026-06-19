import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../core/avatar_helper.dart';
import '../models/user.dart';
import '../providers/follow_provider.dart';
import '../providers/users_provider.dart';

enum FollowListMode { following, followers }

class FollowListScreen extends ConsumerWidget {
  final FollowListMode mode;
  const FollowListScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final followingIds = ref.watch(followProvider);
    final allUsersList = ref.watch(allUsersProvider);

    final List<AppUser> users;
    if (mode == FollowListMode.following) {
      // Everyone the current user actively follows
      users = allUsersList
          .where((u) => !u.isCurrentUser && followingIds.contains(u.id))
          .toList();
    } else {
      // Everyone who follows the current user (static demo data +
      // anyone the current user followed back who also followsCurrentUser)
      users = allUsersList
          .where((u) => !u.isCurrentUser && u.followsCurrentUser)
          .toList();
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
                  Text(
                    mode == FollowListMode.following
                        ? 'Following'
                        : 'Followers',
                    style: AppTypography.screenTitle,
                  ),
                ],
              ),
            ),
          ),

          // ── Count chip ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${users.length} ${mode == FollowListMode.following ? 'people' : 'followers'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── List ─────────────────────────────
          if (users.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyFollow(mode: mode),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppRadius.card),
                    child: Container(
                      color: AppColors.surfaceCard,
                      child: Column(
                        children: users.asMap().entries.map((e) {
                          return _UserRow(
                            user: e.value,
                            showDivider: e.key < users.length - 1,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/user-profile',
                              arguments: e.value,
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

// ── User row ──────────────────────────────────
class _UserRow extends ConsumerWidget {
  final AppUser user;
  final bool showDivider;
  final VoidCallback onTap;

  const _UserRow({
    required this.user,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(isFollowingProvider(user.id));

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AvatarHelper.colorFor(user.id),
                  child: Text(
                    AvatarHelper.initialFor(displayName: user.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + handle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(user.handle, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Follow / Following button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(followProvider.notifier).toggle(user.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? Colors.transparent
                          : AppColors.accentPrimary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      border: isFollowing
                          ? Border.all(
                              color: const Color(0xFF3A3A3A),
                              width: 1)
                          : null,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFollowing
                            ? AppColors.textPrimary
                            : Colors.white,
                        height: 1,
                      ),
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 62),
            color: const Color(0xFF252525),
          ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────
class _EmptyFollow extends StatelessWidget {
  final FollowListMode mode;
  const _EmptyFollow({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isFollowing = mode == FollowListMode.following;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.people_outline_rounded,
            color: AppColors.textTertiary, size: 40),
        const SizedBox(height: 14),
        Text(
          isFollowing ? 'Not following anyone yet' : 'No followers yet',
          style: AppTypography.titleSmall
              .copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          isFollowing
              ? 'Search for people to follow'
              : 'Share your polls to gain followers',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
