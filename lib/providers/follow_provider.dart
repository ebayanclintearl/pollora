import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';

class FollowNotifier extends StateNotifier<Set<String>> {
  FollowNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', uid);
      if (mounted) {
        state = (data as List)
            .map((r) => r['following_id'] as String)
            .toSet();
      }
    } catch (_) {}
  }

  Future<void> follow(String userId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    state = {...state, userId};
    try {
      await supabase.from('follows').insert({
        'follower_id': uid,
        'following_id': userId,
      });
    } catch (_) {
      state = state.where((id) => id != userId).toSet();
    }
  }

  Future<void> unfollow(String userId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final prev = state;
    state = state.where((id) => id != userId).toSet();
    try {
      await supabase
          .from('follows')
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', userId);
    } catch (_) {
      state = prev;
    }
  }

  Future<void> toggle(String userId) {
    if (state.contains(userId)) return unfollow(userId);
    return follow(userId);
  }
}

final followProvider =
    StateNotifierProvider<FollowNotifier, Set<String>>((ref) => FollowNotifier());

/// Convenience: is the current user following [userId]?
final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(followProvider).contains(userId);
});
