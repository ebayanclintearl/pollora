import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions, PostgrestException;
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

  Future<void> saveProfile({
    String? name,
    String? handle,
    String? bio,
    File? avatarFile,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    String? avatarUrl;
    if (avatarFile != null) {
      avatarUrl = await _uploadAvatar(avatarFile, uid);
      // Evict cached image so the new photo shows immediately everywhere.
      // Read our own state directly — going through currentUserProvider here
      // would be a circular dependency (it watches this notifier).
      // Must never block saving — a cache miss/error here is harmless.
      final oldUrl = state.valueOrNull?.avatarUrl;
      if (oldUrl != null) {
        try {
          await CachedNetworkImage.evictFromCache(oldUrl);
        } catch (_) {/* ignore — eviction is best-effort */}
      }
    }

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null)      updateData['name']       = name;
    if (handle != null)    updateData['handle']     = handle;
    if (bio != null)       updateData['bio']        = bio;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    try {
      await supabase.from('profiles').update(updateData).eq('id', uid);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw Exception('handle_taken');
      rethrow;
    }

    // Rebuilding this provider automatically invalidates fullProfileProvider,
    // because fullProfileProvider watches currentProfileProvider. Explicitly
    // invalidating that dependent here creates a circular dependency.
    ref.invalidateSelf();
  }

  Future<String?> _uploadAvatar(File file, String uid) async {
    const maxBytes = 5 * 1024 * 1024;
    if (await file.length() > maxBytes) throw Exception('Image must be under 5 MB');

    final ext = p.extension(file.path).isNotEmpty ? p.extension(file.path) : '.jpg';
    final fileName = '$uid/avatar$ext';

    await supabase.storage.from('avatars').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = supabase.storage.from('avatars').getPublicUrl(fileName);
    // Append a version timestamp so CachedNetworkImage treats re-uploads as
    // a new URL and re-fetches instead of serving the stale cached image.
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
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

/// Full profile fetch by id — includes bio, counts, and followsCurrentUser.
final fullProfileProvider =
    FutureProvider.family<AppUser, String>((ref, userId) async {
  // Re-run whenever the current user's profile changes (e.g. after edit).
  ref.watch(currentProfileProvider);

  final uid = supabase.auth.currentUser?.id;

  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

  bool followsCurrentUser = false;
  if (uid != null && uid != userId) {
    final row = await supabase
        .from('follows')
        .select('follower_id')
        .eq('follower_id', userId)
        .eq('following_id', uid)
        .maybeSingle();
    followsCurrentUser = row != null;
  }

  return AppUser.fromJson(
    (data as Map).cast<String, dynamic>(),
    isCurrentUser: uid == userId,
    followsCurrentUser: followsCurrentUser,
  );
});
