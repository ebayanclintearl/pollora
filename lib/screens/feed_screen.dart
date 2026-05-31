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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
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
  final List<_PollOption> options;
  final String voteCount;

  const _PollCard({
    required this.avatarColor,
    required this.avatarLabel,
    required this.userName,
    required this.timestamp,
    required this.question,
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
          child: Stack(
            children: [
              // Track
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.pollBarTrack,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: option.percentage / 100,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: option.isLeading
                        ? AppColors.pollBarLeading
                        : AppColors.pollBarOther,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // Label inside bar
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
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
              ),
            ],
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
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
