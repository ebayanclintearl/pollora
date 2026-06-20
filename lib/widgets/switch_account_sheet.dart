import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';
import '../core/avatar_helper.dart';
import '../widgets/profile_avatar.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart' as users_prov;
import '../screens/auth_sheet.dart';
import '../services/auth_service.dart';
import '../widgets/app_toast.dart';

class SwitchAccountSheet extends ConsumerWidget {
  const SwitchAccountSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final user = ref.watch(currentUserProvider);
    final appUser = ref.watch(users_prov.currentUserProvider);

    final displayName = AvatarHelper.nameFor(
      displayName: user?.userMetadata?['display_name'] as String?,
      email: user?.email,
    );
    final handle = AvatarHelper.handleFor(
      handle: user?.userMetadata?['handle'] as String?,
      email: user?.email,
    );
    final avatarUrl = appUser?.avatarUrl;

    Future<void> doSignOut() async {
      Navigator.of(context).pop();
      try {
        await AuthService.signOut();
      } catch (_) {
        if (context.mounted) {
          AppToast.show(context, 'Sign out failed', isError: true);
        }
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceModal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────
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

            // ── Header ───────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Signed in as',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Current account row (selected, non-tappable) ──
            Container(
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.70),
                  width: 1.5,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  // Avatar
                  ProfileAvatar(
                    userId: user?.id ?? '',
                    displayName: displayName,
                    avatarUrl: avatarUrl,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  // Name + handle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          handle,
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Selected indicator
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentPrimary,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Actions ───────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: const Color(0xFF303030),
                  width: 0.8,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Add another account — opens sign-in without signing out.
                  // Supabase replaces the session on success; cancel leaves
                  // the current account untouched.
                  _ActionRow(
                    icon: Icons.person_add_outlined,
                    title: 'Add another account',
                    isDestructive: false,
                    showDivider: true,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      await showAuthSheet(context, allowCancel: true);
                    },
                  ),
                  // Sign out
                  _ActionRow(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    isDestructive: true,
                    showDivider: false,
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      await doSignOut();
                    },
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
// Action Row
// ─────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final bool showDivider;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.isDestructive,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive
                      ? AppColors.textDestructive
                      : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? AppColors.textDestructive
                          : AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                if (!isDestructive)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 48),
            color: const Color(0xFF303030),
          ),
      ],
    );
  }
}
