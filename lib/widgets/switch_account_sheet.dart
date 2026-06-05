import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_typography.dart';

class SwitchAccountSheet extends StatefulWidget {
  const SwitchAccountSheet({super.key});

  @override
  State<SwitchAccountSheet> createState() => _SwitchAccountSheetState();
}

class _SwitchAccountSheetState extends State<SwitchAccountSheet> {
  int _selectedIndex = 0;

  final List<_Account> _accounts = const [
    _Account(name: 'Clint',         handle: '@clint',  label: 'C', color: Color(0xFF8B6914)),
    _Account(name: 'Naruto Uzumaki',handle: '@naruto', label: 'N', color: Color(0xFFCC5500)),
    _Account(name: 'Goku Son',      handle: '@goku',   label: 'G', color: Color(0xFF2B4D8B)),
  ];

  void _selectAccount(int i) {
    if (i == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = i);
  }

  void _confirmSwitch() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final selected = _accounts[_selectedIndex];

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceModal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: AppColors.borderDefault, width: 0.5)),
            ),
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFF5A5A5A), borderRadius: BorderRadius.circular(999)),
                ),
                const SizedBox(height: 16),

                // Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text('Switch Account', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Account rows
                ..._accounts.asMap().entries.map((e) => Padding(
                  padding: EdgeInsets.only(bottom: e.key < _accounts.length - 1 ? 10 : 0),
                  child: _AccountRow(
                    account: e.value,
                    isSelected: e.key == _selectedIndex,
                    onTap: () => _selectAccount(e.key),
                  ),
                )),

                const SizedBox(height: 16),

                // Switch confirm button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirmSwitch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Switch to ${selected.name.split(' ').first}',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const Column(
                    children: [
                      _ActionRow(
                        icon: Icons.person_add_outlined,
                        title: 'Add another account',
                        isDestructive: false,
                        showDivider: true,
                      ),
                      _ActionRow(
                        icon: Icons.logout_rounded,
                        title: 'Sign out from all accounts',
                        isDestructive: true,
                        showDivider: false,
                      ),
                    ],
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
// Models
// ─────────────────────────────────────────────
class _Account {
  final String name;
  final String handle;
  final String label;
  final Color color;

  const _Account({
    required this.name,
    required this.handle,
    required this.label,
    required this.color,
  });
}

// ─────────────────────────────────────────────
// Account Row
// ─────────────────────────────────────────────
class _AccountRow extends StatelessWidget {
  final _Account account;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountRow({required this.account, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimaryBorder : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: account.color,
              child: Text(
                account.label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1),
              ),
            ),
            const SizedBox(width: 12),
            // Name + handle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name,
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(account.handle,
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accentPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.accentPrimary : const Color(0xFF555555),
                  width: 1.8,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
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

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.isDestructive,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon,
                  color: isDestructive ? AppColors.textDestructive : AppColors.textSecondary,
                  size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDestructive ? AppColors.textDestructive : AppColors.textPrimary,
                    )),
                ),
                if (!isDestructive)
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(height: 1, margin: const EdgeInsets.only(left: 60, right: 14), color: AppColors.borderSubtle),
      ],
    );
  }
}
