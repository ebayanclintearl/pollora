import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../core/supabase_client.dart';
import '../models/user.dart';
import '../providers/follow_provider.dart';
import '../widgets/profile_avatar.dart';

enum FollowListMode { following, followers }

class FollowListScreen extends ConsumerStatefulWidget {
  final FollowListMode mode;
  const FollowListScreen({super.key, required this.mode});

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final List<AppUser> users;
      if (widget.mode == FollowListMode.following) {
        final data = await supabase
            .from('follows')
            .select('profile:profiles!following_id(*)')
            .eq('follower_id', uid);
        users = (data as List).map((row) {
          final p = (row['profile'] as Map<String, dynamic>).cast<String, dynamic>();
          return AppUser.fromJson(p);
        }).toList();
      } else {
        final data = await supabase
            .from('follows')
            .select('profile:profiles!follower_id(*)')
            .eq('following_id', uid);
        users = (data as List).map((row) {
          final p = (row['profile'] as Map<String, dynamic>).cast<String, dynamic>();
          return AppUser.fromJson(p);
        }).toList();
      }
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _load();
        },
        color: AppColors.accentPrimary,
        backgroundColor: AppColors.surfaceCard,
        strokeWidth: 2.5,
        child: CustomScrollView(
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
                      widget.mode == FollowListMode.following
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
                        _loading
                            ? '—'
                            : '${_users.length} ${widget.mode == FollowListMode.following ? 'people' : 'followers'}',
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
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.textTertiary),
                    ),
                  ),
                ),
              )
            else if (_users.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyFollow(mode: widget.mode),
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
                          children: _users.asMap().entries.map((e) {
                            return _UserRow(
                              user: e.value,
                              showDivider: e.key < _users.length - 1,
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
                ProfileAvatar(
                  userId: user.id,
                  displayName: user.name,
                  avatarUrl: user.avatarUrl,
                  radius: 22,
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
