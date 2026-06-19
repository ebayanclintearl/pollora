import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/poll.dart';
import '../models/user.dart';
import 'polls_provider.dart';

sealed class SearchItem {
  const SearchItem();
}

class UserSearchItem extends SearchItem {
  final AppUser user;
  const UserSearchItem(this.user);
}

class PollSearchItem extends SearchItem {
  final Poll poll;
  const PollSearchItem(this.poll);
}

final searchQueryProvider = StateProvider<String>((ref) => '');

// ── DB-backed search with 350ms debounce ──────
class _SearchNotifier extends AsyncNotifier<List<SearchItem>> {
  Timer? _debounce;

  @override
  Future<List<SearchItem>> build() async {
    final query = ref.watch(searchQueryProvider).trim();

    if (query.isEmpty) return const [];

    // Debounce: cancel previous timer and restart.
    _debounce?.cancel();
    final completer = Completer<List<SearchItem>>();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        completer.complete(await _query(query));
      } catch (e) {
        completer.completeError(e);
      }
    });

    ref.onDispose(() {
      _debounce?.cancel();
      if (!completer.isCompleted) completer.complete(const []);
    });

    return completer.future;
  }

  Future<List<SearchItem>> _query(String q) async {
    final uid = supabase.auth.currentUser?.id;
    final like = '%$q%';

    final results = await Future.wait([
      // Users matching name or handle
      supabase
          .from('profiles')
          .select()
          .or('name.ilike.$like,handle.ilike.$like')
          .neq('id', uid ?? '')
          .limit(4),
      // Polls matching question text
      supabase
          .from('polls')
          .select('*, author:profiles!author_id(*), poll_options(*)')
          .ilike('question', like)
          .order('created_at', ascending: false)
          .limit(6),
    ]);

    final users = (results[0] as List)
        .map((j) => AppUser.fromJson(j as Map<String, dynamic>))
        .map<SearchItem>((u) => UserSearchItem(u))
        .toList();

    final polls = (results[1] as List)
        .map((j) => Poll.fromJson(j as Map<String, dynamic>, currentUserId: uid))
        .map<SearchItem>((p) => PollSearchItem(p))
        .toList();

    return [...users, ...polls];
  }
}

final searchSuggestionsProvider =
    AsyncNotifierProvider<_SearchNotifier, List<SearchItem>>(
        _SearchNotifier.new);
