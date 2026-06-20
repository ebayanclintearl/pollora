import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_toast.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/poll_image.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../core/avatar_helper.dart';
import '../models/poll.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart' as auth_prov;
import '../providers/follow_provider.dart';
import '../providers/polls_provider.dart';
import '../providers/search_provider.dart';

// ─────────────────────────────────────────────
// Feed tab
// ─────────────────────────────────────────────
enum _FeedTab { latest, trending, popular, following }

// ─────────────────────────────────────────────
// Feed Screen
// ─────────────────────────────────────────────
class FeedScreen extends ConsumerStatefulWidget {
  final ValueNotifier<int>? reselectNotifier;
  final ValueNotifier<int>? publishedNotifier;
  const FeedScreen({super.key, this.reselectNotifier, this.publishedNotifier});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _searchActive = false;
  bool _headerVisible = true;
  double _lastScrollOffset = 0;
  _FeedTab _selectedTab = _FeedTab.latest;

  // Minimum scroll delta before reacting — prevents jitter on tiny movements.
  static const double _scrollThreshold = 6.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.reselectNotifier?.addListener(_onReselect);
    widget.publishedNotifier?.addListener(_onPublished);
  }

  @override
  void dispose() {
    widget.reselectNotifier?.removeListener(_onReselect);
    widget.publishedNotifier?.removeListener(_onPublished);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onReselect() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPublished() {
    // Switch to Latest tab so the new poll is guaranteed to be at index 0,
    // then scroll to top.
    setState(() => _selectedTab = _FeedTab.latest);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onScroll() {
    // Always keep header visible while search is open.
    if (_searchActive) return;

    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // Snap back when the user bounces to the very top.
    if (offset <= 0) {
      if (!_headerVisible) setState(() => _headerVisible = true);
      return;
    }

    // Scroll DOWN → hide. Scroll UP → show.
    if (delta > _scrollThreshold && _headerVisible) {
      setState(() => _headerVisible = false);
    } else if (delta < -_scrollThreshold && !_headerVisible) {
      setState(() => _headerVisible = true);
    }

    // Load next page when within 400px of the bottom.
    final sc = _scrollController;
    if (sc.position.extentAfter < 400) {
      ref.read(pollsProvider.notifier).loadMore();
    }
  }

  void _activateSearch() {
    setState(() {
      _searchActive = true;
      _headerVisible = true; // pin header while searching
    });
    Future.delayed(
        const Duration(milliseconds: 50), () => _searchFocus.requestFocus());
  }

  void _cancelSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _searchActive = false);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(pollsProvider.notifier).refresh();
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    // Spacer for the floating header below the notch.
    // SafeArea wraps the scroll view so y=0 is already below the notch;
    // we only need the header's own padding + content + padding.
    const double contentH = 44;
    const double vPad     = 8.0;   // vertical padding above/below header content
    const double spacerH  = vPad + contentH + vPad;
    // Sticky tab bar height
    const double tabBarH  = 44.0;

    final searchQuery    = ref.watch(searchQueryProvider);
    final followedIds    = ref.watch(followProvider);
    final pollsAsync     = ref.watch(pollsProvider);
    final isLoading      = pollsAsync.isLoading;
    final hasError       = pollsAsync.hasError;
    final isLoadingMore  = ref.watch(pollsLoadingMoreProvider);
    final hasMore        = ref.watch(pollsHasMoreProvider);
    final newCount       = ref.watch(newPollsCountProvider);
    final polls = switch (_selectedTab) {
      _FeedTab.latest    => ref.watch(feedPollsProvider),
      _FeedTab.trending  => ref.watch(trendingPollsProvider),
      _FeedTab.popular   => ref.watch(popularPollsProvider),
      _FeedTab.following => ref.watch(followingPollsProvider(followedIds)),
    };
    final suggestionsAsync = ref.watch(searchSuggestionsProvider);
    final suggestions = suggestionsAsync.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable feed — SafeArea keeps viewport below notch ──
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.accentPrimary,
            backgroundColor: AppColors.surfaceCard,
            strokeWidth: 2.5,
            displacement: spacerH + tabBarH + 8,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Reserve space for the floating header (below notch).
                const SliverToBoxAdapter(child: SizedBox(height: spacerH)),

                // ── New-polls banner (above tab bar) ─
                if (newCount > 0 && !_searchActive)
                  SliverToBoxAdapter(
                    child: _NewPollsBanner(
                      count: newCount,
                      onTap: _onRefresh,
                    ),
                  ),

                // ── Sticky tab bar ───────────────
                if (!_searchActive)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _FeedTabDelegate(
                      selected: _selectedTab,
                      onSelect: (tab) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = tab);
                      },
                      height: tabBarH,
                    ),
                  ),

                // ── Content ─────────────────────
                if (isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => i.isOdd
                            ? Container(
                                height: 1, color: AppColors.borderSubtle)
                            : const _SkeletonCard(),
                        childCount: 7,
                      ),
                    ),
                  )
                else if (hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      onRetry: () => ref.invalidate(pollsProvider),
                    ),
                  )
                else if (_searchActive && searchQuery.isNotEmpty)
                  if (suggestionsAsync.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.textTertiary),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildSuggestions(context, suggestions, searchQuery)
                else if (polls.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _selectedTab == _FeedTab.following
                        ? const _FollowingEmptyState()
                        : const _EmptyState(query: ''),
                  )
                else ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => i.isOdd
                          ? Container(
                              height: 1, color: AppColors.borderSubtle)
                          : _FeedItem(pollId: polls[i ~/ 2].id),
                      childCount: polls.length * 2 - 1,
                    ),
                  ),
                  // Pagination footer
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: isLoadingMore
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.textTertiary),
                                ),
                              ),
                            )
                          : hasMore
                              ? const SizedBox.shrink()
                              : const Center(
                                  child: Text(
                                    'You\'re all caught up',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ), // SafeArea

          // ── Floating header ───────────────────
          AnimatedSlide(
            offset: _headerVisible ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _headerVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildHeader(context, top, vPad),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating header widget ─────────────────
  Widget _buildHeader(BuildContext context, double top, double vPad) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        top + vPad,
        AppSpacing.screenH,
        2,
      ),
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
            Semantics(
              label: 'Search polls',
              button: true,
              child: GestureDetector(
                onTap: _activateSearch,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: AppIconSizes.touchTarget,
                  height: AppIconSizes.touchTarget,
                  child: Icon(Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: AppIconSizes.control),
                ),
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
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
                style: AppTypography.titleSmall
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  fillColor: AppColors.surfaceElevated,
                  hintText: 'Search polls and people…',
                  hintStyle: AppTypography.titleSmall
                      .copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textTertiary,
                      size: AppIconSizes.control),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
                cursorColor: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _cancelSearch,
              child: Text(
                'Cancel',
                style: AppTypography.titleSmall
                    .copyWith(color: AppColors.textAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search suggestions sliver ──────────────
  Widget _buildSuggestions(
      BuildContext context, List<SearchItem> items, String query) {
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(query: query),
      );
    }

    final users =
        items.whereType<UserSearchItem>().toList();
    final polls =
        items.whereType<PollSearchItem>().toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (users.isNotEmpty) ...[
            const _SuggestionHeader('People'),
            ...users.map((item) => _UserSuggestionRow(
                  user: item.user,
                  onTap: () => Navigator.of(context)
                      .pushNamed('/user-profile', arguments: item.user),
                )),
            const SizedBox(height: 8),
          ],
          if (polls.isNotEmpty) ...[
            const _SuggestionHeader('Polls'),
            ...polls.map((item) => _PollSuggestionRow(
                  poll: item.poll,
                  onTap: () => Navigator.of(context)
                      .pushNamed('/poll-detail', arguments: item.poll.id),
                )),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// New-polls banner
// ─────────────────────────────────────────────
class _NewPollsBanner extends StatelessWidget {
  final int count;
  final Future<void> Function() onTap;
  const _NewPollsBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentPrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward_rounded,
                size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              '$count new ${count == 1 ? 'poll' : 'polls'} — tap to refresh',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Feed Item
// ─────────────────────────────────────────────
class _FeedItem extends StatelessWidget {
  final String pollId;
  const _FeedItem({required this.pollId});

  @override
  Widget build(BuildContext context) => _PollCard(pollId: pollId);
}

// ─────────────────────────────────────────────
// Poll Card
// ─────────────────────────────────────────────
class _PollCard extends ConsumerStatefulWidget {
  final String pollId;
  const _PollCard({required this.pollId});

  @override
  ConsumerState<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<_PollCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  bool _expanded = false;

  // Show first 2 options + a partial 3rd peeking through the fade.
  static const _collapsedCount = 2;
  static const _barGap = 8.0;
  // How much of the peeking bar is visible before the gradient cuts it.
  static const _peekH = 48.0;

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

  Widget _optionTile(Poll p, int index, PollOption opt, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : _barGap),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(pollsProvider.notifier).vote(widget.pollId, opt.id);
        },
        child: _PollOptionBar(
          option: opt,
          totalVotes: p.totalVotes,
          isVoted: p.votedOptionId == opt.id,
          hasVoted: p.isVoted,
        ),
      ),
    );
  }

  Widget _buildOptions(Poll p) {
    final options = p.options;
    final needsFade = !_expanded && options.length > _collapsedCount;

    if (!needsFade) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.asMap().entries
            .map((e) => _optionTile(p, e.key, e.value,
                last: e.key == options.length - 1))
            .toList(),
      );
    }

    // Collapsed: full visible bars + one partially-visible peeking bar.
    final fullBars = options.take(_collapsedCount).toList();
    final peekBar  = options[_collapsedCount];
    final hidden   = options.length - _collapsedCount;

    void expand() {
      HapticFeedback.selectionClick();
      setState(() => _expanded = true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full bars — each handles its own vote tap.
        ...fullBars.asMap().entries.map(
          (e) => _optionTile(p, e.key, e.value),
        ),

        // Peek section — tapping anywhere here expands.
        // The peek bar + the spacing + divider are all inside so the
        // gradient can cover them seamlessly (no exposed dark gap below).
        GestureDetector(
          onTap: expand,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Column defines the total height of this section.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Peek bar — clipped, non-interactive.
                  ClipRect(
                    child: SizedBox(
                      height: _peekH,
                      child: IgnorePointer(
                        child: OverflowBox(
                          maxHeight: double.infinity,
                          alignment: Alignment.topCenter,
                          child: _optionTile(
                              p, _collapsedCount, peekBar, last: true),
                        ),
                      ),
                    ),
                  ),
                  // Spacing + divider pulled inside so gradient covers them.
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 16),
                ],
              ),
              // Gradient: transparent at top → black at bottom
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // "Show N more" label — centred in the lower half
              Positioned(
                left: 0, right: 0, bottom: 14,
                child: IgnorePointer(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show $hidden more',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Returns the ID to use for avatar colour — real auth ID for the current
  /// user so it matches the profile tab, mock ID for everyone else.
  String _avatarId(AppUser author) {
    if (author.isCurrentUser) {
      return ref.watch(auth_prov.currentUserProvider)?.id ?? author.id;
    }
    return author.id;
  }

  @override
  Widget build(BuildContext context) {
    final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
    Poll? poll;
    for (final p in polls) {
      if (p.id == widget.pollId) {
        poll = p;
        break;
      }
    }
    if (poll == null) return const SizedBox.shrink();
    final p = poll; // non-null alias — safe to use inside closures

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.of(context)
          .pushNamed('/poll-detail', arguments: p.id),
      child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.cardPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author row — tappable ────────────
          GestureDetector(
            onTap: () => Navigator.of(context)
                .pushNamed('/user-profile', arguments: p.author),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AvatarHelper.colorFor(_avatarId(p.author)),
                  child: Text(
                    AvatarHelper.initialFor(displayName: p.author.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        p.author.name,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                            color: AppColors.textTertiary,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.timeAgo,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (p.author.isCurrentUser)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showPollMenu(context, ref, p.id),
                    child: const SizedBox(
                      width: 32, height: 32,
                      child: Center(
                        child: Icon(Icons.more_horiz_rounded,
                            size: 18, color: AppColors.textTertiary),
                      ),
                    ),
                  )
                else ...[
                  _InlineFollowButton(userId: p.author.id),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showOthersPollMenu(context, ref, p.id),
                    child: const SizedBox(
                      width: 32, height: 32,
                      child: Center(
                        child: Icon(Icons.more_horiz_rounded,
                            size: 18, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Question — tappable to open detail ─
          GestureDetector(
            onTap: () => Navigator.of(context)
                .pushNamed('/poll-detail', arguments: p.id),
            behavior: HitTestBehavior.opaque,
            child: Text(p.question, style: AppTypography.cardTitle),
          ),

          // ── Cover image (optional) ────────────
          if (p.coverImagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: PollImage(path: p.coverImagePath),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Options ──────────────────────────
          // GestureDetector with opaque absorbs taps so the outer card
          // tap-to-navigate doesn't fire when the user taps options or "show more".
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // absorb — inner widgets handle their own taps
            child: _buildOptions(p),
          ),

          // Divider — omitted when collapsed (gradient covers that area instead).
          if (_expanded || p.options.length <= _collapsedCount) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 12),
          ],

          // ── Footer ───────────────────────────
          Row(
            children: [
              const Icon(Icons.how_to_vote_outlined,
                  size: AppIconSizes.inline,
                  color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${_fmtVotes(p.totalVotes)} votes',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Comments
              Semantics(
                label: 'Comments, ${p.commentCount}',
                button: true,
                child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.black.withValues(alpha: 0.5),
                    builder: (_) => CommentsSheet(
                      pollId: p.id,
                      pollQuestion: p.question,
                      commentCount: p.commentCount,
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppIconSizes.touchTarget,
                    minHeight: AppIconSizes.touchTarget,
                  ),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: AppIconSizes.control,
                          color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${p.commentCount}',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
              ), // Semantics: Comments
              // Favorite with bounce
              Semantics(
                label: p.isFavorited ? 'Unlike poll' : 'Like poll',
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(pollsProvider.notifier)
                        .toggleFavorite(widget.pollId);
                    _heartCtrl.forward(from: 0);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: AppIconSizes.touchTarget,
                    height: AppIconSizes.touchTarget,
                    child: Center(
                      child: ScaleTransition(
                        scale: _heartScale,
                        child: Icon(
                          p.isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: AppIconSizes.control,
                          color: p.isFavorited
                              ? const Color(0xFFFF5C7A)
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Share
              Semantics(
                label: 'Share poll',
                button: true,
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final result = await Share.share(
                      '${p.question}\n\nhttps://pollora.app/poll/${widget.pollId}',
                      subject: p.question,
                    );
                    if (result.status == ShareResultStatus.success &&
                        context.mounted) {
                      ref.read(pollsProvider.notifier).share(widget.pollId);
                      AppToast.show(context, 'Poll shared',
                          icon: Icons.ios_share_rounded);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: AppIconSizes.touchTarget,
                    height: AppIconSizes.touchTarget,
                    child: Center(
                      child: Icon(Icons.ios_share_rounded,
                          size: AppIconSizes.control,
                          color: p.hasShared
                              ? AppColors.accentPrimary
                              : AppColors.textTertiary),
                    ),
                  ),
                ),
              ), // Semantics: Share
            ],
          ),
        ],
      ),
    ),
    );
  }
}

String _fmtVotes(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000)   return '${(n / 1000).toStringAsFixed(0)}K';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

// ── ⋯ menu for other people's polls ───────────
void _showOthersPollMenu(BuildContext context, WidgetRef ref, String pollId) {
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
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded,
                color: AppColors.textSecondary),
            title: const Text('Copy link'),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(
                  text: 'https://pollora.app/poll/$pollId'));
              AppToast.show(context, 'Link copied');
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined,
                color: AppColors.textDestructive),
            title: const Text('Report poll',
                style: TextStyle(color: AppColors.textDestructive)),
            onTap: () {
              Navigator.pop(context);
              AppToast.show(context, 'Poll reported — thanks for the feedback');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _showPollMenu(BuildContext context, WidgetRef ref, String pollId) {
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
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textDestructive),
            title: const Text('Delete poll',
                style: TextStyle(color: AppColors.textDestructive)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeletePoll(context, ref, pollId);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _confirmDeletePoll(BuildContext context, WidgetRef ref, String pollId) {
  final bottom = MediaQuery.of(context).padding.bottom;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                try {
                  await ref.read(pollsProvider.notifier).deletePoll(pollId);
                } catch (_) {
                  if (context.mounted) {
                    AppToast.show(context, 'Failed to delete poll',
                        isError: true);
                  }
                }
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
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
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
    ),
  );
}

// ─────────────────────────────────────────────
// Inline follow button (shown in author row for others' polls)
// ─────────────────────────────────────────────
class _InlineFollowButton extends ConsumerWidget {
  final String userId;
  const _InlineFollowButton({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(isFollowingProvider(userId));
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
          color: isFollowing
              ? Colors.transparent
              : AppColors.accentPrimary,
          border: Border.all(
            color: isFollowing
                ? AppColors.borderSubtle
                : AppColors.accentPrimary,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isFollowing
                ? AppColors.textSecondary
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Poll Option Bar — animates fill from 0 on first render
// ─────────────────────────────────────────────
class _PollOptionBar extends StatefulWidget {
  final PollOption option;
  final int totalVotes;
  final bool isVoted;
  final bool hasVoted;

  const _PollOptionBar({
    required this.option,
    required this.totalVotes,
    required this.isVoted,
    required this.hasVoted,
  });

  @override
  State<_PollOptionBar> createState() => _PollOptionBarState();
}

class _PollOptionBarState extends State<_PollOptionBar> {
  bool _animIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animIn = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.option.imagePath != null;
    final barH = hasImage ? 68.0 : 48.0;

    return LayoutBuilder(
      builder: (_, constraints) {
        final fillWidth =
            constraints.maxWidth * widget.option.percentage(widget.totalVotes);
        final showFill = widget.hasVoted && _animIn;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: barH,
          decoration: BoxDecoration(
            color: AppColors.pollBarTrack,
            borderRadius: BorderRadius.circular(AppRadius.pollBar),
          ),
          foregroundDecoration: widget.isVoted
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pollBar),
                  border: Border.all(
                      color: AppColors.accentPrimary, width: 1.5),
                )
              : null,
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fill bar
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  width: showFill ? fillWidth : 0,
                  height: barH,
                  color: widget.isVoted
                      ? AppColors.pollBarLeading
                      : AppColors.pollBarOther,
                ),
              ),
              // Option image (1:1, left-anchored)
              if (hasImage)
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: PollImage(path: widget.option.imagePath),
                  ),
                ),
              // Text + percentage
              Padding(
                padding: EdgeInsets.only(
                  left: hasImage ? barH + 10.0 : 12.0,
                  right: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.option.text,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: widget.isVoted
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.hasVoted) ...[
                      if (widget.isVoted)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: AppIconSizes.inline,
                            color: Colors.white,
                          ),
                        ),
                      Text(
                        '${widget.option.percentageInt(widget.totalVotes)}%',
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
      },
    );
  }
}

// ─────────────────────────────────────────────
// Search suggestion widgets
// ─────────────────────────────────────────────
class _SuggestionHeader extends StatelessWidget {
  final String title;
  const _SuggestionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 8, AppSpacing.screenH, 4),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          letterSpacing: 0.8,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _UserSuggestionRow extends ConsumerWidget {
  final AppUser user;
  final VoidCallback onTap;
  const _UserSuggestionRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(isFollowingProvider(user.id));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AvatarHelper.colorFor(user.id),
              child: Text(
                AvatarHelper.initialFor(displayName: user.name),
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
                    user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(user.handle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(followProvider.notifier).toggle(user.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isFollowing
                      ? Colors.transparent
                      : AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: isFollowing
                      ? Border.all(color: const Color(0xFF3A3A3A))
                      : null,
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFollowing
                        ? AppColors.textPrimary
                        : Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollSuggestionRow extends StatelessWidget {
  final Poll poll;
  final VoidCallback onTap;
  const _PollSuggestionRow({required this.poll, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${poll.author.handle} · ${_fmtVotes(poll.totalVotes)} votes',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
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

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 850), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final c =
            AppColors.surfaceElevated.withValues(alpha: _anim.value);

        BoxDecoration sk(double r) =>
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(r));

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.cardPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 32,
                    height: 32,
                    decoration:
                        BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Container(
                    width: 120, height: 9, decoration: sk(4)),
              ]),
              const SizedBox(height: 8),
              Container(
                  width: double.infinity,
                  height: 12,
                  decoration: sk(6)),
              const SizedBox(height: 8),
              Container(width: 170, height: 12, decoration: sk(6)),
              const SizedBox(height: 16),
              ...List.generate(
                  3,
                  (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(height: 48, decoration: sk(8)),
                      )),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 12),
              Container(width: 90, height: 10, decoration: sk(5)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Feed tab — SliverPersistentHeader delegate
// ─────────────────────────────────────────────
class _FeedTabDelegate extends SliverPersistentHeaderDelegate {
  final _FeedTab selected;
  final ValueChanged<_FeedTab> onSelect;
  final double height;

  const _FeedTabDelegate({
    required this.selected,
    required this.onSelect,
    required this.height,
  });

  static const _tabs = [
    (_FeedTab.latest,    'Latest'),
    (_FeedTab.trending,  'Trending'),
    (_FeedTab.popular,   'Popular'),
    (_FeedTab.following, 'Following'),
  ];

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  bool shouldRebuild(_FeedTabDelegate old) =>
      old.selected != selected;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _tabs.map((entry) {
                  final (tab, label) = entry;
                  final isActive = selected == tab;
                  final color = isActive
                      ? AppColors.textAccent
                      : AppColors.textSecondary;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onSelect(tab),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accentPrimaryMuted
                              : AppColors.surfaceElevated,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isActive
                                ? AppColors.accentPrimaryBorder
                                : AppColors.borderDefault,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: color,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(height: 0.5, color: AppColors.borderDefault),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Following empty state
// ─────────────────────────────────────────────
class _FollowingEmptyState extends StatelessWidget {
  const _FollowingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceCard, shape: BoxShape.circle),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated, shape: BoxShape.circle),
            ),
            const Icon(Icons.people_outline_rounded,
                size: AppIconSizes.empty, color: AppColors.textTertiary),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'No one followed yet',
          style: AppTypography.titleMedium
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Follow users to see their polls here',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textTertiary),
        ),
      ],
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
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceCard, shape: BoxShape.circle),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated, shape: BoxShape.circle),
            ),
            Icon(
              isSearch
                  ? Icons.search_off_rounded
                  : Icons.bar_chart_rounded,
              size: AppIconSizes.empty,
              color: AppColors.textTertiary,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          isSearch ? 'No results found' : 'Nothing here yet',
          style: AppTypography.titleMedium
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          isSearch
              ? '"$query" didn\'t match anything'
              : 'Pull down to refresh',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Error state ───────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_rounded,
            size: 44, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        const Text(
          'Couldn\'t load polls',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Check your connection and try again',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onRetry();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
