import 'package:supabase_flutter/supabase_flutter.dart';

/// Global convenience getter for the Supabase client.
/// Usage: `supabase.from('polls').select()`
SupabaseClient get supabase => Supabase.instance.client;

/// Current authenticated user — null if not logged in.
User? get currentAuthUser => supabase.auth.currentUser;
