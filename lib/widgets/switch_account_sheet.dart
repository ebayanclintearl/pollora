import 'package:flutter/material.dart';
import '../app_colors.dart';

class SwitchAccountSheet extends StatefulWidget {
  const SwitchAccountSheet({super.key});

  @override
  State<SwitchAccountSheet> createState() => _SwitchAccountSheetState();
}

class _SwitchAccountSheetState extends State<SwitchAccountSheet> {
  int _selectedIndex = 0;

  final List<_Account> _accounts = const [
    _Account(name: 'Clint', email: 'clint@example.com', avatarColor: Color(0xFF8B6914), label: 'C'),
    _Account(name: 'Naruto Uzumaki', email: 'naruto@example.com', avatarColor: Color(0xFFE8A020), label: 'N'),
    _Account(name: 'Goku Son', email: 'goku@example.com', avatarColor: Color(0xFF1A6B3C), label: 'G'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          // Title block
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Switch account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose an account to continue',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Account rows
          ..._accounts.asMap().entries.map((e) {
            final i = e.key;
            final account = e.value;
            final isSelected = i == _selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccountRow(
                account: account,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            );
          }),

          // Action group
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.person_add_outlined,
                  title: 'Add another account',
                  subtitle: 'Sign in with a different Google account',
                  isDestructive: false,
                  showDivider: true,
                ),
                _ActionRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out from all accounts',
                  subtitle: 'This will sign you out of Pulse',
                  isDestructive: true,
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Cancel
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textAccent,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Account {
  final String name;
  final String email;
  final Color avatarColor;
  final String label;

  const _Account({
    required this.name,
    required this.email,
    required this.avatarColor,
    required this.label,
  });
}

class _AccountRow extends StatelessWidget {
  final _Account account;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountRow({
    super.key,
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimaryMuted
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPrimaryBorder
                : AppColors.borderDefault,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: account.avatarColor,
              child: Text(
                account.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.email,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accentPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentPrimary
                      : const Color(0xFF444444),
                  width: 2,
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

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool showDivider;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDestructive,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDestructive ? AppColors.textDestructive : AppColors.textPrimary;
    final iconColor =
        isDestructive ? AppColors.textDestructive : AppColors.textPrimary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 16),
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}
