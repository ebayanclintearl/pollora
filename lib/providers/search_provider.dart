import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poll.dart';
import '../models/user.dart';
import 'polls_provider.dart';
import 'users_provider.dart';

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

final searchSuggestionsProvider = Provider<List<SearchItem>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return const [];

  final polls = ref.watch(feedPollsProvider);
  final users = ref.watch(allUsersProvider);

  final matchedUsers = users
      .where((u) =>
          !u.isCurrentUser &&
          (u.name.toLowerCase().contains(query) ||
              u.handle.toLowerCase().contains(query)))
      .take(3)
      .map<SearchItem>((u) => UserSearchItem(u))
      .toList();

  final matchedPolls = polls
      .where((p) =>
          p.question.toLowerCase().contains(query) ||
          p.author.name.toLowerCase().contains(query) ||
          p.author.handle.toLowerCase().contains(query))
      .take(5)
      .map<SearchItem>((p) => PollSearchItem(p))
      .toList();

  return [...matchedUsers, ...matchedPolls];
});
