import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../core/supabase_client.dart';

// ─────────────────────────────────────────────
// Blocking — holds the set of user IDs the current user has blocked.
// Mirrors FollowNotifier so the feed/comments can filter cheaply.
// ─────────────────────────────────────────────
class BlockNotifier extends StateNotifier<Set<String>> {
  BlockNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await supabase
          .from('blocked_users')
          .select('blocked_id')
          .eq('blocker_id', uid);
      if (mounted) {
        state = (data as List).map((r) => r['blocked_id'] as String).toSet();
      }
    } catch (_) {}
  }

  Future<void> block(String userId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null || userId == uid) return;
    final prev = state;
    state = {...state, userId};
    try {
      await supabase.from('blocked_users').insert({
        'blocker_id': uid,
        'blocked_id': userId,
      });
    } catch (_) {
      state = prev;
    }
  }

  Future<void> unblock(String userId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final prev = state;
    state = state.where((id) => id != userId).toSet();
    try {
      await supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', uid)
          .eq('blocked_id', userId);
    } catch (_) {
      state = prev;
    }
  }

  Future<void> toggle(String userId) {
    if (state.contains(userId)) return unblock(userId);
    return block(userId);
  }
}

final blockProvider =
    StateNotifierProvider<BlockNotifier, Set<String>>((ref) => BlockNotifier());

/// Convenience: has the current user blocked [userId]?
final isBlockedProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(blockProvider).contains(userId);
});

// ─────────────────────────────────────────────
// Reporting — persists a report row. Targets: 'poll' | 'comment' | 'user'.
// Returns true on success (a duplicate report is treated as success).
// ─────────────────────────────────────────────
Future<bool> reportContent({
  required String targetType,
  required String targetId,
  String? reason,
}) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return false;
  try {
    await supabase.from('reports').insert({
      'reporter_id': uid,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
    });
    return true;
  } on PostgrestException catch (e) {
    // 23505 = unique violation → already reported this target. Fine.
    return e.code == '23505';
  } catch (_) {
    return false;
  }
}
