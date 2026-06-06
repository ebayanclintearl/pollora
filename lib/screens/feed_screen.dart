import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/comments_sheet.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

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
  final List<_PollOption> options;
  final int voteCount;
  final int commentCount;

  const _PollData({
    required this.avatarColor,
    required this.avatarLabel,
    required this.userName,
    required this.timestamp,
    required this.question,
    required this.options,
    required this.voteCount,
    this.commentCount = 0,
  });
}

// ─────────────────────────────────────────────
// Sample data
// ─────────────────────────────────────────────
const _polls = [
  _PollData(
    avatarColor: Color(0xFF1A6B3C), avatarLabel: 'RZ', userName: 'RoronoaZoro',
    commentCount: 12, timestamp: '2h ago', question: 'Who is the strongest?',
    options: [
      _PollOption(label: 'Ban', percentage: 19, isLeading: false),
      _PollOption(label: 'Escanor', percentage: 67, isLeading: true),
      _PollOption(label: 'Zoro', percentage: 14, isLeading: false),
    ],
    voteCount: 1246,
  ),
  _PollData(
    avatarColor: Color(0xFF8B4513), avatarLabel: 'MD', userName: 'MonkeyDLuffy',
    commentCount: 7, timestamp: '6h ago', question: 'Which Devil Fruit is the most useful?',
    options: [
      _PollOption(label: 'Gomu Gomu no Mi', percentage: 42, isLeading: true),
      _PollOption(label: 'Mera Mera no Mi', percentage: 33, isLeading: false),
      _PollOption(label: 'Hie Hie no Mi', percentage: 25, isLeading: false),
    ],
    voteCount: 987,
  ),
  _PollData(
    avatarColor: Color(0xFF2B4D8B), avatarLabel: 'IC', userName: 'Ichigo',
    commentCount: 23, timestamp: '1d ago', question: 'Which is your favorite Anime?',
    options: [
      _PollOption(label: 'One Piece', percentage: 51, isLeading: true),
      _PollOption(label: 'Bleach', percentage: 28, isLeading: false),
      _PollOption(label: 'Naruto', percentage: 21, isLeading: false),
    ],
    voteCount: 2541,
  ),
  _PollData(
    avatarColor: Color(0xFF6B2B8B), avatarLabel: 'GK', userName: 'GokuSon',
    commentCount: 41, timestamp: '2d ago', question: 'Best anime battle of all time?',
    options: [
      _PollOption(label: 'Goku vs Vegeta', percentage: 48, isLeading: true),
      _PollOption(label: 'Naruto vs Sasuke', percentage: 35, isLeading: false),
      _PollOption(label: 'Ichigo vs Aizen', percentage: 17, isLeading: false),
    ],
    voteCount: 5103,
  ),
  _PollData(
    avatarColor: Color(0xFF1A3A6B), avatarLabel: 'KL', userName: 'KilluaZ',
    commentCount: 8, timestamp: '3d ago', question: 'Who has the best power system in anime?',
    options: [
      _PollOption(label: 'Nen – Hunter x Hunter', percentage: 34, isLeading: true),
      _PollOption(label: 'Devil Fruits – One Piece', percentage: 22, isLeading: false),
      _PollOption(label: 'Chakra – Naruto', percentage: 19, isLeading: false),
      _PollOption(label: 'Quirks – My Hero Academia', percentage: 13, isLeading: false),
      _PollOption(label: 'Alchemy – Fullmetal', percentage: 8, isLeading: false),
      _PollOption(label: 'Cursed Energy – Jujutsu', percentage: 4, isLeading: false),
    ],
    voteCount: 8742,
  ),
  _PollData(
    avatarColor: Color(0xFF6B1A1A), avatarLabel: 'ER', userName: 'ErenYeager',
    commentCount: 5, timestamp: '4d ago', question: 'Which anime had the best ending?',
    options: [
      _PollOption(label: 'Fullmetal Alchemist: Brotherhood', percentage: 41, isLeading: true),
      _PollOption(label: 'Steins;Gate', percentage: 28, isLeading: false),
      _PollOption(label: 'Attack on Titan', percentage: 18, isLeading: false),
      _PollOption(label: 'Demon Slayer', percentage: 13, isLeading: false),
    ],
    voteCount: 3891,
  ),
];

String _formatVotes(int n) {
  if (n >= 1000) {
    final t = n ~/ 1000;
    final r = (n % 1000).toString().padLeft(3, '0');
    return '$t,$r';
  }
  return n.toString();
}

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate initial load — shows skeleton cards
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

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
    setState(() { _searchActive = false; _searchQuery = ''; });
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _isLoading = false);
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.accentPrimary,
        backgroundColor: AppColors.surfaceCard,
        strokeWidth: 2.5,
        displacement: 60,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.screenH, top + AppSpacing.screenTop, AppSpacing.screenH, AppSpacing.screenTop),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _searchActive
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Row(
                    children: [
                      const Expanded(
                        child: Text('Polls', style: AppTypography.screenTitle),
                      ),
                      GestureDetector(
                        onTap: _activateSearch,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 44, height: 44,
                          child: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 24),
                        ),
                      ),
                    ],
                  ),
                  secondChild: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            fillColor: AppColors.surfaceElevated,
                            hintText: 'Search polls…',
                            hintStyle: AppTypography.titleSmall.copyWith(color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          cursorColor: AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _cancelSearch,
                        child: Text('Cancel', style: AppTypography.titleSmall.copyWith(color: AppColors.textAccent)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content: skeleton / empty / polls ──
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => i.isOdd
                        ? Container(height: 1, color: AppColors.borderSubtle)
                        : const _SkeletonCard(),
                    childCount: 7,
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(query: _searchQuery),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => i.isOdd
                        ? Container(height: 1, color: AppColors.borderSubtle)
                        : _PollCard(poll: filtered[i ~/ 2]),
                    childCount: filtered.length * 2 - 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Poll Card
// ─────────────────────────────────────────────
class _PollCard extends StatefulWidget {
  final _PollData poll;
  const _PollCard({super.key, required this.poll});
  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> with SingleTickerProviderStateMixin {
  bool _favorited = false;
  bool _optionsExpanded = false;
  int? _votedIndex;
  static const int _previewCount = 3;

  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
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

  void _onVote(int index) {
    HapticFeedback.selectionClick();
    setState(() => _votedIndex = index);
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    setState(() => _favorited = !_favorited);
    _heartCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.poll;
    final displayCount = _votedIndex != null ? p.voteCount + 1 : p.voteCount;

    return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.cardPad,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                CircleAvatar(
                  radius: 16, backgroundColor: p.avatarColor,
                  child: Text(p.avatarLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(p.userName, style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Container(width: 2, height: 2, decoration: const BoxDecoration(color: AppColors.textTertiary, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(p.timestamp, style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Question ──
            Text(p.question, style: AppTypography.cardTitle),

            const SizedBox(height: 16),

            // ── Options ──
            Builder(builder: (_) {
              final hasMore = p.options.length > _previewCount;
              final visible = _optionsExpanded || !hasMore ? p.options : p.options.sublist(0, _previewCount);
              final hidden = hasMore ? p.options.length - _previewCount : 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...visible.asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: e.key < visible.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => _onVote(e.key),
                      child: _PollOptionBar(
                        option: e.value,
                        isVoted: _votedIndex == e.key,
                        hasVoted: _votedIndex != null,
                      ),
                    ),
                  )),
                  if (hasMore && !_optionsExpanded) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _optionsExpanded = true),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.accentPrimaryMuted, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text('+$hidden more option${hidden > 1 ? 's' : ''}',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textAccent)),
                      ),
                    ),
                  ],
                ],
              );
            }),

            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 12),

            // ── Footer ──
            Row(
              children: [
                const Icon(Icons.how_to_vote_outlined, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('${_formatVotes(displayCount)} votes',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w400)),
                const Spacer(),
                // Comments
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: 0.5),
                      builder: (_) => CommentsSheet(pollQuestion: widget.poll.question, commentCount: widget.poll.commentCount),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text('${widget.poll.commentCount}', style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                ),
                // Favorite with bounce
                GestureDetector(
                  onTap: _toggleFavorite,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ScaleTransition(
                      scale: _heartScale,
                      child: Icon(
                        _favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: _favorited ? const Color(0xFFFF5C7A) : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                // Share
                GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.ios_share_rounded, size: 18, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

// ─────────────────────────────────────────────
// Poll Option Bar
// ─────────────────────────────────────────────
class _PollOptionBar extends StatelessWidget {
  final _PollOption option;
  final bool isVoted;
  final bool hasVoted;

  const _PollOptionBar({super.key, required this.option, required this.isVoted, required this.hasVoted});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * (option.percentage / 100);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pollBar)),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pollBar),
                  border: isVoted
                      ? Border.all(color: AppColors.accentPrimary, width: 1.5)
                      : Border.all(color: AppColors.borderDefault, width: 1),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOut,
                        width: hasVoted ? fillWidth : 0,
                        height: 52,
                        color: isVoted ? AppColors.pollBarLeading : AppColors.pollBarOther,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: isVoted ? FontWeight.w700 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasVoted) ...[
                            if (isVoted)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                              ),
                            Text('${option.percentage}%',
                                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}

// ─────────────────────────────────────────────
// Skeleton Card
// ─────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 850), vsync: this)..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final c = AppColors.surfaceElevated.withValues(alpha: _anim.value);
        final r = (v) => BoxDecoration(color: c, borderRadius: BorderRadius.circular(v));
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.cardPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Container(width: 120, height: 9, decoration: r(4.0)),
              ]),
              const SizedBox(height: 8),
              Container(width: double.infinity, height: 12, decoration: r(6.0)),
              const SizedBox(height: 8),
              Container(width: 170, height: 12, decoration: r(6.0)),
              const SizedBox(height: 16),
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(height: 52, decoration: r(8.0)),
              )),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 12),
              Container(width: 90, height: 10, decoration: r(5.0)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle),
            ),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle),
            ),
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.bar_chart_rounded,
              size: 48, color: AppColors.textTertiary,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          isSearch ? 'No polls found' : 'Nothing here yet',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          isSearch ? '"$query" didn\'t match any polls' : 'Pull down to refresh',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
