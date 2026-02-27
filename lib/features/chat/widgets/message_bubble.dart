import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../models/message_role.dart';
import 'user_message_bubble.dart';
import 'assistant_message_bubble.dart';
import 'typing_indicator.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return const TypingIndicator();
    }

    return switch (message.role) {
      MessageRole.user => UserMessageBubble(message: message),
      MessageRole.assistant => AssistantMessageBubble(message: message),
      MessageRole.system => const SizedBox.shrink(),
    };
  }
}
