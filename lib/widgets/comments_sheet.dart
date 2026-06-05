import 'package:flutter/material.dart';
import '../app_colors.dart';

class CommentsSheet extends StatefulWidget {
  final String pollQuestion;
  final int commentCount;
  const CommentsSheet({super.key, required this.pollQuestion, required this.commentCount});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<_Comment> _comments = [
    _Comment(avatarLabel: 'RZ', avatarColor: Color(0xFF1A6B3C), username: 'RoronoaZoro',
        text: 'Escanor is clearly the strongest, no debate!', timestamp: '2h ago'),
    _Comment(avatarLabel: 'MD', avatarColor: Color(0xFF8B4513), username: 'MonkeyDLuffy',
        text: "I'd put Zoro higher honestly 🔥", timestamp: '3h ago'),
    _Comment(avatarLabel: 'IC', avatarColor: Color(0xFF2B4D8B), username: 'Ichigo',
        text: 'The gap between Escanor and Ban is way too big', timestamp: '5h ago'),
    _Comment(avatarLabel: 'GK', avatarColor: Color(0xFF6B2B8B), username: 'GokuSon',
        text: 'Ban with full power is seriously underrated though', timestamp: '8h ago'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, _Comment(
        avatarLabel: 'C',
        avatarColor: const Color(0xFF8B6914),
        username: 'Clint',
        text: text,
        timestamp: 'now',
      ));
      _controller.clear();
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimaryMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_comments.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          // Comments list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _comments.length,
              itemBuilder: (_, i) => _CommentRow(comment: _comments[i]),
            ),
          ),
          // Input
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              color: AppColors.surfaceModal,
            ),
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + keyboardHeight + 10),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF8B6914),
                  child: Text('C', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      cursorColor: AppColors.accentPrimary,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitComment,
                  child: const Icon(Icons.send_rounded, size: 20, color: AppColors.accentPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Comment {
  final String avatarLabel;
  final Color avatarColor;
  final String username;
  final String text;
  final String timestamp;
  const _Comment({
    required this.avatarLabel,
    required this.avatarColor,
    required this.username,
    required this.text,
    required this.timestamp,
  });
}

class _CommentRow extends StatelessWidget {
  final _Comment comment;
  const _CommentRow({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: comment.avatarColor,
            child: Text(comment.avatarLabel,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.username,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 6),
                    Text(comment.timestamp,
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(comment.text,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
