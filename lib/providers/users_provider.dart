import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/user.dart';
import 'auth_provider.dart' as auth_prov;
import 'polls_provider.dart';

// ── Current profile (async) ───────────────────
class CurrentProfileNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // Re-run whenever auth state changes (sign-in / sign-out).
    ref.watch(auth_prov.authStateProvider);
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .single();
      return AppUser.fromJson((data as Map).cast<String, dynamic>(), isCurrentUser: true);
    } catch (_) {
      // Profile row may not exist yet (new sign-up race condition).
      return AppUser(
        id: authUser.id,
        name: authUser.userMetadata?['display_name'] as String? ??
              authUser.email?.split('@').first ?? 'User',
        handle: '@user',
        isCurrentUser: true,
      );
    }
  }

  Future<void> refresh() async => ref.invalidateSelf();

  Future<void> saveProfile({String? name, String? handle, String? bio}) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    await supabase.from('profiles').update({
      if (name != null) 'name': name,
      if (handle != null) 'handle': handle,
      if (bio != null) 'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
    ref.invalidateSelf();
  }
}

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfileNotifier, AppUser?>(
        CurrentProfileNotifier.new);

/// Synchronous read of the current user — null while loading or signed out.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(currentProfileProvider).valueOrNull;
});

/// All unique users who have authored a visible poll.
/// Derived from loaded polls — avoids a separate DB query and circular imports.
final allUsersProvider = Provider<List<AppUser>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  final seen = <String>{};
  final users = <AppUser>[];
  for (final p in polls) {
    if (seen.add(p.author.id)) {
      users.add(p.author);
    }
  }
  return users;
});

/// Quick lookup of an AppUser by id, sourced from loaded polls.
final userByIdProvider = Provider.family<AppUser?, String>((ref, id) {
  final users = ref.watch(allUsersProvider);
  for (final u in users) {
    if (u.id == id) return u;
  }
  return null;
});

/// Full profile fetch by id — includes bio and all counts.
final fullProfileProvider =
    FutureProvider.family<AppUser, String>((ref, userId) async {
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();
  final uid = supabase.auth.currentUser?.id;
  return AppUser.fromJson(
    (data as Map).cast<String, dynamic>(),
    isCurrentUser: uid == userId,
  );
});
