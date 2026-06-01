import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/switch_account_sheet.dart';
import 'settings_screen.dart';

class MyPollsScreen extends StatefulWidget {
  const MyPollsScreen({super.key});

  @override
  State<MyPollsScreen> createState() => _MyPollsScreenState();
}

class _MyPollsScreenState extends State<MyPollsScreen> {
  int _selectedTab = 0; // 0 = Your Polls, 1 = Favorites

  void _showSwitchAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
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
              padding: EdgeInsets.fromLTRB(16, top + 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'My Polls',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Card
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showSwitchAccountSheet,
                  child: const _ProfileCard(),
                ),
                const SizedBox(height: 12),

                // Stats Row
                const _StatsRow(),
                const SizedBox(height: 20),

                // Segmented control
                _SegmentedControl(
                  selected: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: 12),

                // Tab content
                if (_selectedTab == 0) ...[
                  _PollListCard(),
                ] else ...[
                  _FavoritesCard(),
                ],
              ]),
            ),
          ),
        ],
      ),
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
          _Segment(label: 'Your Polls', index: 0, selected: selected, onTap: onChanged),
          _Segment(label: 'Favorites', index: 1, selected: selected, onTap: onChanged),
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
        onTap: () => onTap(index),
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
                    size: 13,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
// Favorites Card
// ──────────────────────────────────────────────
class _FavoritesCard extends StatelessWidget {
  _FavoritesCard();

  final List<_PollRow> _favorites = [
    _PollRow(
      title: 'Who is the strongest?',
      votes: '1,246',
      leading: 'Escanor leading',
      timestamp: '2h ago',
    ),
    _PollRow(
      title: 'Which is your favorite Anime?',
      votes: '2,541',
      leading: 'One Piece leading',
      timestamp: '1d ago',
    ),
    _PollRow(
      title: 'Best anime battle of all time?',
      votes: '5,103',
      leading: 'Goku vs Vegeta leading',
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
// Profile Card
// ──────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.surfaceCard),
        child: Stack(
          children: [
            // Gradient overlay — full-height, right half of card
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.4, 1.0],
                    colors: [Colors.transparent, Color(0x662A2566)],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with edit badge
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF8B6914),
                        child: Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.accentPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 12,
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
                        const Text(
                          'Clint',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '@clint',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Joined May 2024',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                height: 1.0,
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
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Stats Row
// ──────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.bar_chart_rounded,
            label: 'Polls Created',
            value: '8',
            delta: '+2 this week ↑',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.people_outline_rounded,
            label: 'Total Votes',
            value: '1,245',
            delta: '+312 this week ↑',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String delta;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconBadge,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textAccent,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSuccess,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Poll List Card
// ──────────────────────────────────────────────
class _PollListCard extends StatelessWidget {
  _PollListCard();

  final List<_PollRow> _polls = [
    _PollRow(
      title: 'Who is the strongest?',
      votes: '3,245',
      leading: 'Escanor leading',
      timestamp: '2d ago',
    ),
    _PollRow(
      title: 'Which Devil Fruit is most useful?',
      votes: '987',
      leading: 'Gomo Gomu no Mi leading',
      timestamp: '5d ago',
    ),
    _PollRow(
      title: 'Which is your favorite Anime?',
      votes: '2,541',
      leading: 'One Piece leading',
      timestamp: '1w ago',
    ),
    _PollRow(
      title: 'Which character deserves more love?',
      votes: '648',
      leading: 'Killua leading',
      timestamp: '2w ago',
    ),
    _PollRow(
      title: 'Best anime battle of all time?',
      votes: '5,103',
      leading: 'Goku vs 3ron leading',
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
            final i = e.key;
            final poll = e.value;
            final isLast = i == _polls.length - 1;
            return _PollListRow(poll: poll, showDivider: !isLast);
          }).toList(),
        ),
      ),
    );
  }
}

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
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Vote badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimaryMuted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${poll.votes} votes',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAccent,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${poll.leading}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.0,
                            ),
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
              // Right block
              Row(
                children: [
                  Text(
                    poll.timestamp,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    trailingIcon,
                    size: 16,
                    color: trailingColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 16),
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Create New Poll Button
// ──────────────────────────────────────────────
class _CreateNewPollButton extends StatelessWidget {
  const _CreateNewPollButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_rounded, size: 16, color: AppColors.textAccent),
            SizedBox(width: 6),
            Text(
              'Create New Poll',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textAccent,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
