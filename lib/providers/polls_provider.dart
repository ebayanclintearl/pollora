import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/poll.dart';

// ── Notifier ──────────────────────────────────
class PollsNotifier extends StateNotifier<List<Poll>> {
  PollsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = supabase.auth.currentUser?.id;

      final pollsData = await supabase
          .from('polls')
          .select('*, author:profiles!author_id(*), poll_options(*)')
          .order('created_at', ascending: false);

      Map<String, String> votedOptions = {};
      Set<String> favoritedPolls = {};

      if (uid != null) {
        final results = await Future.wait([
          supabase
              .from('votes')
              .select('poll_id, option_id')
              .eq('user_id', uid),
          supabase.from('favorites').select('poll_id').eq('user_id', uid),
        ]);
        for (final v in results[0] as List) {
          votedOptions[v['poll_id'] as String] = v['option_id'] as String;
        }
        for (final f in results[1] as List) {
          favoritedPolls.add(f['poll_id'] as String);
        }
      }

      if (!mounted) return;
      state = (pollsData as List).map((json) {
        final id = json['id'] as String;
        return Poll.fromJson(
          json as Map<String, dynamic>,
          votedOptionId: votedOptions[id],
          isFavorited: favoritedPolls.contains(id),
          currentUserId: uid,
        );
      }).toList();
    } catch (_) {
      // Keep current state on error — UI shows whatever was last loaded.
    }
  }

  Future<void> refresh() => _load();

  Future<void> vote(String pollId, String optionId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    // Optimistic update
    state = state.map((poll) {
      if (poll.id != pollId) return poll;
      if (poll.votedOptionId == optionId) return poll;
      final prev = poll.votedOptionId;
      final opts = poll.options.map((o) {
        if (o.id == optionId) return o.copyWith(votes: o.votes + 1);
        if (o.id == prev) return o.copyWith(votes: (o.votes - 1).clamp(0, 999999));
        return o;
      }).toList();
      return poll.copyWith(options: opts, votedOptionId: optionId);
    }).toList();

    try {
      await supabase.from('votes').upsert(
        {'user_id': uid, 'poll_id': pollId, 'option_id': optionId},
        onConflict: 'user_id,poll_id',
      );
    } catch (_) {
      await _load();
    }
  }

  Future<void> toggleFavorite(String pollId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    bool? was;
    state = state.map((p) {
      if (p.id != pollId) return p;
      was = p.isFavorited;
      return p.copyWith(isFavorited: !p.isFavorited);
    }).toList();
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
      // Revert on failure
      state = state.map((p) {
        if (p.id != pollId) return p;
        return p.copyWith(isFavorited: was!);
      }).toList();
    }
  }

  Future<void> addPoll(Poll localPoll) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final row = await supabase.from('polls').insert({
        'author_id': uid,
        'question': localPoll.question,
        'cover_image_url': localPoll.coverImagePath,
      }).select().single();

      final pollId = row['id'] as String;

      if (localPoll.options.isNotEmpty) {
        await supabase.from('poll_options').insert(
          localPoll.options.asMap().entries.map((e) => {
            'poll_id': pollId,
            'text': e.value.text,
            'position': e.key,
            'image_url': e.value.imagePath,
          }).toList(),
        );
      }

      await _load();
    } catch (_) {}
  }

  void incrementShare(String pollId) {
    state = state.map((p) {
      if (p.id != pollId) return p;
      return p.copyWith(shareCount: p.shareCount + 1);
    }).toList();
  }
}

// ── Providers ─────────────────────────────────
final pollsProvider =
    StateNotifierProvider<PollsNotifier, List<Poll>>((ref) => PollsNotifier());

/// All polls sorted newest first (for the feed).
final feedPollsProvider = Provider<List<Poll>>((ref) {
  return [...ref.watch(pollsProvider)]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Trending — engagement score within the last 7 days.
final trendingPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  int score(Poll p) => p.totalVotes + p.commentCount * 3;
  return polls.where((p) => p.createdAt.isAfter(cutoff)).toList()
    ..sort((a, b) => score(b).compareTo(score(a)));
});

/// Popular — all time, sorted by total votes.
final popularPollsProvider = Provider<List<Poll>>((ref) {
  return [...ref.watch(pollsProvider)]
    ..sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
});

/// Following — polls from users the current user follows.
final followingPollsProvider =
    Provider.family<List<Poll>, Set<String>>((ref, followedIds) {
  return ref
      .watch(pollsProvider)
      .where((p) => followedIds.contains(p.author.id))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Current user's own polls.
final myPollsProvider = Provider<List<Poll>>((ref) {
  return ref
      .watch(pollsProvider)
      .where((p) => p.author.isCurrentUser && p.sharedBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Polls the current user has favorited.
final favoritePollsProvider = Provider<List<Poll>>((ref) {
  return ref.watch(pollsProvider).where((p) => p.isFavorited).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// All polls by a specific user (for their profile page).
final pollsByUserProvider =
    Provider.family<List<Poll>, String>((ref, userId) {
  return ref
      .watch(pollsProvider)
      .where((p) => p.author.id == userId && p.sharedBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
