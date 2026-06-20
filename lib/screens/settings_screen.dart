import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../core/avatar_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart' as users_prov;
import '../widgets/profile_avatar.dart';
import '../providers/follow_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_toast.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
                  8, AppSpacing.screenH, 2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: AppIconSizes.touchTarget,
                      height: AppIconSizes.touchTarget,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary,
                        size: AppIconSizes.control,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Settings', style: AppTypography.screenTitle),
                    ),
                  ),
                  const SizedBox(width: AppIconSizes.touchTarget),
                ],
              ),
            ),

            // ── Scrollable body ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.x8),
                children: [
                  // ── Profile row ──
                  _ProfileRow(),
                  const SizedBox(height: 20),

                  // ── Support ──
                  const _SectionLabel('Support'),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.star_outline_rounded,
                        label: 'Rate the App',
                        onTap: () {},
                        showDivider: true,
                      ),
                      _SettingsRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Contact Us',
                        onTap: () {},
                        showDivider: true,
                      ),
                      _SettingsRow(
                        icon: Icons.ios_share_rounded,
                        label: 'Share App',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Legal ──
                  const _SectionLabel('Legal'),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.shield_outlined,
                        label: 'Privacy Policy',
                        onTap: () {},
                        showDivider: true,
                      ),
                      _SettingsRow(
                        icon: Icons.article_outlined,
                        label: 'Terms of Service',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Sign Out — standalone destructive button ──
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      try {
                        await AuthService.signOut();
                        ref.invalidate(followProvider);
                        // pollsProvider auto-reloads via authStateProvider watch
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.show(context, 'Sign out failed', isError: true);
                        }
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                            color: AppColors.textDestructive
                                .withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: AppColors.textDestructive,
                              size: AppIconSizes.control),
                          const SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDestructive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── App version ──
                  const Center(
                    child: Text(
                      'Pollora v1.0.0',
                      style: AppTypography.labelSmall,
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
// Profile row — mini summary at top of settings
// ─────────────────────────────────────────────
class _ProfileRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final appUser = ref.watch(users_prov.currentUserProvider);

    final displayName = appUser?.name.isNotEmpty == true
        ? appUser!.name
        : AvatarHelper.nameFor(
            displayName: authUser?.userMetadata?['display_name'] as String?,
            email: authUser?.email,
          );
    final handle = appUser?.handle.isNotEmpty == true
        ? appUser!.handle
        : AvatarHelper.handleFor(
            handle: authUser?.userMetadata?['handle'] as String?,
            email: authUser?.email,
          );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              userId: authUser?.id ?? appUser?.id ?? '',
              displayName: displayName,
              avatarUrl: appUser?.avatarUrl,
              radius: 26,
            ),
            const SizedBox(width: 14),
            // Name + handle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(handle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            // Chevron
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: AppIconSizes.control),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings card
// ─────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        color: AppColors.surfaceCard,
        child: Column(children: children),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings row (tappable)
// ─────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon,
                    size: AppIconSizes.control, color: AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: AppTypography.titleSmall),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: AppIconSizes.control, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 48),
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}

