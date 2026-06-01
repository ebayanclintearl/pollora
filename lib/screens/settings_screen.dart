import 'package:flutter/material.dart';
import '../app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, top + 16, 16, bottom + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Account ──
            _SectionLabel(label: 'Account'),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Preferences ──
            _SectionLabel(label: 'Preferences'),
            _SettingsCard(
              children: [
                _SettingsToggleRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Support ──
            _SectionLabel(label: 'Support'),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate App',
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
            const SizedBox(height: 24),

            // ── Legal ──
            _SectionLabel(label: 'Legal'),
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

            // ── Sign Out ──
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── App version ──
            Center(
              child: Text(
                'Pollora v1.0.0',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
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
// Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings Card (groups rows)
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
// Settings Row (tappable)
// ─────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isDestructive;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.textDestructive : AppColors.textPrimary;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppColors.textDestructive.withOpacity(0.12)
                        : AppColors.surfaceIconBadge,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: isDestructive ? AppColors.textDestructive : Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                if (!isDestructive)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 64),
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Settings Toggle Row
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconBadge,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
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
