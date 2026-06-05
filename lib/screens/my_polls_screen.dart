import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import '../widgets/switch_account_sheet.dart';
import 'settings_screen.dart';

class MyPollsScreen extends StatefulWidget {
  const MyPollsScreen({super.key});

  @override
  State<MyPollsScreen> createState() => _MyPollsScreenState();
}

class _MyPollsScreenState extends State<MyPollsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 20, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile', style: AppTypography.screenTitle),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Profile Header ──
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: _showSwitchAccountSheet,
              behavior: HitTestBehavior.opaque,
              child: const _ProfileHeader(),
            ),
          ),

          // ── Stats Bar ──
          const SliverToBoxAdapter(child: _StatsBar()),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Segmented control
                _SegmentedControl(
                  selected: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: 14),

                // Tab content
                if (_selectedTab == 0)
                  const _PollListCard()
                else
                  const _FavoritesCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Profile Header — flat, no card background
// ──────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8B6914),
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
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
                    const SizedBox(height: 4),
                    const Text('Clint', style: AppTypography.profileName),
                    const SizedBox(height: 2),
                    const Text('@clint', style: AppTypography.bodySmall),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.textTertiary),
                        SizedBox(width: 4),
                        Text(
                          'Joined May 2024',
                          style: AppTypography.statLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Stats Bar — single card, 4 columns
// ──────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const IntrinsicHeight(
          child: Row(
            children: [
              _StatCell(value: 8, label: 'Polls'),
              _StatDivider(),
              _StatCell(value: 1245, label: 'Votes'),
              _StatDivider(),
              _StatCell(value: 124, label: 'Followers'),
              _StatDivider(),
              _StatCell(value: 48, label: 'Following'),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatStat(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) {
    final t = n ~/ 1000;
    final r = (n % 1000).toString().padLeft(3, '0');
    return '$t,$r';
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOut,
        builder: (context, animated, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatStat(animated.round()),
                style: AppTypography.statValue,
              ),
              const SizedBox(height: 4),
              Text(label, style: AppTypography.statLabel),
            ],
          );
        },
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: AppColors.borderDefault,
    );
  }
}

// ──────────────────────────────────────────────
// Segmented Control
// ──────────────────────────────────────────────
class _SegmentedControl extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Segment(
              label: 'Your Polls',
              index: 0,
              selected: selected,
              onTap: onChanged),
          _Segment(
              label: 'Favorites',
              index: 1,
              selected: selected,
              onTap: onChanged),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _Segment({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(index); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (index == 1)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Poll List Card
// ──────────────────────────────────────────────
class _PollListCard extends StatelessWidget {
  const _PollListCard();

  static const List<_PollRow> _polls = [
    _PollRow(
      title: 'Who is the strongest?',
      votes: '3,245',
      leading: 'Escanor',
      timestamp: '2d ago',
    ),
    _PollRow(
      title: 'Which Devil Fruit is most useful?',
      votes: '987',
      leading: 'Gomu Gomu no Mi',
      timestamp: '5d ago',
    ),
    _PollRow(
      title: 'Which is your favorite Anime?',
      votes: '2,541',
      leading: 'One Piece',
      timestamp: '1w ago',
    ),
    _PollRow(
      title: 'Which character deserves more love?',
      votes: '648',
      leading: 'Killua',
      timestamp: '2w ago',
    ),
    _PollRow(
      title: 'Best anime battle of all time?',
      votes: '5,103',
      leading: 'Goku vs Vegeta',
      timestamp: '2w ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: AppColors.surfaceCard,
        child: Column(
          children: _polls.asMap().entries.map((e) {
            return _PollListRow(
              poll: e.value,
              showDivider: e.key < _polls.length - 1,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Favorites Card
// ──────────────────────────────────────────────
class _FavoritesCard extends StatelessWidget {
  const _FavoritesCard();

  static const List<_PollRow> _favorites = [
    _PollRow(
      title: 'Who is the strongest?',
      votes: '1,246',
      leading: 'Escanor',
      timestamp: '2h ago',
    ),
    _PollRow(
      title: 'Which is your favorite Anime?',
      votes: '2,541',
      leading: 'One Piece',
      timestamp: '1d ago',
    ),
    _PollRow(
      title: 'Best anime battle of all time?',
      votes: '5,103',
      leading: 'Goku vs Vegeta',
      timestamp: '2d ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_favorites.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: const Column(
          children: [
            Icon(Icons.favorite_border_rounded,
                color: AppColors.textTertiary, size: 36),
            SizedBox(height: 12),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Heart a poll in the feed to save it here',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: AppColors.surfaceCard,
        child: Column(
          children: _favorites.asMap().entries.map((e) {
            return _PollListRow(
              poll: e.value,
              showDivider: e.key < _favorites.length - 1,
              trailingIcon: Icons.favorite_rounded,
              trailingColor: const Color(0xFFFF5C7A),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Poll row data
// ──────────────────────────────────────────────
class _PollRow {
  final String title;
  final String votes;
  final String leading;
  final String timestamp;

  const _PollRow({
    required this.title,
    required this.votes,
    required this.leading,
    required this.timestamp,
  });
}

// ──────────────────────────────────────────────
// Poll list row
// ──────────────────────────────────────────────
class _PollListRow extends StatelessWidget {
  final _PollRow poll;
  final bool showDivider;
  final IconData trailingIcon;
  final Color trailingColor;

  const _PollListRow({
    super.key,
    required this.poll,
    required this.showDivider,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.trailingColor = AppColors.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Leading dot accent
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: const BoxDecoration(
                  color: AppColors.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.title,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          poll.votes,
                          style: AppTypography.labelMedium.copyWith(color: AppColors.textAccent),
                        ),
                        Text(' votes', style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w400)),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${poll.leading} leading',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Timestamp + trailing icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    poll.timestamp,
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  Icon(trailingIcon, size: 16, color: trailingColor),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 36),
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}

