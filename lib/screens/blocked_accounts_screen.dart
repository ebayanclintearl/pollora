import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import '../core/supabase_client.dart';
import '../providers/moderation_provider.dart';
import '../widgets/pressable.dart';
import '../widgets/profile_avatar.dart';

class BlockedAccountsScreen extends ConsumerStatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  ConsumerState<BlockedAccountsScreen> createState() =>
      _BlockedAccountsScreenState();
}

class _BlockedUser {
  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;
  const _BlockedUser(this.id, this.name, this.handle, this.avatarUrl);
}

class _BlockedAccountsScreenState extends ConsumerState<BlockedAccountsScreen> {
  bool _loading = true;
  List<_BlockedUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = ref.read(blockProvider).toList();
    if (ids.isEmpty) {
      setState(() {
        _loading = false;
        _users = [];
      });
      return;
    }
    try {
      final data = await supabase
          .from('profiles')
          .select('id, name, handle, avatar_url')
          .inFilter('id', ids);
      _users = (data as List)
          .map((r) => _BlockedUser(
                r['id'] as String,
                r['name'] as String? ?? '',
                r['handle'] as String? ?? '',
                r['avatar_url'] as String?,
              ))
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _unblock(_BlockedUser user) async {
    HapticFeedback.selectionClick();
    setState(() => _users.removeWhere((u) => u.id == user.id));
    await ref.read(blockProvider.notifier).unblock(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Blocked Accounts', style: AppTypography.titleMedium),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary),
            )
          : _users.isEmpty
              ? _empty()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 68),
                    color: AppColors.borderSubtle,
                  ),
                  itemBuilder: (_, i) => _row(_users[i]),
                ),
    );
  }

  Widget _row(_BlockedUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ProfileAvatar(
            userId: user.id,
            displayName: user.name,
            avatarUrl: user.avatarUrl,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(user.handle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => _unblock(user),
            pressedScale: 0.93,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: const Text(
                'Unblock',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded,
              size: 44, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No blocked accounts',
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'People you block won\'t appear in your feed or comments',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
