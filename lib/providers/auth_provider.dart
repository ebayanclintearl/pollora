import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

/// Streams every auth state change (sign in, sign out, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Streams only sign-in and sign-out events — ignores token refreshes.
/// Use this to avoid rebuilding data providers on routine token rotation.
final authSignInOutProvider = StreamProvider<AuthChangeEvent>((ref) {
  return supabase.auth.onAuthStateChange
      .where((s) =>
          s.event == AuthChangeEvent.signedIn ||
          s.event == AuthChangeEvent.signedOut)
      .map((s) => s.event);
});

/// True if a valid session exists.
final isAuthenticatedProvider = Provider<bool>((ref) {
  // While the stream is loading, fall back to the cached session so the
  // app doesn't flash the auth sheet on a warm restart.
  return ref.watch(authStateProvider).when(
    data:    (s) => s.session != null,
    loading: ()  => supabase.auth.currentSession != null,
    error:   (_, __) => false,
  );
});

/// The currently authenticated Supabase user, or null.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // re-evaluate on any auth change
  return supabase.auth.currentUser;
});
