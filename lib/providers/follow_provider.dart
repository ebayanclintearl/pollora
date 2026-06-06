import 'package:flutter_riverpod/flutter_riverpod.dart';

class FollowNotifier extends StateNotifier<Set<String>> {
  FollowNotifier() : super(const {});

  void follow(String userId) => state = {...state, userId};

  void unfollow(String userId) =>
      state = state.where((id) => id != userId).toSet();

  void toggle(String userId) {
    if (state.contains(userId)) {
      unfollow(userId);
    } else {
      follow(userId);
    }
  }
}

final followProvider =
    StateNotifierProvider<FollowNotifier, Set<String>>((ref) => FollowNotifier());

/// Convenience: is the current user following [userId]?
final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(followProvider).contains(userId);
});
