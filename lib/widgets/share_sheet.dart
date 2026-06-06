import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';
import '../models/user.dart';
import '../providers/follow_provider.dart';
import '../providers/polls_provider.dart';
import '../providers/users_provider.dart';

class ShareSheet extends ConsumerStatefulWidget {
  final String pollId;
  const ShareSheet({super.key, required this.pollId});

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  bool _sharedToFeed = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final polls = ref.watch(pollsProvider);
    final me = ref.watch(currentUserProvider);
    final followingIds = ref.watch(followProvider);
    final allUsersList = ref.watch(allUsersProvider);

    // Find the poll
    late final poll = polls.firstWhere(
      (p) => p.id == widget.pollId,
      orElse: () => polls.first,
    );

    final alreadyShared = polls.any((p) =>
        p.id == 'shared_${widget.pollId}_${me.id}');

    final isOwnPoll = poll.author.id == me.id;

    final followingUsers = allUsersList
        .where((u) => followingIds.contains(u.id))
        .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceModal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A4A),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ── Title ────────────────────────────
            const Text(
              'Share Poll',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),

            // ── Poll preview card ─────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                    color: const Color(0xFF2C2C2C), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: poll.author.avatarColor,
                        child: Text(
                          poll.author.avatarLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        poll.author.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        poll.author.handle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    poll.question,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${poll.options.length} options · ${_fmt(poll.totalVotes)} votes',
                    style: AppTypography.statLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Action buttons ────────────────────
            Row(
              children: [
                // Copy link
                Expanded(
                  child: _ShareAction(
                    icon: _copied
                        ? Icons.check_rounded
                        : Icons.link_rounded,
                    label: _copied ? 'Copied!' : 'Copy Link',
                    accent: _copied,
                    disabled: false,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await Clipboard.setData(ClipboardData(
                        text: 'https://pollora.app/poll/${poll.id}',
                      ));
                      setState(() => _copied = true);
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) setState(() => _copied = false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Share to feed
                Expanded(
                  child: _ShareAction(
                    icon: (alreadyShared || _sharedToFeed)
                        ? Icons.check_rounded
                        : Icons.repeat_rounded,
                    label: (alreadyShared || _sharedToFeed)
                        ? 'Shared!'
                        : 'Share to Feed',
                    accent: alreadyShared || _sharedToFeed,
                    disabled: isOwnPoll,
                    onTap: (alreadyShared || _sharedToFeed || isOwnPoll)
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(pollsProvider.notifier)
                                .shareToFeed(poll.id, me);
                            setState(() => _sharedToFeed = true);
                          },
                  ),
                ),
              ],
            ),

            // ── Send to followers ─────────────────
            if (followingUsers.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Send to',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: followingUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) =>
                      _FollowerAvatar(user: followingUsers[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = (n % 1000).toString().padLeft(3, '0');
    return '$k,$r';
  }
  return n.toString();
}

// ── Share action tile ─────────────────────────
class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;
  final bool disabled;
  final VoidCallback? onTap;

  const _ShareAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.textAccent : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
                color: const Color(0xFF2C2C2C), width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Follower avatar ───────────────────────────
class _FollowerAvatar extends StatefulWidget {
  final AppUser user;
  const _FollowerAvatar({required this.user});

  @override
  State<_FollowerAvatar> createState() => _FollowerAvatarState();
}

class _FollowerAvatarState extends State<_FollowerAvatar> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_sent) return;
        HapticFeedback.selectionClick();
        setState(() => _sent = true);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _sent
                  ? AppColors.accentPrimary
                  : widget.user.avatarColor,
            ),
            child: Center(
              child: _sent
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 22)
                  : Text(
                      widget.user.avatarLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            widget.user.name.split(' ').first,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
