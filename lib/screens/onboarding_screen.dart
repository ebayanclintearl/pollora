import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  // Tracks whether bars have already played for the current visit to page 1
  bool _barsPlayed = false;

  // Per-page stagger
  late AnimationController _contentCtrl;
  late Animation<double> _illustrationScale;
  late Animation<double> _illustrationFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;

  // Bar chart on page 1 (results page)
  late AnimationController _barsCtrl;
  late Animation<double> _bar1;
  late Animation<double> _bar2;
  late Animation<double> _bar3;

  @override
  void initState() {
    super.initState();

    // ── Content stagger ────────────────────────
    _contentCtrl = AnimationController(
      duration: const Duration(milliseconds: 680),
      vsync: this,
    );
    _illustrationScale = Tween(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _illustrationFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.18, 0.65, curve: Curves.easeOut),
    ));
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.18, 0.65, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.33, 0.78, curve: Curves.easeOut),
    ));
    _subtitleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.33, 0.78, curve: Curves.easeOut),
      ),
    );

    // ── Bar chart animations (page 1) ─────────
    _barsCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _bar1 = Tween(begin: 0.0, end: 0.64).animate(
      CurvedAnimation(
        parent: _barsCtrl,
        curve: const Interval(0.0, 0.68, curve: Curves.easeOut),
      ),
    );
    _bar2 = Tween(begin: 0.0, end: 0.24).animate(
      CurvedAnimation(
        parent: _barsCtrl,
        curve: const Interval(0.10, 0.76, curve: Curves.easeOut),
      ),
    );
    _bar3 = Tween(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(
        parent: _barsCtrl,
        curve: const Interval(0.22, 0.86, curve: Curves.easeOut),
      ),
    );

    _contentCtrl.forward();

    // Listen to exact scroll position — only fire bars when fully settled at page 1
    _pageCtrl.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!_pageCtrl.hasClients) return;
    final pos = _pageCtrl.page ?? 0;
    // Reset bars when user swipes away from page 1 so they replay on re-visit
    if ((pos - 1.0).abs() > 0.4 && _barsPlayed) {
      _barsPlayed = false;
      _barsCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _contentCtrl.dispose();
    _barsCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _contentCtrl.forward(from: 0);
    // Trigger bar animation directly when landing on page 1 — no scroll-position polling needed
    if (page == 1 && !_barsPlayed) {
      _barsPlayed = true;
      _barsCtrl.forward(from: 0);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.selectionClick();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      HapticFeedback.mediumImpact();
      widget.onComplete();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final top = MediaQuery.of(context).padding.top;
    final isLast = _currentPage == _totalPages - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Skip ──────────────────────────
            SizedBox(
              height: top + 54,
              child: Align(
                alignment: Alignment.bottomRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  child: GestureDetector(
                    onTap: isLast ? null : _skip,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Skip',
                        style: AppTypography.titleSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ─────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: [
                  _OnboardingPage(
                    illustration: const _AskIllustration(),
                    title: 'Ever wonder what\nothers think?',
                    subtitle:
                        'Ask any question, from daily dilemmas to big decisions, and get honest answers fast.',
                    illustrationScale: _illustrationScale,
                    illustrationFade: _illustrationFade,
                    titleSlide: _titleSlide,
                    titleFade: _titleFade,
                    subtitleSlide: _subtitleSlide,
                    subtitleFade: _subtitleFade,
                  ),
                  _OnboardingPage(
                    illustration: _ResultsIllustration(
                      bar1: _bar1,
                      bar2: _bar2,
                      bar3: _bar3,
                    ),
                    title: 'See what the\ncrowd says',
                    subtitle:
                        'Watch real votes roll in live. No guessing, no bias. Just what people actually think.',
                    illustrationScale: _illustrationScale,
                    illustrationFade: _illustrationFade,
                    titleSlide: _titleSlide,
                    titleFade: _titleFade,
                    subtitleSlide: _subtitleSlide,
                    subtitleFade: _subtitleFade,
                  ),
                  _OnboardingPage(
                    illustration: const _DecisionIllustration(),
                    title: 'Make better\ndecisions',
                    subtitle:
                        'Turn collective opinions into clarity. Whether it\'s a small choice or a big move, the crowd has the answer.',
                    illustrationScale: _illustrationScale,
                    illustrationFade: _illustrationFade,
                    titleSlide: _titleSlide,
                    titleFade: _titleFade,
                    subtitleSlide: _subtitleSlide,
                    subtitleFade: _subtitleFade,
                  ),
                ],
              ),
            ),

            // ── Bottom controls ───────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 36),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.accentPrimary
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Text(
                          isLast ? 'Get Started' : 'Continue',
                          key: ValueKey(isLast),
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

// ─────────────────────────────────────────────
// Generic page layout
// ─────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;
  final Animation<double> illustrationScale;
  final Animation<double> illustrationFade;
  final Animation<Offset> titleSlide;
  final Animation<double> titleFade;
  final Animation<Offset> subtitleSlide;
  final Animation<double> subtitleFade;

  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.illustrationScale,
    required this.illustrationFade,
    required this.titleSlide,
    required this.titleFade,
    required this.subtitleSlide,
    required this.subtitleFade,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(
            flex: 55,
            child: Center(
              child: FadeTransition(
                opacity: illustrationFade,
                child: ScaleTransition(
                  scale: illustrationScale,
                  child: illustration,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: titleFade,
                  child: SlideTransition(
                    position: titleSlide,
                    child: Text(title, style: AppTypography.displayOnboarding),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: subtitleFade,
                  child: SlideTransition(
                    position: subtitleSlide,
                    child: Text(subtitle, style: AppTypography.bodyLarge),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Page 1 — Ask illustration
// Vote icon in glowing rings, three option bubbles orbiting
// ─────────────────────────────────────────────
class _AskIllustration extends StatelessWidget {
  const _AskIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 252,
      height: 252,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          _Ring(
            size: 236,
            color: AppColors.accentPrimary.withValues(alpha: 0.07),
            strokeWidth: 1.5,
          ),
          // Inner ring
          _Ring(
            size: 172,
            color: AppColors.accentPrimary.withValues(alpha: 0.13),
            strokeWidth: 1.5,
          ),

          // Option bubble — top left
          const Positioned(
            top: 22,
            left: 18,
            child: _OptionBubble(
              label: 'A',
              color: Color(0xFF5B4FE8),
            ),
          ),
          // Option bubble — top right
          const Positioned(
            top: 22,
            right: 18,
            child: _OptionBubble(
              label: 'B',
              color: Color(0xFF7B6FFF),
            ),
          ),
          // Option bubble — bottom center
          const Positioned(
            bottom: 22,
            child: _OptionBubble(
              label: 'C',
              color: Color(0xFF9D94FF),
            ),
          ),

          // Center — vote icon with purple glow
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentPrimary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withValues(alpha: 0.50),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.how_to_vote_rounded,
              color: Colors.white,
              size: AppIconSizes.illustration,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const _Ring({
    required this.size,
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
      ),
    );
  }
}

class _OptionBubble extends StatelessWidget {
  final String label;
  final Color color;

  const _OptionBubble({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.38), width: 1.2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Page 2 — Results illustration
// Standalone animated bar chart with live counter
// ─────────────────────────────────────────────
class _ResultsIllustration extends StatelessWidget {
  final Animation<double> bar1;
  final Animation<double> bar2;
  final Animation<double> bar3;

  const _ResultsIllustration({
    required this.bar1,
    required this.bar2,
    required this.bar3,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([bar1, bar2, bar3]),
      builder: (_, __) {
        final votes = ((bar1.value + bar2.value + bar3.value) * 460).round();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textSuccess,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$votes votes',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bars
            _ChartBar(fill: bar1.value, isLeading: true),
            const SizedBox(height: 8),
            _ChartBar(fill: bar2.value, isLeading: false),
            const SizedBox(height: 8),
            _ChartBar(fill: bar3.value, isLeading: false),
          ],
        );
      },
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double fill;
  final bool isLeading;

  const _ChartBar({required this.fill, required this.isLeading});

  @override
  Widget build(BuildContext context) {
    final pct = (fill * 100).round();
    return LayoutBuilder(
      builder: (_, constraints) {
        final fillWidth = constraints.maxWidth * fill;
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.pollBarTrack,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fill
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillWidth,
                  color: isLeading
                      ? AppColors.pollBarLeading
                      : AppColors.pollBarOther,
                ),
              ),
              // Leading star
              if (isLeading)
                const Positioned(
                  left: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.star_rounded,
                      size: AppIconSizes.inline,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Percentage
              if (pct > 0)
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
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
// Page 3 — Decision illustration
// Person nodes connected to a central checkmark
// ─────────────────────────────────────────────
class _DecisionIllustration extends StatelessWidget {
  const _DecisionIllustration();

  static List<Offset> _nodePositions(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 90.0;
    return List.generate(6, (i) {
      final angle = (i * 60 - 90) * pi / 180;
      return Offset(cx + r * cos(angle), cy + r * sin(angle));
    });
  }

  @override
  Widget build(BuildContext context) {
    const size = Size(252, 252);
    final nodes = _nodePositions(size);

    // Purple family — cohesive single-accent illustrations
    const nodeColors = [
      Color(0xFF5B4FE8),
      Color(0xFF6A5EF0),
      Color(0xFF7B6FFF),
      Color(0xFF8C80FF),
      Color(0xFF9D94FF),
      Color(0xFF6658EB),
    ];

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // Connecting lines
          CustomPaint(
            size: size,
            painter: _NetworkPainter(nodes: nodes),
          ),

          // Person nodes
          ...List.generate(nodes.length, (i) {
            final pos = nodes[i];
            final color = nodeColors[i];
            return Positioned(
              left: pos.dx - 22,
              top: pos.dy - 22,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.38),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: AppIconSizes.control,
                  color: color,
                ),
              ),
            );
          }),

          // Center checkmark
          Positioned(
            left: size.width / 2 - 40,
            top: size.height / 2 - 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.50),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: AppIconSizes.illustration,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final List<Offset> nodes;

  const _NetworkPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceElevated
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    for (final node in nodes) {
      // Line to center (with a gap so it doesn't overlap the center icon)
      final dir = (center - node);
      final len = dir.distance;
      final unit = dir / len;
      final start = node + unit * 24; // leave gap for node circle
      final end = center - unit * 42; // leave gap for center circle
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter old) => old.nodes != nodes;
}
