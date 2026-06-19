class AppUser {
  final String id;
  final String name;
  final String handle;
  final String? bio;
  final int pollsCount;
  final int votesReceived;
  final int followersCount;
  final int followingCount;
  final bool isCurrentUser;
  // true when this user follows the logged-in user (hard-coded for demo)
  final bool followsCurrentUser;

  const AppUser({
    required this.id,
    required this.name,
    required this.handle,
    this.bio,
    this.pollsCount = 0,
    this.votesReceived = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isCurrentUser = false,
    this.followsCurrentUser = false,
  });

  AppUser copyWith({
    int? followersCount,
    int? followingCount,
    int? pollsCount,
    int? votesReceived,
  }) =>
      AppUser(
        id: id,
        name: name,
        handle: handle,
        bio: bio,
        pollsCount: pollsCount ?? this.pollsCount,
        votesReceived: votesReceived ?? this.votesReceived,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        isCurrentUser: isCurrentUser,
        followsCurrentUser: followsCurrentUser,
      );
}
