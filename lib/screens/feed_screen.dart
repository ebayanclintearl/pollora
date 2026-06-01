import 'package:flutter/material.dart';
import '../app_colors.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, top + 16, 16, 8),
              child: Row(
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PollCard(
                  avatarColor: const Color(0xFF1A6B3C),
                  avatarLabel: 'RZ',
                  userName: 'RoronoaZoro',
                  timestamp: '2h ago',
                  question: 'Who is the strongest?',
                  coverAsset: 'assets/images/poll_cover_sample.png',
                  options: const [
                    _PollOption(label: 'Ban', percentage: 19, isLeading: false),
                    _PollOption(label: 'Escanor', percentage: 67, isLeading: true),
                    _PollOption(label: 'Zoro', percentage: 14, isLeading: false),
                  ],
                  voteCount: '1,246 votes',
                ),
                const SizedBox(height: 12),
                _PollCard(
                  avatarColor: const Color(0xFF8B4513),
                  avatarLabel: 'MD',
                  userName: 'MonkeyDLuffy',
                  timestamp: '6h ago',
                  question: 'Which Devil Fruit is the most useful?',
                  options: const [
                    _PollOption(label: 'Gomu Gomu no Mi', percentage: 42, isLeading: true),
                    _PollOption(label: 'Mera Mera no Mi', percentage: 33, isLeading: false),
                    _PollOption(label: 'Hie Hie no Mi', percentage: 25, isLeading: false),
                  ],
                  voteCount: '987 votes',
                ),
                const SizedBox(height: 12),
                _PollCard(
                  avatarColor: const Color(0xFF2B4D8B),
                  avatarLabel: 'IC',
                  userName: 'Ichigo',
                  timestamp: '1d ago',
                  question: 'Which is your favorite Anime?',
                  options: const [
                    _PollOption(label: 'One Piece', percentage: 51, isLeading: true),
                    _PollOption(label: 'Bleach', percentage: 28, isLeading: false),
                    _PollOption(label: 'Naruto', percentage: 21, isLeading: false),
                  ],
                  voteCount: '2,541 votes',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollOption {
  final String label;
  final int percentage;
  final bool isLeading;

  const _PollOption({
    required this.label,
    required this.percentage,
    required this.isLeading,
  });
}

class _PollCard extends StatelessWidget {
  final Color avatarColor;
  final String avatarLabel;
  final String userName;
  final String timestamp;
  final String question;
  final String? coverAsset;
  final List<_PollOption> options;
  final String voteCount;

  const _PollCard({
    required this.avatarColor,
    required this.avatarLabel,
    required this.userName,
    required this.timestamp,
    required this.question,
    this.coverAsset,
    required this.options,
    required this.voteCount,
  });

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: avatarColor,
                  child: Text(
                    avatarLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Question
            Text(
              question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            // Cover image — below question, above options
            if (coverAsset != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    coverAsset!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Options
            ...options.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              return Padding(
                padding: EdgeInsets.only(bottom: i < options.length - 1 ? 8 : 0),
                child: _PollOptionBar(option: opt),
              );
            }),
            const SizedBox(height: 8),
            // Vote count
            Text(
              voteCount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
                      // Track — full width, flat (ClipRRect handles rounding)
                      Container(color: AppColors.pollBarTrack),
                      // Fill — exact pixel width, flat
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
                      // Label — left-aligned inside bar
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
        // Percentage — outside the bar
        SizedBox(
          width: 40,
          child: Text(
            '${option.percentage}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
