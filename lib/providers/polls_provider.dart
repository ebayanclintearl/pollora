import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poll.dart';
import 'users_provider.dart';

// ── Initial feed data ─────────────────────────
List<Poll> _buildInitialPolls() {
  final now = DateTime.now();
  return [
    Poll(
      id: 'p1',
      author: allUsers[1], // RoronoaZoro
      question: 'Who is the strongest?',
      options: const [
        PollOption(id: 'p1o1', text: 'Ban', votes: 237),
        PollOption(id: 'p1o2', text: 'Escanor', votes: 836),
        PollOption(id: 'p1o3', text: 'Zoro', votes: 173),
      ],
      createdAt: now.subtract(const Duration(hours: 2)),
      commentCount: 12,
      shareCount: 34,
    ),
    Poll(
      id: 'p2',
      author: allUsers[2], // MonkeyDLuffy
      question: 'Which Devil Fruit is the most useful?',
      options: const [
        PollOption(id: 'p2o1', text: 'Gomu Gomu no Mi', votes: 415),
        PollOption(id: 'p2o2', text: 'Mera Mera no Mi', votes: 326),
        PollOption(id: 'p2o3', text: 'Hie Hie no Mi', votes: 246),
      ],
      createdAt: now.subtract(const Duration(hours: 6)),
      commentCount: 7,
      shareCount: 18,
    ),
    Poll(
      id: 'p3',
      author: allUsers[3], // Ichigo
      question: 'Which is your favorite Anime?',
      options: const [
        PollOption(id: 'p3o1', text: 'One Piece', votes: 1297),
        PollOption(id: 'p3o2', text: 'Bleach', votes: 713),
        PollOption(id: 'p3o3', text: 'Naruto', votes: 531),
      ],
      createdAt: now.subtract(const Duration(days: 1)),
      commentCount: 23,
      shareCount: 67,
    ),
    Poll(
      id: 'p4',
      author: allUsers[4], // GokuSon
      question: 'Best anime battle of all time?',
      options: const [
        PollOption(id: 'p4o1', text: 'Goku vs Vegeta', votes: 2449),
        PollOption(id: 'p4o2', text: 'Naruto vs Sasuke', votes: 1786),
        PollOption(id: 'p4o3', text: 'Ichigo vs Aizen', votes: 868),
      ],
      createdAt: now.subtract(const Duration(days: 2)),
      commentCount: 41,
      shareCount: 112,
    ),
    Poll(
      id: 'p5',
      author: allUsers[5], // KilluaZ
      question: 'Who has the best power system in anime?',
      options: const [
        PollOption(id: 'p5o1', text: 'Nen – Hunter x Hunter', votes: 2972),
        PollOption(id: 'p5o2', text: 'Devil Fruits – One Piece', votes: 1923),
        PollOption(id: 'p5o3', text: 'Chakra – Naruto', votes: 1661),
        PollOption(id: 'p5o4', text: 'Quirks – My Hero Academia', votes: 1136),
        PollOption(id: 'p5o5', text: 'Alchemy – Fullmetal', votes: 699),
        PollOption(id: 'p5o6', text: 'Cursed Energy – Jujutsu', votes: 351),
      ],
      createdAt: now.subtract(const Duration(days: 3)),
      commentCount: 8,
      shareCount: 44,
    ),
    Poll(
      id: 'p6',
      author: allUsers[6], // ErenYeager
      question: 'Which anime had the best ending?',
      options: const [
        PollOption(id: 'p6o1', text: 'Fullmetal Alchemist: Brotherhood', votes: 1596),
        PollOption(id: 'p6o2', text: 'Steins;Gate', votes: 1089),
        PollOption(id: 'p6o3', text: 'Attack on Titan', votes: 701),
        PollOption(id: 'p6o4', text: 'Demon Slayer', votes: 505),
      ],
      createdAt: now.subtract(const Duration(days: 4)),
      commentCount: 5,
      shareCount: 29,
    ),
    // ── Current user's polls ──────────────────
    Poll(
      id: 'my1',
      author: currentUser,
      question: 'Who is the strongest Seven Deadly Sin?',
      options: const [
        PollOption(id: 'my1o1', text: 'Escanor', votes: 2178),
        PollOption(id: 'my1o2', text: 'Ban', votes: 602),
        PollOption(id: 'my1o3', text: 'Meliodas', votes: 465),
      ],
      createdAt: now.subtract(const Duration(days: 2)),
      commentCount: 15,
      shareCount: 28,
    ),
    Poll(
      id: 'my2',
      author: currentUser,
      question: 'Which Devil Fruit is most useful?',
      options: const [
        PollOption(id: 'my2o1', text: 'Gomu Gomu no Mi', votes: 415),
        PollOption(id: 'my2o2', text: 'Ope Ope no Mi', votes: 312),
        PollOption(id: 'my2o3', text: 'Pika Pika no Mi', votes: 260),
      ],
      createdAt: now.subtract(const Duration(days: 5)),
      commentCount: 7,
      shareCount: 12,
    ),
    Poll(
      id: 'my3',
      author: currentUser,
      question: 'Which is your favorite Anime?',
      options: const [
        PollOption(id: 'my3o1', text: 'One Piece', votes: 1297),
        PollOption(id: 'my3o2', text: 'Naruto', votes: 731),
        PollOption(id: 'my3o3', text: 'Bleach', votes: 513),
      ],
      createdAt: now.subtract(const Duration(days: 7)),
      commentCount: 23,
      shareCount: 45,
      isFavorited: true,
    ),
    Poll(
      id: 'my4',
      author: currentUser,
      question: 'Which character deserves more love?',
      options: const [
        PollOption(id: 'my4o1', text: 'Killua', votes: 398),
        PollOption(id: 'my4o2', text: 'Rock Lee', votes: 148),
        PollOption(id: 'my4o3', text: 'Yamcha', votes: 102),
      ],
      createdAt: now.subtract(const Duration(days: 14)),
      commentCount: 9,
      shareCount: 8,
    ),
    Poll(
      id: 'my5',
      author: currentUser,
      question: 'Best anime battle of all time?',
      options: const [
        PollOption(id: 'my5o1', text: 'Goku vs Vegeta', votes: 2449),
        PollOption(id: 'my5o2', text: 'Naruto vs Sasuke', votes: 1786),
        PollOption(id: 'my5o3', text: 'Ichigo vs Aizen', votes: 868),
      ],
      createdAt: now.subtract(const Duration(days: 14)),
      commentCount: 41,
      shareCount: 92,
      isFavorited: true,
    ),
  ];
}

// ── Notifier ──────────────────────────────────
class PollsNotifier extends StateNotifier<List<Poll>> {
  PollsNotifier() : super(_buildInitialPolls());

  void vote(String pollId, String optionId) {
    state = state.map((poll) {
      if (poll.id != pollId || poll.isVoted) return poll;
      final updatedOptions = poll.options.map((opt) {
        return opt.id == optionId
            ? opt.copyWith(votes: opt.votes + 1)
            : opt;
      }).toList();
      return poll.copyWith(options: updatedOptions, votedOptionId: optionId);
    }).toList();
  }

  void toggleFavorite(String pollId) {
    state = state.map((poll) {
      if (poll.id != pollId) return poll;
      return poll.copyWith(isFavorited: !poll.isFavorited);
    }).toList();
  }

  /// Called when the user taps the native share button.
  /// Increments the share count so the UI reflects the action.
  void incrementShare(String pollId) {
    state = state.map((poll) {
      if (poll.id != pollId) return poll;
      return poll.copyWith(shareCount: poll.shareCount + 1);
    }).toList();
  }
}

// ── Providers ─────────────────────────────────
final pollsProvider =
    StateNotifierProvider<PollsNotifier, List<Poll>>((ref) => PollsNotifier());

/// All polls sorted newest first (for the feed).
final feedPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider);
  return [...polls]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Current user's own polls (not shared posts).
final myPollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider);
  return polls
      .where((p) => p.author.id == currentUser.id && p.sharedBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Polls the current user has favorited.
final favoritePollsProvider = Provider<List<Poll>>((ref) {
  final polls = ref.watch(pollsProvider);
  return polls
      .where((p) => p.isFavorited)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// All polls by a specific user (for their profile page).
final pollsByUserProvider =
    Provider.family<List<Poll>, String>((ref, userId) {
  final polls = ref.watch(pollsProvider);
  return polls
      .where((p) => p.author.id == userId && p.sharedBy == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
