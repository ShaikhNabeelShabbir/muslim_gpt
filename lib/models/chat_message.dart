import 'citation.dart';
import 'message_role.dart';

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final List<Citation> citations;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    List<Citation>? citations,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
