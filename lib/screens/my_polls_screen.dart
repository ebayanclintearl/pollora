import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../models/poll.dart';
import '../providers/auth_provider.dart' as auth_prov;
import '../providers/polls_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/pressable.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/switch_account_sheet.dart';
import 'follow_list_screen.dart';
import 'settings_screen.dart';

class MyPollsScreen extends ConsumerStatefulWidget {
  const MyPollsScreen({super.key});

  @override
  ConsumerState<MyPollsScreen> createState() => _MyPollsScreenState();
}

class _MyPollsScreenState extends ConsumerState<MyPollsScreen> {
  int _selectedTab = 0;

  void _showSwitchAccountSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const SwitchAccountSheet(),
    );
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.wait([
      ref.read(pollsProvider.notifier).refresh(),
      ref.read(currentProfileProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final myPolls = ref.watch(myPollsProvider);
    final favorites = ref.watch(favoritePollsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.accentPrimary,
        backgroundColor: AppColors.surfaceCard,
        strokeWidth: 2.5,
        child: CustomScrollView(
          slivers: [
            // ── Screen header ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  top + 8,
                  AppSpacing.screenH,
                  2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profile', style: AppTypography.screenTitle),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: AppIconSizes.touchTarget,
                        height: AppIconSizes.touchTarget,
                        child: Icon(
                          Icons.settings_rounded,
                          color: AppColors.textSecondary,
                          size: AppIconSizes.control,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Profile info — flat, no card ──────────
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _showSwitchAccountSheet,
                behavior: HitTestBehavior.opaque,
                child: const _ProfileSection(),
              ),
            ),

            // ── Stats — flat, no card ─────────────────
            const SliverToBoxAdapter(child: _StatsRow()),

            // ── Thin separator ────────────────────────
            SliverToBoxAdapter(
              child: Container(
                height: 0.5,
                margin: const EdgeInsets.only(top: 20),
                color: const Color(0xFF242424),
              ),
            ),

            // ── Underline tabs ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _UnderlineTabs(
                  selected: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
              ),
            ),

            // ── Tab content ───────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_selectedTab == 0)
                    _PollListSection(polls: myPolls)
                  else
                    _FavoritesSection(polls: favorites),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _joinedLabel(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Joined ${months[dt.month - 1]} ${dt.year}';
}

// ──────────────────────────────────────────────
// Profile Section — flat layout, no card
// ──────────────────────────────────────────────
class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authUser = ref.watch(auth_prov.currentUserProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with edit badge
          Stack(
            children: [
              ProfileAvatar(
                userId: authUser?.id ?? user?.id ?? '',
                displayName: user?.name,
                avatarUrl: user?.avatarUrl,
                radius: 36,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPrimary,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Name block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? '', style: AppTypography.profileName),
                const SizedBox(height: 3),
                Text(user?.handle ?? '', style: AppTypography.bodySmall),
                if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(user.bio!, style: AppTypography.bodyMedium),
                ],
                const SizedBox(height: 8),
                if (user?.createdAt != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _joinedLabel(user!.createdAt!),
                        style: AppTypography.statLabel,
                      ),
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

// ──────────────────────────────────────────────
// Stats Row — flat, animated count-up
// ──────────────────────────────────────────────
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myPolls = ref.watch(myPollsProvider);
    // Derive live counts from pollsProvider so they update instantly on
    // delete or vote — no extra DB call needed.
    final pollsCount = myPolls.length;
    final votesReceived = myPolls.fold(0, (sum, p) => sum + p.totalVotes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(value: pollsCount, label: 'Polls'),
            _VerticalDivider(),
            _StatCell(value: votesReceived, label: 'Votes'),
            _VerticalDivider(),
            _StatCell(
              value: user?.followersCount ?? 0,
              label: 'Followers',
              onTap: () => Navigator.of(context).pushNamed(
                '/follow-list',
                arguments: FollowListMode.followers,
              ),
            ),
            _VerticalDivider(),
            _StatCell(
              value: user?.followingCount ?? 0,
              label: 'Following',
              onTap: () => Navigator.of(context).pushNamed(
                '/follow-list',
                arguments: FollowListMode.following,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 0.5,
        height: 28,
        color: const Color(0xFF2E2E2E),
      ),
    );
  }
}

String _formatStat(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  }
  return n.toString();
}

class _StatCell extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _StatCell({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (_, animated, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatStat(animated.round()),
                style: AppTypography.statValue,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTypography.statLabel),
                  if (onTap != null) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 11,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Underline Tabs — iOS-native style
// ──────────────────────────────────────────────
class _UnderlineTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _UnderlineTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UnderlineTab(
          label: 'Your Polls',
          icon: null,
          index: 0,
          selected: selected,
          onTap: onChanged,
        ),
        _UnderlineTab(
          label: 'Favorites',
          icon: Icons.favorite_rounded,
          index: 1,
          selected: selected,
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _UnderlineTab({
    required this.label,
    required this.icon,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    return Expanded(
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        pressedScale: 0.95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 13,
                      color: isActive
                          ? AppColors.navActive
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      height: 1,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 2,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Poll List Section — from provider
// ──────────────────────────────────────────────
class _PollListSection extends StatelessWidget {
  final List<Poll> polls;
  const _PollListSection({required this.polls});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            const Icon(Icons.bar_chart_rounded,
                color: AppColors.textTertiary, size: 40),
            const SizedBox(height: 14),
            Text(
              'No polls yet',
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Polls you create will appear here',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        color: AppColors.surfaceCard,
        child: Column(
          children: polls.asMap().entries.map((e) {
            return _PollListRow(
              poll: e.value,
              showDivider: e.key < polls.length - 1,
              onTap: () => Navigator.of(context)
                  .pushNamed('/poll-detail', arguments: e.value.id),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Favorites Section — from provider
// ──────────────────────────────────────────────
class _FavoritesSection extends StatelessWidget {
  final List<Poll> polls;
  const _FavoritesSection({required this.polls});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            const Icon(Icons.favorite_border_rounded,
                color: AppColors.textTertiary, size: 40),
            const SizedBox(height: 14),
            Text(
              'No favorites yet',
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Heart a poll in the feed to save it here',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        color: AppColors.surfaceCard,
        child: Column(
          children: polls.asMap().entries.map((e) {
            return _PollListRow(
              poll: e.value,
              showDivider: e.key < polls.length - 1,
              onTap: () => Navigator.of(context)
                  .pushNamed('/poll-detail', arguments: e.value.id),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Poll list row — tappable, flat, minimal chrome
// ──────────────────────────────────────────────
class _PollListRow extends StatelessWidget {
  final Poll poll;
  final bool showDivider;
  final VoidCallback onTap;

  const _PollListRow({
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH, vertical: 14),
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
                        '${_formatStat(poll.totalVotes)} votes · ${poll.timeAgo}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      poll.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
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
