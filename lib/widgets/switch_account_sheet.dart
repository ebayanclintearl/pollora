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
    _Account(
      name: 'Clint',
      email: 'clint@example.com',
      label: 'C',
    ),
    _Account(
      name: 'Naruto Uzumaki',
      email: 'naruto@example.com',
      label: 'N',
    ),
    _Account(
      name: 'Goku Son',
      email: 'goku@example.com',
      label: 'G',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceModal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: AppColors.borderDefault, width: 0.7),
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A5A5A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'Switch account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ..._accounts.asMap().entries.map((e) {
                  final i = e.key;
                  final account = e.value;
                  final isSelected = i == _selectedIndex;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _accounts.length - 1 ? 0 : 10,
                    ),
                    child: _AccountRow(
                      account: account,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedIndex = i),
                    ),
                  );
                }),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
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

class _Account {
  final String name;
  final String email;
  final String label;

  const _Account({
    required this.name,
    required this.email,
    required this.label,
  });
}

class _AccountRow extends StatelessWidget {
  final _Account account;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountRow({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPrimaryBorder
                : AppColors.borderSubtle,
            width: isSelected ? 1.1 : 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceInput,
              child: Text(
                account.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    account.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? AppColors.accentPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentPrimary
                      : const Color(0xFF555555),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 17,
                    )
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDestructive
                        ? AppColors.textDestructive
                        : AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 62, right: 14),
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}
