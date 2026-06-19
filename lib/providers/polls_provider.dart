import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgresChangeEvent;
import '../core/supabase_client.dart';
import '../models/poll.dart';
import 'auth_provider.dart' as auth_prov;

const _pageSize = 20;

// ── Pagination side-state ─────────────────────
final pollsHasMoreProvider     = StateProvider<bool>((ref) => true);
final pollsLoadingMoreProvider = StateProvider<bool>((ref) => false);

// ── Real-time new-poll counter ─────────────────
// Incremented by the Realtime subscription; reset to 0 on refresh.
final newPollsCountProvider = StateProvider<int>((ref) => 0);

// ── Notifier ──────────────────────────────────
class PollsNotifier extends AsyncNotifier<List<Poll>> {
  @override
  Future<List<Poll>> build() async {
    ref.watch(auth_prov.authStateProvider);
    ref.read(pollsHasMoreProvider.notifier).state     = true;
    ref.read(pollsLoadingMoreProvider.notifier).state = false;
    ref.read(newPollsCountProvider.notifier).state    = 0;

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

    return _fetch(cursor: null);
  }

  Future<List<Poll>> _fetch({required DateTime? cursor}) async {
    final uid = supabase.auth.currentUser?.id;

    // Filters must be applied before .order()/.limit() in the Supabase Dart client.
    final pollsData = cursor != null
        ? await supabase
            .from('polls')
            .select('*, author:profiles!author_id(*), poll_options(*)')
            .lt('created_at', cursor.toIso8601String())
            .order('created_at', ascending: false)
            .limit(_pageSize)
        : await supabase
            .from('polls')
            .select('*, author:profiles!author_id(*), poll_options(*)')
            .order('created_at', ascending: false)
            .limit(_pageSize);

    Map<String, String> votedOptions   = {};
    Set<String>         favoritedPolls = {};

    Set<String> sharedPolls = {};

    if (uid != null) {
      final ids = (pollsData as List).map((j) => j['id'] as String).toList();
      if (ids.isNotEmpty) {
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
    }

    return (pollsData as List).map((json) {
      final id = json['id'] as String;
      return Poll.fromJson(
        json as Map<String, dynamic>,
        votedOptionId: votedOptions[id],
        isFavorited:   favoritedPolls.contains(id),
        hasShared:     sharedPolls.contains(id),
        currentUserId: uid,
      );
    }).toList();
  }

  Future<void> refresh() async {
    ref.read(newPollsCountProvider.notifier).state = 0;
    ref.invalidateSelf();
  }

  Future<void> loadMore() async {
    if (ref.read(pollsLoadingMoreProvider) ||
        !ref.read(pollsHasMoreProvider)) return;

    final current = state.valueOrNull ?? [];
    if (current.isEmpty) return;

    ref.read(pollsLoadingMoreProvider.notifier).state = true;
    try {
      final cursor = current.last.createdAt;
      final more   = await _fetch(cursor: cursor);
      ref.read(pollsHasMoreProvider.notifier).state = more.length >= _pageSize;
      state = AsyncData([...current, ...more]);
    } catch (_) {
      // Keep existing state on failure.
    } finally {
      ref.read(pollsLoadingMoreProvider.notifier).state = false;
    }
  }

  List<Poll> get _current => state.valueOrNull ?? const [];

  // Track in-flight mutations so rapid taps can't fire duplicate DB calls.
  final _votingPolls     = <String>{};
  final _favoritingPolls = <String>{};

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
        if (o.id == prev)     return o.copyWith(votes: (o.votes - 1).clamp(0, 999999));
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

    // Upload images to Storage before writing to DB.
    final coverUrl = await _uploadImage(
        localPoll.coverImagePath, 'poll-covers', uid);

    final row = await supabase.from('polls').insert({
      'author_id':       uid,
      'question':        localPoll.question,
      'cover_image_url': coverUrl,
    }).select().single();

    final pollId = row['id'] as String;

    if (localPoll.options.isNotEmpty) {
      final optionRows = <Map<String, dynamic>>[];
      for (int i = 0; i < localPoll.options.length; i++) {
        final opt    = localPoll.options[i];
        final imgUrl = await _uploadImage(opt.imagePath, 'poll-options', uid);
        optionRows.add({
          'poll_id':   pollId,
          'text':      opt.text,
          'position':  i,
          'image_url': imgUrl,
        });
      }
      await supabase.from('poll_options').insert(optionRows);
    }

    ref.invalidateSelf();
  }

  Future<void> deletePoll(String pollId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final snapshot = _current;
    // Optimistic remove
    state = AsyncData(_current.where((p) => p.id != pollId).toList());
    try {
      await supabase.from('polls').delete().eq('id', pollId).eq('author_id', uid);
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

  /// Uploads [localPath] to [bucket] under [uid]/timestamp.ext.
  /// Returns the public URL on success, or null if path is null / upload fails.
  Future<String?> _uploadImage(
      String? localPath, String bucket, String uid) async {
    if (localPath == null || localPath.isEmpty) return null;
    if (localPath.startsWith('http')) return localPath; // already a URL

    final file = File(localPath);
    if (!file.existsSync()) return null;

    // Reject files over 5 MB before hitting Storage.
    const maxBytes = 5 * 1024 * 1024;
    if (await file.length() > maxBytes) throw Exception('Image must be under 5 MB');

    final ext      = p.extension(localPath).isNotEmpty
        ? p.extension(localPath)
        : '.jpg';
    final fileName =
        '$uid/${DateTime.now().millisecondsSinceEpoch}$ext';

    try {
      await supabase.storage.from(bucket).upload(fileName, file);
      return supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }
}

// ── Providers ─────────────────────────────────
final pollsProvider =
    AsyncNotifierProvider<PollsNotifier, List<Poll>>(PollsNotifier.new);

/// Newest-first (full loaded list).
final feedPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  return [...polls]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Trending: engagement score within last 7 days.
final trendingPollsProvider = Provider<List<Poll>>((ref) {
  final polls  = ref.watch(pollsProvider).valueOrNull ?? const [];
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  int score(Poll p) => p.totalVotes + p.commentCount * 3;
  return polls.where((p) => p.createdAt.isAfter(cutoff)).toList()
    ..sort((a, b) => score(b).compareTo(score(a)));
});

/// Popular: sorted by total votes.
final popularPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  return [...polls]..sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
});

/// Following: polls from followed users.
final followingPollsProvider =
    Provider.family<List<Poll>, Set<String>>((ref, followedIds) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  return polls.where((p) => followedIds.contains(p.author.id)).toList()
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
final pollsByUserProvider =
    Provider.family<List<Poll>, String>((ref, userId) {
  final polls = ref.watch(pollsProvider).valueOrNull ?? const [];
  return polls
      .where((p) => p.author.id == userId && p.sharedBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
