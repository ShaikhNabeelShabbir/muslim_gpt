class Conversation {
  final String id;
  final String title;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final int messageCount;

  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.updatedAt,
    this.messageCount = 0,
  });

  Conversation copyWith({
    String? id,
    String? title,
    String? lastMessagePreview,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}
