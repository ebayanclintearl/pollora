import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent;
import '../core/supabase_client.dart';
import '../models/poll.dart';
import 'auth_provider.dart' as auth_prov;
import 'moderation_provider.dart';

const _pageSize = 20;

// ── Pagination side-state ─────────────────────
final pollsHasMoreProvider = StateProvider<bool>((ref) => true);
final pollsLoadingMoreProvider = StateProvider<bool>((ref) => false);

// ── Real-time new-poll counter ─────────────────
// Incremented by the Realtime subscription; reset to 0 on refresh.
final newPollsCountProvider = StateProvider<int>((ref) => 0);

// ── Notifier ──────────────────────────────────
class PollsNotifier extends AsyncNotifier<List<Poll>> {
  @override
  Future<List<Poll>> build() async {
    ref.watch(auth_prov.authSignInOutProvider);

    // Defer mutations — modifying other providers synchronously inside
    // build() is illegal in Riverpod and crashes on provider rebuild.
    var disposed = false;
    ref.onDispose(() => disposed = true);
    Future.microtask(() {
      if (disposed) return;
      ref.read(pollsHasMoreProvider.notifier).state = true;
      ref.read(pollsLoadingMoreProvider.notifier).state = false;
      ref.read(newPollsCountProvider.notifier).state = 0;
    });

    // Subscribe to new polls via Realtime; increment the banner counter.
    final channel = supabase
        .channel('public:polls:inserts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'polls',
          callback: (payload) {
            final uid = supabase.auth.currentUser?.id;
            // Don't count the current user's own new polls.
            if (payload.newRecord['author_id'] == uid) return;
            ref.read(newPollsCountProvider.notifier).state++;
          },
        )
        .subscribe();

    // Cancel the channel when the provider is rebuilt / disposed.
    ref.onDispose(() => supabase.removeChannel(channel));

    final initial = await _fetch(cursor: null);
    _latestCursor = initial.isNotEmpty ? initial.last.createdAt : null;
    return initial;
  }

  // Oldest "Latest"-tab poll loaded so far. Kept separate from the pool so
  // merging ranked polls (Popular/Trending/Following) can't corrupt the
  // chronological pagination cursor.
  DateTime? _latestCursor;

  static const _selectCols = '*, author:profiles!author_id(*), poll_options(*)';

  // Latest feed page (newest-first, keyset-paginated by created_at).
  Future<List<Poll>> _fetch({required DateTime? cursor}) async {
    final pollsData = cursor != null
        ? await supabase
            .from('polls')
            .select(_selectCols)
            .lt('created_at', cursor.toIso8601String())
            .order('created_at', ascending: false)
            .limit(_pageSize)
        : await supabase
            .from('polls')
            .select(_selectCols)
            .order('created_at', ascending: false)
            .limit(_pageSize);
    return _decorate(pollsData as List);
  }

  // Annotate raw poll rows with the current user's vote/favorite/share state.
  Future<List<Poll>> _decorate(List pollsData) async {
    final uid = supabase.auth.currentUser?.id;
    Map<String, String> votedOptions = {};
    Set<String> favoritedPolls = {};
    Set<String> sharedPolls = {};

    if (uid != null && pollsData.isNotEmpty) {
      final ids = pollsData.map((j) => j['id'] as String).toList();
      final results = await Future.wait([
        supabase
            .from('votes')
            .select('poll_id, option_id')
            .eq('user_id', uid)
            .inFilter('poll_id', ids),
        supabase
            .from('favorites')
            .select('poll_id')
            .eq('user_id', uid)
            .inFilter('poll_id', ids),
        supabase
            .from('shares')
            .select('poll_id')
            .eq('user_id', uid)
            .inFilter('poll_id', ids),
      ]);
      for (final v in results[0] as List) {
        votedOptions[v['poll_id'] as String] = v['option_id'] as String;
      }
      for (final f in results[1] as List) {
        favoritedPolls.add(f['poll_id'] as String);
      }
      for (final s in results[2] as List) {
        sharedPolls.add(s['poll_id'] as String);
      }
    }

    return pollsData.map((json) {
      final id = json['id'] as String;
      return Poll.fromJson(
        json as Map<String, dynamic>,
        votedOptionId: votedOptions[id],
        isFavorited: favoritedPolls.contains(id),
        hasShared: sharedPolls.contains(id),
        currentUserId: uid,
      );
    }).toList();
  }

  // Add fetched polls to the shared pool, skipping ones already present so
  // existing optimistic state (votes/favorites) is preserved.
  void _merge(List<Poll> fetched) {
    final current = _current;
    final existing = {for (final p in current) p.id};
    final additions = fetched.where((p) => !existing.contains(p.id)).toList();
    if (additions.isEmpty) return;
    state = AsyncData([...current, ...additions]);
  }

  // ── Server-side ranked tabs — fetched on demand and merged into the pool
  // so the derived providers reorder a globally-correct set. ────────────────
  Future<void> loadPopular() async {
    try {
      final data = await supabase
          .from('polls')
          .select(_selectCols)
          .order('vote_count', ascending: false)
          .limit(_pageSize * 2);
      _merge(await _decorate(data as List));
    } catch (_) {}
  }

  Future<void> loadTrending() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    try {
      final data = await supabase
          .from('polls')
          .select(_selectCols)
          .gt('created_at', cutoff.toIso8601String())
          .order('vote_count', ascending: false)
          .limit(_pageSize * 2);
      _merge(await _decorate(data as List));
    } catch (_) {}
  }

  Future<void> loadFollowing(Set<String> followedIds) async {
    if (followedIds.isEmpty) return;
    try {
      final data = await supabase
          .from('polls')
          .select(_selectCols)
          .inFilter('author_id', followedIds.toList())
          .order('created_at', ascending: false)
          .limit(_pageSize * 2);
      _merge(await _decorate(data as List));
    } catch (_) {}
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    ref.read(newPollsCountProvider.notifier).state = 0;
    try {
      final fresh = await _fetch(cursor: null);
      _latestCursor = fresh.isNotEmpty ? fresh.last.createdAt : null;
      ref.read(pollsHasMoreProvider.notifier).state = true;
      ref.read(pollsLoadingMoreProvider.notifier).state = false;
      state = AsyncData(fresh);
    } catch (_) {
      // Keep current data visible on error; don't flash empty.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> loadMore() async {
    if (ref.read(pollsLoadingMoreProvider) || !ref.read(pollsHasMoreProvider)) {
      return;
    }

    final cursor = _latestCursor;
    if (cursor == null) return;

    ref.read(pollsLoadingMoreProvider.notifier).state = true;
    try {
      final more = await _fetch(cursor: cursor);
      ref.read(pollsHasMoreProvider.notifier).state = more.length >= _pageSize;
      if (more.isNotEmpty) _latestCursor = more.last.createdAt;
      _merge(more);
    } catch (_) {
      // Keep existing state on failure.
    } finally {
      ref.read(pollsLoadingMoreProvider.notifier).state = false;
    }
  }

  List<Poll> get _current => state.valueOrNull ?? const [];

  // Track in-flight mutations so rapid taps can't fire duplicate DB calls.
  final _votingPolls = <String>{};
  final _favoritingPolls = <String>{};
  bool _refreshing = false;

  // ── Mutations ─────────────────────────────

  Future<void> vote(String pollId, String optionId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    if (_votingPolls.contains(pollId)) return; // in-flight guard
    _votingPolls.add(pollId);
    final snapshot = _current;
    state = AsyncData(_current.map((poll) {
      if (poll.id != pollId) return poll;
      if (poll.votedOptionId == optionId) return poll;
      final prev = poll.votedOptionId;
      final opts = poll.options.map((o) {
        if (o.id == optionId) return o.copyWith(votes: o.votes + 1);
        if (o.id == prev)
          return o.copyWith(votes: (o.votes - 1).clamp(0, 999999));
        return o;
      }).toList();
      return poll.copyWith(options: opts, votedOptionId: optionId);
    }).toList());
    try {
      await supabase.from('votes').upsert(
        {'user_id': uid, 'poll_id': pollId, 'option_id': optionId},
        onConflict: 'user_id,poll_id',
      );
    } catch (_) {
      state = AsyncData(snapshot);
    } finally {
      _votingPolls.remove(pollId);
    }
  }

  Future<void> toggleFavorite(String pollId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    if (_favoritingPolls.contains(pollId)) return; // in-flight guard
    _favoritingPolls.add(pollId);
    final snapshot = _current;
    bool? was;
    state = AsyncData(_current.map((p) {
      if (p.id != pollId) return p;
      was = p.isFavorited;
      return p.copyWith(isFavorited: !p.isFavorited);
    }).toList());
    if (was == null) return;
    try {
      if (was!) {
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', uid)
            .eq('poll_id', pollId);
      } else {
        await supabase
            .from('favorites')
            .insert({'user_id': uid, 'poll_id': pollId});
      }
    } catch (_) {
      state = AsyncData(snapshot);
    } finally {
      _favoritingPolls.remove(pollId);
    }
  }

  Future<void> addPoll(Poll localPoll) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');

    final question = localPoll.question.trim();
    if (question.isEmpty || question.length > 300) {
      throw Exception('Question must be 1–300 characters');
    }
    for (final opt in localPoll.options) {
      if (opt.text.trim().isEmpty || opt.text.trim().length > 120) {
        throw Exception('Each option must be 1–120 characters');
      }
    }

    // Track every successfully uploaded file so we can clean up on failure.
    final uploaded = <({String bucket, String path, String url})>[];

    try {
      final coverResult = await _uploadImageTracked(
          localPoll.coverImagePath, 'poll-covers', uid);
      if (coverResult != null) uploaded.add(coverResult);

      final row = await supabase
          .from('polls')
          .insert({
            'author_id': uid,
            'question': localPoll.question,
            'cover_image_url': coverResult?.url,
          })
          .select()
          .single();

      final pollId = row['id'] as String;

      if (localPoll.options.isNotEmpty) {
        final optionRows = <Map<String, dynamic>>[];
        for (int i = 0; i < localPoll.options.length; i++) {
          final opt = localPoll.options[i];
          final img =
              await _uploadImageTracked(opt.imagePath, 'poll-options', uid);
          if (img != null) uploaded.add(img);
          optionRows.add({
            'poll_id': pollId,
            'text': opt.text,
            'position': i,
            'image_url': img?.url,
          });
        }
        await supabase.from('poll_options').insert(optionRows);
      }
    } catch (e) {
      // Best-effort cleanup of any files uploaded before the failure.
      for (final u in uploaded) {
        try {
          await supabase.storage.from(u.bucket).remove([u.path]);
        } catch (_) {}
      }
      rethrow;
    }

    // Refresh without going through AsyncLoading (no empty flash).
    _refreshing = false;
    await refresh();
  }

  Future<void> deletePoll(String pollId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final snapshot = _current;
    // Optimistic remove
    state = AsyncData(_current.where((p) => p.id != pollId).toList());
    try {
      await supabase
          .from('polls')
          .delete()
          .eq('id', pollId)
          .eq('author_id', uid);
    } catch (_) {
      state = AsyncData(snapshot);
      rethrow;
    }
  }

  Future<void> share(String pollId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    final poll = _current.firstWhere((p) => p.id == pollId,
        orElse: () => throw StateError('poll not found'));
    if (poll.hasShared) return; // already counted this user

    // Optimistic update
    final snapshot = _current;
    state = AsyncData(_current.map((p) {
      if (p.id != pollId) return p;
      return p.copyWith(hasShared: true, shareCount: p.shareCount + 1);
    }).toList());

    try {
      await supabase.from('shares').insert({'user_id': uid, 'poll_id': pollId});
    } catch (_) {
      state = AsyncData(snapshot); // revert on failure
    }
  }

  // ── Storage helpers ───────────────────────

  /// Uploads [localPath] to [bucket] and returns both the public URL and
  /// the storage path, so the caller can clean up on failure.
  /// Returns null if [localPath] is empty, already a URL, or file missing.
  Future<({String url, String path, String bucket})?> _uploadImageTracked(
      String? localPath, String bucket, String uid) async {
    if (localPath == null || localPath.isEmpty) return null;
    if (localPath.startsWith('http')) return null; // already persisted

    final file = File(localPath);
    if (!file.existsSync()) return null;

    const maxBytes = 5 * 1024 * 1024;
    if (await file.length() > maxBytes)
      throw Exception('Image must be under 5 MB');

    final ext =
        p.extension(localPath).isNotEmpty ? p.extension(localPath) : '.jpg';
    final fileName = '$uid/${DateTime.now().millisecondsSinceEpoch}$ext';

    await supabase.storage.from(bucket).upload(fileName, file);
    final url = supabase.storage.from(bucket).getPublicUrl(fileName);
    return (url: url, path: fileName, bucket: bucket);
  }
}

// ── Providers ─────────────────────────────────
final pollsProvider =
    AsyncNotifierProvider<PollsNotifier, List<Poll>>(PollsNotifier.new);

/// Newest-first (full loaded list), minus blocked authors.
final feedPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  final blocked = ref.watch(blockProvider);
  return polls.where((p) => !blocked.contains(p.author.id)).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Trending: engagement score within last 7 days, minus blocked authors.
final trendingPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  final blocked = ref.watch(blockProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  int score(Poll p) => p.totalVotes + p.commentCount * 3;
  return polls
      .where(
          (p) => p.createdAt.isAfter(cutoff) && !blocked.contains(p.author.id))
      .toList()
    ..sort((a, b) => score(b).compareTo(score(a)));
});

/// Popular: sorted by total votes, minus blocked authors.
final popularPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  final blocked = ref.watch(blockProvider);
  return polls.where((p) => !blocked.contains(p.author.id)).toList()
    ..sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
});

/// Following: polls from followed users, minus blocked authors.
final followingPollsProvider =
    Provider.family<List<Poll>, Set<String>>((ref, followedIds) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  final blocked = ref.watch(blockProvider);
  return polls
      .where((p) =>
          followedIds.contains(p.author.id) && !blocked.contains(p.author.id))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Current user's own polls.
final myPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  return polls
      .where((p) => p.author.isCurrentUser && p.sharedBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Favorited polls.
final favoritePollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  return polls.where((p) => p.isFavorited).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Polls by a specific author.
final pollsByUserProvider = Provider.family<List<Poll>, String>((ref, userId) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  return polls
      .where((p) => p.author.id == userId && p.sharedBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
