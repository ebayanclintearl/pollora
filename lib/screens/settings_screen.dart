import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Settings', style: AppTypography.screenTitle),
                ],
              ),
            ),

            // ── Scrollable body ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Profile row ──
                  _ProfileRow(),
                  const SizedBox(height: 20),

                  // ── Account ──
                  const _SectionLabel('Account'),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Preferences ──
                  const _SectionLabel('Preferences'),
                  _SettingsCard(
                    children: [
                      _SettingsToggleRow(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                    onTap: () => HapticFeedback.mediumImpact(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.textDestructive.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: AppColors.textDestructive, size: 18),
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
class _ProfileRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8B6914),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clint', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('@clint', style: AppTypography.bodySmall),
              ],
            ),
          ),
          // Chevron
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary, size: 20),
        ],
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
      borderRadius: BorderRadius.circular(16),
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
          onTap: () { HapticFeedback.selectionClick(); onTap(); },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: AppTypography.titleSmall),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textTertiary),
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

// ─────────────────────────────────────────────
// Settings toggle row
// ─────────────────────────────────────────────
class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTypography.titleSmall),
          ),
          Switch(
            value: value,
            onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); },
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accentPrimary,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceElevated,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
