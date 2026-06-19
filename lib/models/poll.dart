import 'user.dart';

class PollOption {
  final String id;
  final String text;
  final int votes;
  final String? imagePath;

  const PollOption({
    required this.id,
    required this.text,
    required this.votes,
    this.imagePath,
  });

  PollOption copyWith({int? votes}) =>
      PollOption(id: id, text: text, votes: votes ?? this.votes, imagePath: imagePath);

  double percentage(int total) => total > 0 ? votes / total : 0.0;
  int percentageInt(int total) =>
      total > 0 ? (votes / total * 100).round() : 0;
}

class Poll {
  final String id;
  final AppUser author;
  final String question;
  final List<PollOption> options;
  final DateTime createdAt;
  final int commentCount;
  final int shareCount;
  final bool isFavorited;
  final String? votedOptionId;
  // Non-null = this is a reshared copy; holds the user who shared it
  final AppUser? sharedBy;
  // Optional cover image — local file path (picked from gallery)
  final String? coverImagePath;

  const Poll({
    required this.id,
    required this.author,
    required this.question,
    required this.options,
    required this.createdAt,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isFavorited = false,
    this.votedOptionId,
    this.sharedBy,
    this.coverImagePath,
  });

  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes);
  bool get isVoted => votedOptionId != null;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  Poll copyWith({
    List<PollOption>? options,
    bool? isFavorited,
    String? votedOptionId,
    int? commentCount,
    int? shareCount,
    AppUser? sharedBy,
    String? coverImagePath,
  }) =>
      Poll(
        id: id,
        author: author,
        question: question,
        options: options ?? this.options,
        createdAt: createdAt,
        commentCount: commentCount ?? this.commentCount,
        shareCount: shareCount ?? this.shareCount,
        isFavorited: isFavorited ?? this.isFavorited,
        votedOptionId: votedOptionId ?? this.votedOptionId,
        sharedBy: sharedBy ?? this.sharedBy,
        coverImagePath: coverImagePath ?? this.coverImagePath,
      );
}
