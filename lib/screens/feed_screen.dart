import 'package:flutter/material.dart';
import '../app_colors.dart';

// ─────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────
class _PollOption {
  final String label;
  final int percentage;
  final bool isLeading;
  const _PollOption({required this.label, required this.percentage, required this.isLeading});
}

class _PollData {
  final Color avatarColor;
  final String avatarLabel;
  final String userName;
  final String timestamp;
  final String question;
  final String? coverAsset;
  final List<_PollOption> options;
  final String voteCount;

  const _PollData({
    required this.avatarColor,
    required this.avatarLabel,
    required this.userName,
    required this.timestamp,
    required this.question,
    this.coverAsset,
    required this.options,
    required this.voteCount,
  });
}

// ─────────────────────────────────────────────
// Sample data
// ─────────────────────────────────────────────
const _polls = [
  _PollData(
    avatarColor: Color(0xFF1A6B3C),
    avatarLabel: 'RZ',
    userName: 'RoronoaZoro',
    timestamp: '2h ago',
    question: 'Who is the strongest?',
    coverAsset: 'assets/images/poll_cover_sample.png',
    options: [
      _PollOption(label: 'Ban', percentage: 19, isLeading: false),
      _PollOption(label: 'Escanor', percentage: 67, isLeading: true),
      _PollOption(label: 'Zoro', percentage: 14, isLeading: false),
    ],
    voteCount: '1,246 votes',
  ),
  _PollData(
    avatarColor: Color(0xFF8B4513),
    avatarLabel: 'MD',
    userName: 'MonkeyDLuffy',
    timestamp: '6h ago',
    question: 'Which Devil Fruit is the most useful?',
    options: [
      _PollOption(label: 'Gomu Gomu no Mi', percentage: 42, isLeading: true),
      _PollOption(label: 'Mera Mera no Mi', percentage: 33, isLeading: false),
      _PollOption(label: 'Hie Hie no Mi', percentage: 25, isLeading: false),
    ],
    voteCount: '987 votes',
  ),
  _PollData(
    avatarColor: Color(0xFF2B4D8B),
    avatarLabel: 'IC',
    userName: 'Ichigo',
    timestamp: '1d ago',
    question: 'Which is your favorite Anime?',
    options: [
      _PollOption(label: 'One Piece', percentage: 51, isLeading: true),
      _PollOption(label: 'Bleach', percentage: 28, isLeading: false),
      _PollOption(label: 'Naruto', percentage: 21, isLeading: false),
    ],
    voteCount: '2,541 votes',
  ),
  _PollData(
    avatarColor: Color(0xFF6B2B8B),
    avatarLabel: 'GK',
    userName: 'GokuSon',
    timestamp: '2d ago',
    question: 'Best anime battle of all time?',
    options: [
      _PollOption(label: 'Goku vs Vegeta', percentage: 48, isLeading: true),
      _PollOption(label: 'Naruto vs Sasuke', percentage: 35, isLeading: false),
      _PollOption(label: 'Ichigo vs Aizen', percentage: 17, isLeading: false),
    ],
    voteCount: '5,103 votes',
  ),
];


// ─────────────────────────────────────────────
// Feed Screen
// ─────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searchActive = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _activateSearch() {
    setState(() => _searchActive = true);
    Future.delayed(const Duration(milliseconds: 50), () => _searchFocus.requestFocus());
  }

  void _cancelSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchActive = false;
      _searchQuery = '';
    });
  }

  List<_PollData> get _filtered {
    if (_searchQuery.isEmpty) return _polls;
    return _polls.where((p) =>
      p.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.userName.toLowerCase().contains(_searchQuery.toLowerCase()),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, top + 16, 16, 12),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _searchActive
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                // Default header
                firstChild: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Polls',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    Row(
                      children: [
                        // Search icon
                        GestureDetector(
                          onTap: _activateSearch,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFF8B6914),
                          child: Text(
                            'C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Search header
                secondChild: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search polls...',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: AppColors.textTertiary,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          cursorColor: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _cancelSearch,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Poll list ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded,
                              color: AppColors.textTertiary, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No results for "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        if (i.isOdd) return const SizedBox(height: 12);
                        return _PollCard(poll: filtered[i ~/ 2]);
                      },
                      childCount: filtered.length * 2 - 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Poll Card (stateful — owns favorite toggle)
// ─────────────────────────────────────────────
class _PollCard extends StatefulWidget {
  final _PollData poll;
  const _PollCard({super.key, required this.poll});

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  bool _favorited = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.poll;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: p.avatarColor,
                  child: Text(
                    p.avatarLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.userName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        p.timestamp,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Question
            Text(
              p.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),

            // Cover image
            if (p.coverAsset != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(p.coverAsset!, fit: BoxFit.cover),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Options
            ...p.options.asMap().entries.map((e) => Padding(
                  padding: EdgeInsets.only(bottom: e.key < p.options.length - 1 ? 8 : 0),
                  child: _PollOptionBar(option: e.value),
                )),

            const SizedBox(height: 12),

            // Footer: vote count + actions
            Row(
              children: [
                Text(
                  p.voteCount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textAccent,
                  ),
                ),
                const Spacer(),
                // Favorite
                GestureDetector(
                  onTap: () => setState(() => _favorited = !_favorited),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: _favorited ? const Color(0xFFFF5C7A) : AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Share
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.ios_share_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Poll Option Bar
// ─────────────────────────────────────────────
class _PollOptionBar extends StatelessWidget {
  final _PollOption option;
  const _PollOptionBar({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * (option.percentage / 100);
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 40,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: AppColors.pollBarTrack),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: fillWidth,
                          height: 40,
                          child: Container(
                            color: option.isLeading
                                ? AppColors.pollBarLeading
                                : AppColors.pollBarOther,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 0,
                        bottom: 0,
                        right: 8,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            option.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '${option.percentage}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
