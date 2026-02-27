import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_message.dart';
import '../../../models/message_role.dart';
import '../../../mock/mock_messages.dart';

const _uuid = Uuid();

final chatMessagesProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void loadMessages(String conversationId) {
    // In Phase 1, load mock messages for any conversation
    state = List.from(mockMessages);
  }

  void sendMessage(String content) {
    // Add user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];

    // Add loading indicator
    final loadingMessage = ChatMessage(
      id: 'loading-${_uuid.v4()}',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [...state, loadingMessage];

    // Simulate AI response after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      final response = getMockAiResponse();
      // Remove loading and add real response
      state = [
        ...state.where((m) => !m.isLoading),
        response,
      ];
    });
  }

  void clearMessages() {
    state = [];
  }
}
